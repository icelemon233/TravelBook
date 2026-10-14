import { spawnSync } from 'node:child_process';
import { mkdtempSync, cpSync, writeFileSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const remote = process.env.DEPLOY_REMOTE || 'git@github.com:icelemon233/cinna-travel.git';
const branch = process.env.DEPLOY_BRANCH || 'gh-pages';
const env = { ...process.env, GIT_SSH_COMMAND: process.env.GIT_SSH_COMMAND || 'ssh -o BatchMode=yes -o StrictHostKeyChecking=yes' };
function run(command, args, cwd = root) {
  const result = spawnSync(command, args, { cwd, env, stdio: 'inherit', windowsHide: true });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${command} failed (${result.status})`);
}
run(process.execPath, ['scripts/build.mjs']);
const staging = mkdtempSync(join(tmpdir(), 'cinna-pages-'));
console.log(`Deployment checkout: ${staging}`);
run('git', ['-c', 'core.autocrlf=false', 'clone', '--depth', '1', '--single-branch', '--branch', branch, remote, staging]);
run('git', ['config', 'core.autocrlf', 'false'], staging);
run('git', ['rm', '-r', '--quiet', '--ignore-unmatch', '.'], staging);
for (const name of ['index.html', 'app.js', 'app.css', 'assets']) {
  cpSync(join(root, name), join(staging, name), { recursive: true });
}
cpSync(join(root, 'index.html'), join(staging, '404.html'));
writeFileSync(join(staging, '.nojekyll'), '');
const hashes = Object.fromEntries(['index.html', 'app.js', 'app.css'].map(name => [name, createHash('sha256').update(readFileSync(join(root, name))).digest('hex')]));
writeFileSync(join(staging, 'deployment.json'), JSON.stringify({ hashes }, null, 2) + '\n');
run('git', ['add', '-A'], staging);
const diff = spawnSync('git', ['diff', '--cached', '--quiet'], { cwd: staging, windowsHide: true });
if (diff.status === 0) {
  console.log('GitHub Pages branch already contains this build.');
} else if (diff.status === 1) {
  run('git', ['commit', '-m', 'Publish Tibet itinerary'], staging);
  run('git', ['push', 'origin', branch], staging);
} else {
  throw new Error('Could not inspect staged deployment changes.');
}
console.log('Published branch: ' + branch);
console.log('Verify https://icelemon233.github.io/cinna-travel/deployment.json against:');
console.log(JSON.stringify(hashes, null, 2));
run(process.execPath, ['scripts/verify-deployment.mjs']);
