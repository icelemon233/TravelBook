import {spawn} from 'node:child_process';
await import('./build.mjs');
const children=['scripts/build.mjs','scripts/preview.cjs'].map((file,i)=>spawn(process.execPath,[file,...(i===0?['--watch']:[])],{stdio:'inherit',windowsHide:true}));
let closing=false;const close=()=>{if(closing)return;closing=true;children.forEach(child=>child.kill());};
process.on('SIGINT',close);process.on('SIGTERM',close);children.forEach(child=>child.on('exit',code=>{close();process.exitCode=code||0;}));
