import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve('lib');
const violations = [];
let checked = 0;

function walk(directory) {
  for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) walk(file);
    else if (entry.name.endsWith('.dart')) inspect(file);
  }
}

function inspect(file) {
  checked++;
  const source = path.relative(root, file).replaceAll('\\', '/');
  const feature = source.match(/^features\/([^/]+)\//)?.[1];
  const text = fs.readFileSync(file, 'utf8');
  for (const match of text.matchAll(/(?:import|export)\s+['"]([^'"]+)['"]/g)) {
    const uri = match[1];
    if (uri.startsWith('dart:')) continue;
    let target;
    if (uri.startsWith('package:cinna_travel_book/')) {
      target = uri.slice('package:cinna_travel_book/'.length);
    } else if (!uri.startsWith('package:')) {
      target = path.relative(root, path.resolve(path.dirname(file), uri)).replaceAll('\\', '/');
    } else continue;
    let reason;
    if (source.startsWith('core/') && !target.startsWith('core/')) {
      reason = 'core must not depend on app or features';
    } else if (feature && target.startsWith('app/')) {
      reason = 'features must not depend on the application composition root';
    } else if (feature) {
      const imported = target.match(/^features\/([^/]+)\/(data|presentation)\//);
      if (imported && imported[1] !== feature) {
        reason = 'cross-feature imports must use a public contract or domain model';
      }
    }
    if (source.includes('/domain/') && /\/(data|presentation)\//.test(target)) {
      reason = 'domain models must not depend on data or presentation implementations';
    }
    if (reason) {
      const line = text.slice(0, match.index).split('\n').length;
      violations.push(`${source}:${line} -> ${target}: ${reason}`);
    }
  }
}

walk(root);
if (violations.length) {
  console.error(violations.join('\n'));
  process.exitCode = 1;
} else {
  console.log(`Module boundaries verified in ${checked} Dart files.`);
}
