import test from 'node:test';
import assert from 'node:assert/strict';
import worker, { FeedbackGate } from '../src/index.mjs';
import { Relay, validate, readPayload, issueBody, digest } from '../src/protocol.mjs';

const env = { FEEDBACK_ENABLED: 'true', GITHUB_ISSUE_TOKEN: 'mock-only',
  GITHUB_OWNER: 'S-Adnan-11', GITHUB_REPO: 'al-murajaah-feedback', FEEDBACK_VISIBILITY: 'public' };
const payload = (number = 1) => ({ submissionId: `00000000-0000-4000-8000-${String(number).padStart(12, '0')}`,
  message: 'A reviewable message', category: 'problem', details: {} });
class Storage {
  map = new Map();
  async get(k) { return structuredClone(this.map.get(k)); }
  async put(k, v) { this.map.set(k, structuredClone(v)); }
  async delete(k) { this.map.delete(k); }
  async list() { return structuredClone(this.map); }
  async setAlarm() {}
}
const response = (status, value, headers) => new Response(JSON.stringify(value), { status, headers });

test('strict UTF-8 schema, bounded stream, no repository/hidden details', async () => {
  for (const value of [null, [], { ...payload(), repository: 'other' }, { ...payload(), category: 'bug' },
    { ...payload(), message: 'x' }, { ...payload(), message: '界'.repeat(2001) },
    { ...payload(), details: { deviceId: 'secret' } }, { ...payload(), message: 'hello\u0000' },
    { ...payload(), submissionId: '../issues' }]) assert.throws(() => validate(value));
  assert.equal(validate(payload()).message, payload().message);
  const request = (body) => new Request('https://test/feedback', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body });
  await assert.rejects(readPayload(request(' '.repeat(8193))));
  await assert.rejects(readPayload(request(new Uint8Array([0xff]))));
  assert.deepEqual(await readPayload(request(JSON.stringify(payload()))), payload());
});

test('user content is literal and mass mentions neutralized', () => {
  const body = issueBody({ ...payload(), message: '@everyone\n![x](https://remote/image)\n```\n<script>' }, 'hash');
  assert.ok(body.includes('    @\u200beveryone'));
  assert.ok(body.includes('    ![x](https://remote/image)'));
  assert.ok(body.includes('    ```\n    <script>'));
});

test('confirmed retry returns same reference; changed payload conflicts; destination fixed', async () => {
  let calls = 0;
  const storage = new Storage();
  const relay = new Relay(storage, env, async (url, options) => {
    calls++;
    assert.equal(url, 'https://api.github.com/repos/S-Adnan-11/al-murajaah-feedback/issues');
    assert.equal(options.method, 'POST');
    assert.equal((await storage.get(`submission:${payload().submissionId}`)).status, 'pending');
    return response(201, { number: 41 });
  });
  assert.deepEqual(await (await relay.submit(payload(), 'ip')).json(), { status: 'confirmed', reference: 41 });
  assert.equal((await relay.submit(payload(), 'ip')).status, 200);
  assert.equal((await relay.submit({ ...payload(), message: 'Changed' }, 'ip')).status, 409);
  assert.equal(calls, 1);
  assert.ok(!JSON.stringify([...storage.map]).includes('A reviewable message'));
});

test('ambiguous POST is never retried, even when reconciliation finds nothing', async () => {
  let now = 1000000, posts = 0, gets = 0;
  const relay = new Relay(new Storage(), env, async (_, options) => {
    if (options.method === 'POST') { posts++; throw new Error('timeout'); }
    gets++; return response(200, []);
  }, () => now);
  assert.equal((await relay.submit(payload(), 'ip')).status, 202);
  assert.equal((await relay.submit(payload(), 'ip')).status, 202);
  now += 31000;
  assert.equal((await relay.submit(payload(), 'ip')).status, 202);
  assert.equal(posts, 1); assert.equal(gets, 1);
});

test('pending survives a new Relay and reconciles an earlier identical submission', async () => {
  const storage = new Storage(); let now = 1000000;
  await new Relay(storage, env, async () => response(502, {}), () => now).submit(payload(), 'ip');
  now += 31000;
  const marker = `<!-- am-feedback:${payload().submissionId}:${await digest(JSON.stringify(payload()))} -->`;
  const relay = new Relay(storage, env, async (_, options) => {
    assert.notEqual(options.method, 'POST');
    return response(200, [{ number: 9, body: marker }]);
  }, () => now);
  assert.deepEqual(await (await relay.submit(payload(), 'ip')).json(), { status: 'confirmed', reference: 9 });
});

test('definite credential rejection allows safe retry; upstream throttling reported truthfully', async () => {
  let calls = 0;
  const relay = new Relay(new Storage(), env, async () => ++calls === 1 ? response(401, {}) : response(201, { number: 4 }));
  assert.equal((await relay.submit(payload(), 'ip')).status, 503);
  assert.equal((await relay.submit(payload(), 'ip')).status, 200);
  const limited = new Relay(new Storage(), env, async () => response(403, {}, { 'x-ratelimit-remaining': '0' }));
  assert.equal((await limited.submit(payload(), 'ip')).status, 429);
});

test('hourly source limit and singleton global burst quota', async () => {
  const relay = new Relay(new Storage(), env, async () => response(201, { number: 1 }));
  for (let i = 1; i <= 3; i++) assert.equal((await relay.submit(payload(i), 'same')).status, 200);
  assert.equal((await relay.submit(payload(4), 'same')).status, 429);
  for (let i = 5; i <= 11; i++) assert.equal((await relay.submit(payload(i), `ip${i}`)).status, 200);
  assert.equal((await relay.submit(payload(12), 'another')).status, 429);
});

test('concurrent calls are serialized by the actual Durable Object adapter', async () => {
  const gate = new FeedbackGate({ storage: new Storage() }, env);
  let posts = 0;
  gate.relay.upstream = async () => { posts++; await new Promise((resolve) => setTimeout(resolve, 5)); return response(201, { number: 1 }); };
  const request = () => new Request('https://internal/submit', { method: 'POST', body: JSON.stringify({ payload: payload(), ip: 'ip' }) });
  const results = await Promise.all(Array.from({ length: 8 }, () => gate.fetch(request())));
  assert.equal(posts, 1); assert.ok(results.every((r) => r.status === 200));
});

test('token absent / kill switch: no binding or GitHub access; narrow routing and edge throttle', async () => {
  for (const config of [{ ...env, GITHUB_ISSUE_TOKEN: undefined }, { ...env, FEEDBACK_ENABLED: 'false' }]) {
    assert.equal((await worker.fetch(new Request('https://test/feedback', { method: 'POST' }), config)).status, 503);
    assert.equal((await (await worker.fetch(new Request('https://test/health'), config)).json()).available, false);
  }
  assert.equal((await worker.fetch(new Request('https://test/admin'), env)).status, 404);
  assert.equal((await worker.fetch(new Request('https://test/feedback'), env)).status, 405);
  assert.equal((await worker.fetch(new Request('https://test/feedback', { method: 'POST' }),
    { ...env, EDGE_LIMIT: { limit: async () => ({ success: false }) } })).status, 429);
});

test('50-person mocked burst respects the global quota without duplicate upstream posts', async () => {
  const gate = new FeedbackGate({ storage: new Storage() }, env);
  let posts = 0;
  gate.relay.upstream = async () => response(201, { number: ++posts });
  const results = await Promise.all(Array.from({ length: 50 }, (_, i) => gate.fetch(
    new Request('https://internal/submit', { method: 'POST', body: JSON.stringify({
      payload: payload(i + 100), ip: `simulated-${i}`,
    }) }))));
  assert.equal(posts, 10);
  assert.equal(results.filter((r) => r.status === 200).length, 10);
  assert.equal(results.filter((r) => r.status === 429).length, 40);
});
