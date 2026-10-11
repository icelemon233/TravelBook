import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';

const root=process.cwd();
function git(args,cwd=root){return execFileSync('git',args,{cwd,encoding:'utf8',stdio:['ignore','pipe','inherit'],env:{...process.env,GIT_TERMINAL_PROMPT:'0'}}).trim();}
if(git(['status','--porcelain']))throw new Error('Commit the reviewed source before deployment.');
execFileSync(process.execPath,['--test','scripts/plan.test.mjs'],{cwd:root,stdio:'inherit'});
const source=git(['rev-parse','HEAD']);
const remote=process.env.DEPLOY_REMOTE||git(['remote','get-url','origin']);
const branch=process.env.DEPLOY_BRANCH||'gh-pages';
const tempBase=path.resolve(os.tmpdir());
const temp=fs.mkdtempSync(path.join(tempBase,'cinna-pages-'));
try{
  git(['clone','--single-branch','--branch',branch,remote,temp]);
  git(['rm','-r','--ignore-unmatch','.'],temp);
  for(const file of ['index.html','.nojekyll','autumn','assets','tibet','tibet-source.html'])fs.cpSync(path.join(root,file),path.join(temp,file),{recursive:true});
  fs.writeFileSync(path.join(temp,'404.html'),'<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>页面未找到 · Cinna Travel</title><body style="font:16px/2 system-ui;padding:10vw;background:#f4f0e7;color:#2d493d"><h1>页面未找到</h1><p><a href="https://icelemon233.github.io/cinna-travel/">返回赣皖旅游攻略</a> · <a href="https://icelemon233.github.io/cinna-travel/tibet/">查看西藏旅游攻略</a></p></body></html>');
  const hashes={};
  for(const file of ['index.html','autumn/app.js','autumn/style.css','autumn/trip-data.js','autumn/energy.js'])hashes[file]=crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex');
  fs.writeFileSync(path.join(temp,'deployment.json'),JSON.stringify({source_commit:source,hashes},null,2)+'\n');
  git(['add','-A'],temp);
  if(!git(['diff','--cached','--name-only'],temp)){console.log('No Pages changes to publish.');}else{
    git(['commit','-m',`Publish autumn itinerary from ${source.slice(0,7)}`],temp);
    git(['push','origin',branch],temp);
  }
  console.log(`Published source ${source}\nURL: https://icelemon233.github.io/cinna-travel/`);
}finally{
  const resolved=path.resolve(temp);
  if(path.dirname(resolved)!==tempBase||!path.basename(resolved).startsWith('cinna-pages-'))throw new Error('Refusing cleanup outside generated deployment directory.');
  fs.rmSync(resolved,{recursive:true,force:true});
}
