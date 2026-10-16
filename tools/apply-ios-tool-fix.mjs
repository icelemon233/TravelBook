import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';

// Flutter's official fix for https://github.com/flutter/flutter/issues/181771.
// Only the disposable CI host tool is patched; application/runtime sources are untouched.
const upstream='c3ed85ef987759ee54a6bce275490cde2a238dc1';
const originalHash='8a877c1d5dd8535be3e8b1c95b753d4c97b09b2adfcf6fa4f90b545734981514';
const patchedHash='541510af8e6f3205eb1c08fa7dd626fd029f8a94ad730b54c4800562c7a29640';
const patchHash='c7562cb1f47f3fa28044befd1fbdb148d1387026f1ae2a11c4d3fa4013b4f2d7';
const checkOnly=process.argv[2]==='--check';
if(!checkOnly&&(process.platform!=='darwin'||process.env.GITHUB_ACTIONS!=='true')){
  throw new Error('Apply this host-tool backport only on a disposable macOS GitHub Actions runner. Use --check <Flutter SDK> for a read-only compatibility check.');
}
const configured=checkOnly?process.argv[3]:process.env.FLUTTER_ROOT;
if(!configured||!path.isAbsolute(configured))throw new Error('An absolute Flutter SDK root is required.');
const root=fs.realpathSync(configured);
const relative='packages/flutter_tools/lib/src/ios/simulators.dart';
const target=path.resolve(root,relative);
const patch=fileURLToPath(new URL('patches/flutter-3.47.7-ios-log-reader.patch',import.meta.url));
const hash=value=>crypto.createHash('sha256').update(value).digest('hex');
if(hash(fs.readFileSync(patch).toString('utf8').replaceAll('\r\n','\n'))!==patchHash)throw new Error('The reviewed upstream backport changed.');
const before=hash(fs.readFileSync(target,'utf8').replaceAll('\r\n','\n'));
if(![originalHash,patchedHash].includes(before))throw new Error('Flutter tool source differs from the reviewed 3.47.7 baseline; review the SDK upgrade and remove/update this temporary backport.');
if(before===originalHash)execFileSync('git',['-C',root,'apply','--check',patch],{stdio:'inherit'});
if(checkOnly){console.log('Pinned upstream iOS tool fix is compatible: '+upstream);process.exit(0);}
if(before===originalHash)execFileSync('git',['-C',root,'apply',patch],{stdio:'inherit'});
if(hash(fs.readFileSync(target,'utf8').replaceAll('\r\n','\n'))!==patchedHash)throw new Error('Patched Flutter tool checksum mismatch.');
// Regenerate two disposable compiled-tool cache files on the next Flutter invocation.
const cache=path.resolve(root,'bin/cache');
for(const name of ['flutter_tools.snapshot','flutter_tools.stamp']){
  const generated=path.resolve(cache,name);
  if(path.dirname(generated)!==cache||!generated.startsWith(root+path.sep))throw new Error('Unexpected tool cache path.');
  fs.rmSync(generated,{force:true});
}
console.log('Applied official Flutter iOS simulator log-readiness fix '+upstream+' to the CI host tool.');
