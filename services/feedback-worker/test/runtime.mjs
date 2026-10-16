import { Miniflare, convertV4MiniflareOptions } from '../../../artifacts/feedback-worker-tools/node_modules/miniflare/dist/src/index.js';
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';

const source = path.resolve(import.meta.dirname, '../src');
let posts = 0;
const mf = new Miniflare(convertV4MiniflareOptions({
  workers: [{
  name: 'feedback-test',
  modules: [
    { type: 'ESModule', path: path.join(source, 'index.mjs'), contents: fs.readFileSync(path.join(source, 'index.mjs'), 'utf8') },
    { type: 'ESModule', path: path.join(source, 'protocol.mjs'), contents: fs.readFileSync(path.join(source, 'protocol.mjs'), 'utf8') },
  ],
  compatibilityDate: '2026-10-10',
  bindings: { GITHUB_OWNER: 'S-Adnan-11', GITHUB_REPO: 'al-murajaah-feedback',
    FEEDBACK_VISIBILITY: 'public', FEEDBACK_ENABLED: 'true', GITHUB_ISSUE_TOKEN: 'runtime-mock-only' },
  durableObjects: { FEEDBACK: { className: 'FeedbackGate', useSQLite: true } },
  outboundService: async (request) => {
    assert.equal(request.url, 'https://api.github.com/repos/S-Adnan-11/al-murajaah-feedback/issues');
    assert.equal(request.method, 'POST');
    posts++;
    return Response.json({ number: 71 }, { status: 201 });
  },
  }],
}));
try {
  const payload = { submissionId: '00000000-0000-4000-8000-000000000001',
    message: 'Local runtime test, never published', category: 'other', details: {} };
  const send = () => mf.dispatchFetch('https://worker.test/feedback', { method: 'POST',
    headers: { 'content-type': 'application/json', 'CF-Connecting-IP': '192.0.2.1' }, body: JSON.stringify(payload) });
  const responses = await Promise.all(Array.from({ length: 6 }, send));
  for (const result of responses) {
    assert.equal(result.status, 200);
    assert.deepEqual(await result.json(), { status: 'confirmed', reference: 71 });
  }
  assert.equal(posts, 1);
  const state = await mf.getDurableObjectNamespace('FEEDBACK', 'feedback-test');
  assert.ok(state.idFromName('feedback-v1'));
  console.log('PASS: real workerd + SQLite Durable Object, 6 concurrent submissions, 1 mocked GitHub POST, 6 identical confirmations. No real issue created.');
} finally { await mf.dispose(); }
