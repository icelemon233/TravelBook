import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const site = 'https://icelemon233.github.io/cinna-travel/';
const hash = value => createHash('sha256').update(value).digest('hex');
const expected = Object.fromEntries(['index.html', 'app.js', 'app.css'].map(name => [name, hash(readFileSync(join(root, name)))]));
let reason = '';
for (let attempt = 1; attempt <= 20; attempt++) {
  try {
    const get = async name => {
      const response = await fetch(site + name + '?deploy-check=' + Date.now(), { signal: AbortSignal.timeout(15000), cache: 'no-store' });
      if (!response.ok) throw new Error(`${name}: HTTP ${response.status}`);
      return response;
    };
    const manifest = await (await get('deployment.json')).json();
    for (const [name, digest] of Object.entries(expected)) {
      if (manifest.hashes?.[name] !== digest) throw new Error(`${name}: previous deployment still served`);
      if (hash(Buffer.from(await (await get(name)).arrayBuffer())) !== digest) throw new Error(`${name}: online file hash differs`);
    }
    console.log('Verified live deployment: ' + site);
    process.exit(0);
  } catch (error) {
    reason = error.message;
    console.log(`Waiting for Pages (${attempt}/20): ${reason}`);
  }
  if (attempt < 20) await new Promise(resolve => setTimeout(resolve, 15000));
}
throw new Error('Pages verification timed out: ' + reason);
