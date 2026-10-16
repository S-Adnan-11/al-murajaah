import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Keep Wrangler caches, local state and generated bundles in existing ignored
// artifacts/. The reviewed template/source stay in services/feedback-worker.
const source = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(source, '../..');
const target = path.join(root, 'artifacts/feedback-worker-deploy');
const config = JSON.parse(fs.readFileSync(path.join(source, 'wrangler.jsonc'), 'utf8'));
config.main = path.join(source, config.main);
config.$schema = path.join(root, 'artifacts/feedback-worker-tools/node_modules/wrangler/config-schema.json');
fs.mkdirSync(target, { recursive: true });
fs.writeFileSync(path.join(target, 'wrangler.jsonc'), JSON.stringify(config, null, 2) + '\n');
console.log('Prepared artifacts/feedback-worker-deploy/wrangler.jsonc (no credentials).');
