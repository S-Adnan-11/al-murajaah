import { available, json, readPayload, Relay } from './protocol.mjs';

export default {
  async fetch(request, env) {
    const path = new URL(request.url).pathname;
    if (path === '/health' && request.method === 'GET') {
      return json(200, { status: 'ok', available: available(env), visibility: 'public' });
    }
    if (path !== '/feedback') return json(404, { status: 'not_found' });
    if (request.method !== 'POST') return json(405, { status: 'method_not_allowed' });
    if (!available(env)) return json(503, { status: 'unavailable' }, 60);
    const ip = request.headers.get('CF-Connecting-IP') ?? 'unknown';
    // Edge limit is per Cloudflare location and eventually consistent.
    if (env.EDGE_LIMIT && !(await env.EDGE_LIMIT.limit({ key: ip })).success) {
      return json(429, { status: 'rate_limited' }, 60);
    }
    let payload;
    try { payload = await readPayload(request); } catch { return json(400, { status: 'invalid' }); }
    try {
      return await env.FEEDBACK.get(env.FEEDBACK.idFromName('feedback-v1')).fetch(
        new Request('https://internal/submit', { method: 'POST',
          body: JSON.stringify({ payload, ip }) }),
      );
    } catch { return json(202, { status: 'pending' }, 30); }
  },
};

export class FeedbackGate {
  constructor(ctx, env) {
    this.relay = new Relay(ctx.storage, env);
    this.tail = Promise.resolve();
  }
  fetch(request) {
    // Serialize the singleton's quota and submission transitions, including
    // requests arriving during upstream I/O. Pending survives eviction/crash.
    const result = this.tail.then(async () => {
      const { payload, ip } = await request.json();
      return this.relay.submit(payload, ip);
    });
    this.tail = result.catch(() => {});
    return result;
  }
  alarm() {
    const result = this.tail.then(() => this.relay.cleanup());
    this.tail = result.catch(() => {});
    return result;
  }
}
