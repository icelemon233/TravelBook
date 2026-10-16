import fs from 'node:fs';
import crypto from 'node:crypto';
const version='6.2.108',base=`https://unpkg.com/pdfjs-dist@${version}/`;
fs.mkdirSync('web/vendor/pdfjs',{recursive:true});
const files={};
for(const [source,target] of [['build/pdf.min.mjs','pdf.min.mjs'],['build/pdf.worker.min.mjs','pdf.worker.min.mjs'],['LICENSE','LICENSE']]) {
  const response=await fetch(base+source,{signal:AbortSignal.timeout(90000)});if(!response.ok)throw new Error('PDF.js download HTTP '+response.status);
  const bytes=Buffer.from(await response.arrayBuffer());fs.writeFileSync('web/vendor/pdfjs/'+target,bytes);files[target]=crypto.createHash('sha256').update(bytes).digest('hex');
}
fs.writeFileSync('web/vendor/pdfjs/provenance.json',JSON.stringify({package:'pdfjs-dist',version,source:`https://www.npmjs.com/package/pdfjs-dist/v/${version}`,license:'Apache-2.0',files},null,2));
console.log('Pinned PDF.js runtime bundled locally; printing needs no external CDN.');
