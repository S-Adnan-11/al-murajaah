export const MAX_BYTES = 8192;
const encoder = new TextEncoder();
export const size = (s) => encoder.encode(s).length;
export const json = (status, value, retry = null) => new Response(JSON.stringify(value), {
  status,
  headers: {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
    ...(retry ? { 'Retry-After': String(retry) } : {}),
  },
});
export const available = (env) => env.FEEDBACK_ENABLED === 'true' &&
  Boolean(env.GITHUB_ISSUE_TOKEN) && env.GITHUB_OWNER === 'S-Adnan-11' &&
  env.GITHUB_REPO === 'al-murajaah-feedback' && env.FEEDBACK_VISIBILITY === 'public';

export async function readPayload(request) {
  if (request.headers.get('content-type')?.split(';')[0].trim() !== 'application/json') {
    throw new Error('content_type');
  }
  if (request.headers.get('content-encoding')) throw new Error('encoding');
  if (Number(request.headers.get('content-length') ?? 0) > MAX_BYTES) throw new Error('size');
  const reader = request.body?.getReader();
  if (!reader) throw new Error('body');
  const chunks = [];
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.length;
    if (total > MAX_BYTES) { await reader.cancel(); throw new Error('size'); }
    chunks.push(value);
  }
  const bytes = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  return validate(JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes)));
}

function onlyKeys(object, keys) {
  return object && typeof object === 'object' && !Array.isArray(object) &&
    Object.keys(object).every((key) => keys.includes(key));
}
function text(value, max) {
  return typeof value === 'string' && value.trim().length > 0 && size(value) <= max &&
    !/[\x00-\x08\x0b-\x1f\x7f\u202a-\u202e\u2066-\u2069]/u.test(value);
}
export function validate(value) {
  if (!onlyKeys(value, ['submissionId', 'message', 'category', 'details']) ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value.submissionId) ||
      !text(value.message, 6000) || value.message.trim().length < 3 ||
      !['problem', 'suggestion', 'other'].includes(value.category)) throw new Error('schema');
  const details = value.details ?? {};
  if (!onlyKeys(details, ['appVersion', 'androidVersion', 'manufacturer', 'model']) ||
      Object.values(details).some((v) => !text(v, 100))) throw new Error('details');
  // Stable order ensures the same reviewable payload has the same digest.
  return {
    submissionId: value.submissionId.toLowerCase(), message: value.message.trim(),
    category: value.category,
    details: Object.fromEntries(Object.keys(details).sort().map((k) => [k, details[k]])),
  };
}
export async function digest(value) {
  return [...new Uint8Array(await crypto.subtle.digest('SHA-256', encoder.encode(value)))].map(
    (byte) => byte.toString(16).padStart(2, '0'),
  ).join('');
}
export function issueBody(payload, hash) {
  // Four-space code blocks display user text literally: no mentions, Markdown
  // links, remote images, HTML or closing-fence injection is interpreted.
  const literal = (value) => value.replaceAll('\r\n', '\n').replaceAll('\r', '\n')
    .replaceAll('@', '@\u200b').split('\n').map((line) => `    ${line}`).join('\n');
  return `Submitted from Al-Muraja'ah. Public, text-only feedback.\n\nCategory: ${payload.category}\n\n` +
    literal(payload.message) + (Object.keys(payload.details).length
      ? '\n\nUser-reviewed details:\n\n' + literal(Object.entries(payload.details).map(([k, v]) => `${k}: ${v}`).join('\n')) : '') +
    `\n\n<!-- am-feedback:${payload.submissionId}:${hash} -->`;
}

export class Relay {
  constructor(storage, env, upstream = (url, options) => fetch(url, options), now = () => Date.now()) {
    this.storage = storage; this.env = env; this.upstream = upstream; this.now = now;
  }
  headers() {
    return { Authorization: `Bearer ${this.env.GITHUB_ISSUE_TOKEN}`,
      Accept: 'application/vnd.github+json', 'X-GitHub-Api-Version': '2026-03-10',
      'User-Agent': 'al-murajaah-feedback', 'Content-Type': 'application/json' };
  }
  async github(url, options = {}) {
    return this.upstream(url, { ...options, headers: this.headers(), redirect: 'manual',
      signal: AbortSignal.timeout(8000) });
  }
  async submit(payload, ip) {
    const now = this.now(), key = `submission:${payload.submissionId}`;
    const hash = await digest(JSON.stringify(payload));
    let record = await this.storage.get(key);
    if (record && record.hash !== hash) return json(409, { status: 'conflict' });
    if (record?.status === 'confirmed') return json(200, { status: 'confirmed', reference: record.reference });
    if (record?.status === 'pending') {
      if (now - record.checked < 30000) return json(202, { status: 'pending' }, 30);
      record.checked = now;
      await this.storage.put(key, record);
      const marker = `<!-- am-feedback:${payload.submissionId}:${hash} -->`;
      try {
        // Bounded reconciliation; absence never licenses another POST.
        for (let page = 1; page <= 3; page++) {
          const url = `https://api.github.com/repos/${this.env.GITHUB_OWNER}/${this.env.GITHUB_REPO}/issues?state=all&sort=created&direction=desc&per_page=100&page=${page}&since=${encodeURIComponent(new Date(record.created - 60000).toISOString())}`;
          const response = await this.github(url);
          if (!response.ok) break;
          const issues = await response.json();
          if (!Array.isArray(issues)) break;
          const match = issues.find((issue) => !issue.pull_request && typeof issue.body === 'string' && issue.body.includes(marker) && Number.isSafeInteger(issue.number));
          if (match) return this.confirm(key, record, match.number);
          if (issues.length < 100) break;
        }
      } catch { /* Upstream may still be uncertain. */ }
      return json(202, { status: 'pending' }, 30);
    }
    const date = new Date(now).toISOString().slice(0, 10);
    const minute = Math.floor(now / 60000), hour = Math.floor(now / 3600000);
    const salt = await this.storage.get('salt') ?? crypto.randomUUID();
    await this.storage.put('salt', salt);
    const address = await digest(`${salt}:${date}:${ip}`);
    const dayKey = `day:${date}`;
    const counts = await this.storage.get(dayKey) ?? { total: 0, minute, burst: 0, ips: {} };
    const person = counts.ips[address] ?? { hour, hourly: 0, daily: 0 };
    if (counts.minute !== minute) { counts.minute = minute; counts.burst = 0; }
    if (person.hour !== hour) { person.hour = hour; person.hourly = 0; }
    if (counts.total >= 100 || counts.burst >= 10 || person.hourly >= 3 || person.daily >= 10) {
      return json(429, { status: 'rate_limited' }, 3600);
    }
    counts.total++; counts.burst++; person.hourly++; person.daily++;
    counts.ips[address] = person;
    await this.storage.put(dayKey, counts);
    record = { hash, status: 'pending', created: now, checked: now };
    // Durable pending write must precede the potentially ambiguous POST.
    await this.storage.put(key, record);
    if (this.storage.getAlarm && await this.storage.getAlarm() === null) {
      await this.storage.setAlarm(now + 86400000);
    }
    try {
      const response = await this.github(`https://api.github.com/repos/${this.env.GITHUB_OWNER}/${this.env.GITHUB_REPO}/issues`, {
        method: 'POST', body: JSON.stringify({ title: `[App feedback] ${payload.category}`, body: issueBody(payload, hash) }),
      });
      if (response.status === 201) {
        const result = await response.json();
        if (Number.isSafeInteger(result.number) && result.number > 0) return this.confirm(key, record, result.number);
      } else if ([400, 401, 403, 404, 410, 422, 429].includes(response.status)) {
        // A definite rejection is safe to retry, and still consumes abuse quota.
        record.status = 'rejected';
        await this.storage.put(key, record);
        return response.status === 429 || response.headers.get('x-ratelimit-remaining') === '0' || response.headers.has('retry-after')
          ? json(429, { status: 'rate_limited' }, 3600)
          : json(503, { status: 'unavailable' }, 60);
      }
    } catch { /* Transport failure or malformed success is ambiguous. */ }
    return json(202, { status: 'pending' }, 30);
  }
  async confirm(key, record, reference) {
    await this.storage.put(key, { ...record, status: 'confirmed', reference });
    return json(200, { status: 'confirmed', reference });
  }
  async cleanup() {
    const now = this.now();
    for (const [key, value] of await this.storage.list()) {
      if (key.startsWith('submission:') && now - value.created > 30 * 86400000 ||
          key.startsWith('day:') && key.slice(4) < new Date(now - 86400000).toISOString().slice(0, 10)) {
        await this.storage.delete(key);
      }
    }
    await this.storage.setAlarm(now + 86400000);
  }
}
