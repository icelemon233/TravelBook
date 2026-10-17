import {execFileSync} from 'node:child_process';
const run=(cmd,args)=>execFileSync(cmd,args,{encoding:'utf8',stdio:['pipe','pipe','pipe']}).trim();
if(run('git',['branch','--show-current'])!=='main')throw new Error('Publish the reviewed main branch.');
if(run('git',['status','--porcelain']))throw new Error('Commit local changes before deployment.');
const head=run('git',['rev-parse','HEAD']);
const runs=JSON.parse(run('gh',['run','list','--repo','icelemon233/TravelBook','--workflow','flutter.yml','--branch','main','--limit','10','--json','databaseId,headSha,status,conclusion']));
const matching=runs.find(r=>r.headSha===head);
if(matching){console.log(`Deployment workflow: https://github.com/icelemon233/TravelBook/actions/runs/${matching.databaseId} (${matching.status}/${matching.conclusion||'pending'})`);}
else {run('gh',['workflow','run','flutter.yml','--repo','icelemon233/TravelBook','--ref','main']);console.log('Three-platform checks and Web deployment requested for '+head);}
