import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Keep Wrangler caches, local state and generated bundles in existing ignored
// artifact-private/. The template/source stay in services/feedback-worker.
const source = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(source, '../..');
const target = path.join(root, 'artifact-private/feedback-worker-deploy');
const tools = path.join(root, 'artifact-private/feedback-worker-tools');
fs.mkdirSync(tools, { recursive: true });
for (const file of ['package.json', 'package-lock.json']) {
  fs.copyFileSync(path.join(source, file), path.join(tools, file));
}
const config = JSON.parse(fs.readFileSync(path.join(source, 'wrangler.jsonc'), 'utf8'));
config.main = path.join(source, config.main);
config.$schema = path.join(root, 'artifact-private/feedback-worker-tools/node_modules/wrangler/config-schema.json');
fs.mkdirSync(target, { recursive: true });
fs.writeFileSync(path.join(target, 'wrangler.jsonc'), JSON.stringify(config, null, 2) + '\n');
console.log('Prepared locked tools manifests and deployment config under artifact-private/ (no credentials).');
