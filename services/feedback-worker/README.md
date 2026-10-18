# Al-Murāja’ah text feedback relay

We use this Worker to relay text feedback from the app to our public GitHub feedback tracker. This directory contains its source, tests and deployment configuration.
[App source and setup](../../README.md) · [Public feedback tracker](https://github.com/S-Adnan-11/al-murajaah-feedback).

The app build requires no service credentials. Without a `FEEDBACK_ENDPOINT`
compile-time define, sending is unavailable. Development and automated checks
should use a local/test service and mocked GitHub requests.
Use Node.js 22 or newer (locally verified with 26.10.0).

Fixed destination: public Issues in `S-Adnan-11/al-murajaah-feedback`.
`POST /feedback` accepts only a UUID v4 `submissionId`, `message` (3+ characters,
at most 6,000 UTF-8 bytes), category (`problem`, `suggestion`, `other`) and optional
reviewed `details` (`appVersion`, `androidVersion`, `manufacturer`, `model`, each
at most 100 bytes). The entire request is limited to 8,192 bytes. Unknown fields,
control characters, non-JSON requests and encoded request bodies are rejected.
User text is rendered literally; mentions are neutralized. Responses contain only
status and a confirmed issue number. No message bodies are logged or stored by
the relay. The issue is public; Cloudflare and GitHub can process request metadata.

The APK contains only the public endpoint. `GITHUB_ISSUE_TOKEN` belongs exclusively
in Cloudflare Secrets, restricted to Issues read/write on this repository.
Absent token or `FEEDBACK_ENABLED=false` returns 503 without contacting GitHub.
`GET /health` reports configuration availability; it does not validate token expiry.

## Prepare and deploy from the workspace root

```powershell
node services/feedback-worker/prepare.mjs
npm.cmd ci --prefix artifact-private/feedback-worker-tools --no-audit --no-fund
node --test services/feedback-worker/test/relay.test.mjs
node services/feedback-worker/test/runtime.mjs
```

The protocol and workerd/SQLite runtime checks above mock GitHub and create no real issue.
The committed `package.json` and `package-lock.json` pin Wrangler, Miniflare and their transitive dependencies. Preparation copies both manifests into the ignored tools directory; `npm ci` installs that exact dependency graph there. Runtime tests read Miniflare from that directory. The mocked protocol tests need only Node.js, with no npm install.
Use `.cmd` launchers on Windows; on macOS/Linux use `npm` and the corresponding launcher without `.cmd`.

Deployment is a separate maintainer operation and needs Cloudflare access and a configured secret:

```powershell
artifact-private/feedback-worker-tools/node_modules/.bin/wrangler.cmd --cwd artifact-private/feedback-worker-deploy login --device --browser=false
artifact-private/feedback-worker-tools/node_modules/.bin/wrangler.cmd --cwd artifact-private/feedback-worker-deploy deploy --config wrangler.jsonc
```

Preparation copies the configuration into ignored `artifact-private/` using absolute
source paths. Run Wrangler from that prepared directory to keep generated
state, logs and bundles out of source. Retain the production service's bindings
and state when deploying an update.
The deployment creates one SQLite Durable Object class and an edge rate-limit
binding. Check account quotas before deployment and wider distribution.

## Abuse and retry behavior

An edge binding permits 30 requests/minute per connecting IP at a Cloudflare
location. This limit is eventually consistent and is not an exact global quota.
A serialized singleton Durable Object additionally limits new attempts to 3/IP
per UTC hour, 10/IP per UTC day, 10 globally per UTC minute and 100 globally per
UTC day. Definite upstream rejections consume quota too. IPs are stored only as
daily salted digests and never enter GitHub issues. Shared networks share limits.
This is an unauthenticated public endpoint; distributed spam can consume quotas
and service capacity. CORS and an APK secret would not solve that problem.

Submission ID plus canonical content digest identifies a retry. A changed body
with the same ID returns 409. Confirmed retries return the stored reference.
Pending state is persisted before GitHub POST. GitHub requests have an 8-second
timeout and do not follow redirects. Ambiguous results return 202 and never
automatically repeat the POST. A later retry, at most every 30 seconds, searches
up to three pages of repository issues for the exact submission marker. An
absent marker leaves the submission pending. This can require maintainer investigation;
it is not a guarantee of exactly-once delivery.

Deduplication records expire after 30 days. Daily counters/digests expire after
their useful window; alarms clean up state without retaining feedback bodies.
Do not resubmit an old uncertain report under a new ID. Clearing server state or
retrying after retention can lose duplicate protection.

## Operate

Set `FEEDBACK_ENABLED=false` in the Worker settings to stop submissions. Before
redeploying, also change that value in the reviewed template if the service must
remain stopped; the template's plain variables are deployed again. Rotate the
GitHub token directly in Cloudflare before expiry or after revocation. Never put
the token in Flutter defines, assets, logs or source.
Rotation requires no APK update. Preserve the Durable Object namespace/migration
history during updates so pending and confirmed results survive.

After configuring the secret, submit one clearly labeled manual test from the
installed app, inspect its issue and reference, then exercise errors/offline and
retry. Confirm audio continues. Local tests mock GitHub and create no real issue.

Provider contracts: [Durable Objects](https://developers.cloudflare.com/durable-objects/),
[rate limits](https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/),
[secrets](https://developers.cloudflare.com/workers/configuration/secrets/),
[GitHub issues](https://docs.github.com/en/rest/issues/issues#create-an-issue).
