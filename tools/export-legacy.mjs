import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {execFileSync} from 'node:child_process';
import {build} from 'esbuild';

// Immutable source commits are reachable through both archive branches and the merge.
const root=path.resolve(import.meta.dirname,'..');
const refs={ganwan:'a0f0420768bf20522329feb1e026dd0f1bc13d86',tibet:'f017b1e24db716f07b2e99444685cc68b8d9b6fd',preAntd:'cc4b00c3a4fac70c7032dfe1c8d5425ffbcbb5c5'};
const check=process.argv.includes('--check');
const git=args=>execFileSync('git',args,{cwd:root,maxBuffer:32*1024*1024});
const read=(ref,file)=>git(['show',`${ref}:${file}`]).toString('utf8');
const json=(ref,file)=>JSON.parse(read(ref,file));
const cache=new Map();
async function moduleAt(ref,entry){
  const key=`${ref}:${entry}`;if(cache.has(key))return cache.get(key);
  const result=await build({entryPoints:[entry],write:false,bundle:true,platform:'node',format:'cjs',logLevel:'silent',plugins:[{name:'git-snapshot',setup(builder){
    builder.onResolve({filter:/.*/},a=>({path:path.posix.normalize(path.posix.join(a.importer?path.posix.dirname(a.importer):'',a.path.replace(/\?.*$/,''))),namespace:'snapshot'}));
    builder.onLoad({filter:/.*/,namespace:'snapshot'},a=>({contents:read(ref,a.path),loader:a.path.endsWith('.json')?'json':'js'}));
  }}]});
  const context={module:{exports:{}},console,Image:class{set src(v){this.source=v;}}};
  vm.runInNewContext(result.outputFiles[0].text,context,{timeout:5000});cache.set(key,context.module.exports);return context.module.exports;
}
function output(file,value){
  const target=path.join(root,file),bytes=Buffer.from(typeof value==='string'?value:JSON.stringify(value));
  if(check){if(!fs.existsSync(target)||!fs.readFileSync(target).equals(bytes))throw new Error(`Generated asset differs: ${file}`);}
  else{fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,bytes);}
}
function copyImages(ref,namespace){
  const files=git(['ls-tree','-r','--name-only',ref,'--','assets']).toString().trim().split('\n');
  for(const file of files.filter(f=>/\.(png|jpe?g|webp)$/i.test(f))){
    const target=path.join(root,'assets/images',namespace,file.slice(7)),bytes=git(['show',`${ref}:${file}`]);
    if(check){if(!fs.existsSync(target)||!fs.readFileSync(target).equals(bytes))throw new Error(`Image changed: ${file}`);}
    else{fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,bytes);}
  }
}
const text=v=>v==null?'待核实':String(v);
const link=(title,url,description='')=>({title,url,description});
const fact=(label,value)=>({label,value:text(value)});
const colors=['#344d59','#b84727','#9b7114','#18776f','#5555a1','#306a99','#8b4466'];
const [g,gm,gb,gd,gr,ga]=await Promise.all(['trip-data','map-model','budget-model','driving','return-options-model','attractions-data'].map(file=>moduleAt(refs.ganwan,`autumn/${file}.js`)));
const audit=json(refs.ganwan,'autumn/amap-times.json'),returns=json(refs.ganwan,'autumn/return-options-data.json'),photos=json(refs.ganwan,'autumn/photo-sources.json'),gmap=json(refs.ganwan,'autumn/map-data.json');
function sourceOf(p){return p?.source?link(p.sourceLabel||'原始资料',p.source):null;}
function ganwanDay(day,index){
  const drive=gd.drivingFor(day,audit),map=gm.mapDays([day])[0],night=day.overnight;
  return {id:day.id,number:index+1,label:`Day ${index+1}`,phase:day.phase,title:day.route,focus:day.focus,detail:day.detail,geography:day.geography,points:[],mapPaths:map.paths,color:map.color,km:drive.complete?drive.km:null,minutes:drive.complete?drive.minutes:null,
    facts:[fact('道路',day.road),fact('驾驶核对',drive.label),fact('补能',day.charge),fact('过夜与恢复',day.sleep)],
    navigation:drive.legs.map((leg,i)=>link(drive.legs.length>1?`第${i+1}段高德路线`:'高德路线',leg.url,`${leg.from} → ${leg.to}；${leg.roads}；${leg.policy}`)),
    overnight:{mode:night.mode,title:night.place.name,region:night.place.region,address:night.place.address,note:night.place.note,status:night.status,reason:night.reason,source:sourceOf(night.place),backup:night.fallback?{title:night.fallback.name,region:night.fallback.region,address:night.fallback.address,note:night.fallback.note,source:sourceOf(night.fallback)}:null},events:[]};
}
const ganwanVariants=[15,16,17].map(n=>({id:String(n),label:`${n}天`,selectors:{length:String(n)},days:g.makePlan(n).map(ganwanDay),budgetDefaults:gb.budgetDefaults}));
const checks=[['route','每天实际导航不超过5小时','用具体停车场／酒店做起终点，必要时提前落脚或拆段。'],['charge','下一段主站与备用站都查过','确认AC/DC、接口、开放时间、近期状态及备用站可达。'],['sleep','车宿点已获准过夜','确认停车许可、厕所、夜间出入和噪声，不只看地图有停车场。'],['hotel','酒店恢复晚已有安排','床车每2–3晚恢复一次，停车与充电分别确认。'],['night','整夜空调耗电有实测依据','睡前SOC覆盖夜耗、次日路程与备用电量。'],['shuttle','阳产换乘与下山时间已查清','不按固定30元或固定末班时间做承诺。'],['weather','天气、路况与开放情况已查','阴雨、封路或疲劳时使用机动日，不强求云海日出。'],['offline','证件、随车用品与离线地图备齐','车宿用品、饮水、洗漱、补胎用品与道路救援信息。']];
const ganwanPhotos=Object.entries(photos).map(([id,p])=>({id,asset:`assets/images/ganwan/${p.local.replace(/^assets\//,'')}`,title:p.description||p.title,author:p.author,license:p.license,licenseUrl:p.licenseUrl,source:p.source||p.url,generated:false}));
const ganwan={id:'ganwan',title:'赣皖自驾',subtitle:'江门出发 · 古村、江岸与床车',edition:'15 / 16 / 17 天 · 日期待定',description:'单司机，每日纯驾驶以4–5小时为目标；床车与酒店交替，充电和休息另计。',defaultVariant:'16',coverId:'yangchan',selectors:[{id:'length',label:'行程天数',options:[{id:'15',label:'15天 · 少一天周边'},{id:'16',label:'16天 · 主方案'},{id:'17',label:'17天 · 多一天缓冲'}]}],variants:ganwanVariants,sections:['overview','itinerary','map','attractions','stays','budget','returns','energy','checklist','sources'],photos:ganwanPhotos,
  attractions:ga.attractionGroups.map(group=>({...group,spots:group.spots.map(s=>({...s,description:s.text,source:link('原始资料',s.source)}))})),
  budgetFields:gb.budgetFields.map(f=>({...f,defaultValue:f.value,integer:f.step===1,group:['people','rooms'].includes(f.id)?'基础':['hotel-budget','food'].includes(f.id)?'住宿与餐饮':['consumption','electricity','night-kwh','loss','detour'].includes(f.id)?'用电与里程':'其他费用',variantScoped:false})),checks:checks.map(([id,title,detail])=>({id,title,detail,group:'出发前核对'})),sources:g.sources.map(([title,description,url])=>link(title,url,description)),notes:[audit.note,'地图节点为参考位置，不等于已获停车或车宿许可。酒店、充电、票务和当日道路情况须再次确认。','个人备注、清单和预算保存在本设备，可通过备份文件迁移；不会自动跨设备同步。'],returnOptions:returns,mapAsset:'assets/data/maps/ganwan.json',drivingAudit:audit,permitSteps:[],risks:[],legacyTaskIds:[]};

const [tm,tr,tl,tmap]=await Promise.all(['model','road-network','map-geography','map-renderer'].map(f=>moduleAt(refs.tibet,`src/${f}.js`)));
const tc=json(refs.tibet,'src/content.json'),td=tm.data;
const plain=nodes=>nodes.flatMap(n=>typeof n==='string'?[n]:[...(n.children?plain(n.children):[])]).join('');
const nodeLinks=nodes=>nodes.flatMap(n=>typeof n==='string'?[]:[...(n.tag==='a'&&n.href?[link(plain(n.children),n.href)]:[]),...(n.children?nodeLinks(n.children):[])]);
const tibetVariants=[],parity=[];
for(const scenario of ['A','B','C','C-ok','C-fail'])for(const branch of ['a','b','c'])for(const plan of ['A','B']){
  const state=tm.scenarioData(scenario,branch),route=tm.routeRows(state,plan),events=tm.detailRows(state,plan),segments=tm.segmentRows(state,plan),maps=tmap.mapDayData(scenario,branch,plan),id=`${scenario}_${branch}_${plan}`,defaults={...td.assumptions,mealDays:7,...tm.scenarioBudget(state)};
  const rows=[['9/27','拉萨 · 晚间取车','9/27 晚取车并验车，核对保险和取还车时刻。','0 km','时间待核实','3,650 m'],...route];
  const days=rows.map((r,index)=>{const date=r[0],revised=state.days[date],map=maps.find(d=>d.date===date),stay=td.stays.find(s=>s[0]===date),night=date==='10/3'?tm.overnight(plan):null;
    return {id:date,number:index,label:date,phase:index===0?'准备':'行程',title:r[1],focus:r[2],detail:revised?.note||r[2],geography:r[5],points:map?.points||[],mapPaths:[],color:colors[Math.max(0,index-1)%colors.length],km:null,minutes:null,
      facts:[fact('里程',r[3]),fact('驾驶',r[4]),fact('海拔',r[5])],navigation:segments.filter(s=>s[0]===date).map(s=>link(`${s[2]} → ${s[3]}`,`https://uri.amap.com/search?keyword=${encodeURIComponent(s[3])}&view=map`,`${s[6]}；${s[4]==null?'里程待核实':s[4]+' km'}；${s[5]}`)),
      overnight:{mode:index===0?'preparation':'hotel',title:revised?.hotel||night?.hotel||stay?.[2]||'取车与验车',region:revised?.points.at(-1)||night?.city||stay?.[1]||'拉萨',address:'以实际预订与导航为准',note:stay?.[3]||revised?.note||'',status:revised?.price==null&&revised?'店名或价格待补录':'原路书记录，当前预订状态需确认',reason:'',source:null,backup:null},
      events:events.filter(e=>e[0]===date).map(e=>({time:text(e[1]),place:text(e[2]),activity:text(e[3]),facts:[fact('里程',e[4]==null?'待核实':`${e[4]} km`),fact('驾驶',typeof e[5]==='number'?tm.drive(e[5]):e[5]),fact('海拔',e[6]==null?'待核实':`${e[6]} m`),fact('费用',e[7]),fact('提醒',e[8]),fact('关注等级',e[9])]}))};
  });
  tibetVariants.push({id,label:state.name,budgetScopeId:state.north?id:`${scenario}_${plan}`,budgetWarnings:state.days['9/30'].points.includes('珠峰大本营前')?['珠峰方向未指定具体入口，门票与换乘费未计入默认预算。实际进入前核对并补入额外费用。']:[],selectors:{scenario,branch,overnight:plan},days,budgetDefaults:defaults,pending:state.pending,tickets:tm.ticketEntries(state)});parity.push({kind:'tibet',variant:id,inputs:defaults,expected:tm.budgetTotals(defaults,plan)});
}
const fieldGroups=td.inputGroups.flatMap(g=>(g.id==='food'?['mealDays','meals']:g.keys).map(id=>({id,group:g.title})));
const tibetFields=fieldGroups.map(({id,group})=>({id,label:id==='mealDays'?'餐饮计费天数':td.labels[id],unit:['people','cars','rooms'].includes(id)?'个':['days','mealDays'].includes(id)?'天':id==='reserve'?'%':'',defaultValue:td.assumptions[id]??(id==='mealDays'?7:null),min:['people','cars','rooms','days','mealDays'].includes(id)?1:0,max:['people','cars','rooms'].includes(id)?30:['days','mealDays'].includes(id)?366:id==='reserve'?100:1000000,integer:['people','cars','rooms','days','mealDays'].includes(id),group,variantScoped:id.startsWith('hotel')||['routeKm','ticketPerson'].includes(id)}));
const generated=git(['ls-tree','-r','--name-only',refs.tibet,'--','assets/generated']).toString().trim().split('\n');
const tibetPhotos=generated.filter(f=>/\.(webp|png)$/.test(f)&&path.posix.basename(f)!=='cinna-tibet-logo.png').map(f=>({id:path.posix.basename(f,path.posix.extname(f)),asset:'assets/images/tibet/'+f.slice(7),title:'AI 意境配图，非实地照片或测绘地图',author:'原西藏路书素材',license:'原项目生成素材',licenseUrl:'',source:'',generated:true}));
const tibet={id:'tibet',selectionTag:'预案预览',title:'西藏自驾',subtitle:'拉萨出发 · 西藏高原公路',edition:'2026.09.28 — 10.04 · 9/27 晚取车',description:'七天、四个人、一辆六座四驱。按办证结果选择 A/B/C 路线，北线住宿与后半程方案独立切换。',defaultVariant:'B_a_A',coverId:'road',selectors:[{id:'scenario',label:'办证路线',options:[{id:'A',label:'A · 拉萨办理成功'},{id:'B',label:'B · 日喀则方向统一暂停'},{id:'C',label:'C · 待日喀则结果'},{id:'C-ok',label:'C · 日喀则办理成功'},{id:'C-fail',label:'C · 日喀则办理失败'}]},{id:'branch',label:'北线住宿分支',activeWhen:{scenario:['B','C-fail']},options:[{id:'a',label:'a · 措勤'},{id:'b',label:'b · 尼玛'},{id:'c',label:'c · 文布南村'}]},{id:'overnight',label:'10/3 住宿方案',options:[{id:'A',label:'申扎 · 博翔'},{id:'B',label:'班戈 · 华庭'}]}],variants:tibetVariants,sections:['overview','itinerary','map','stays','budget','checklist','risks','permits','sources'],photos:tibetPhotos,attractions:[],budgetFields:tibetFields,checks:td.tasks.map(task=>({...task,group:td.checklistGroups.find(group=>group[1].includes(task.id))?.[0]||'其他'})),risks:tm.riskRows,permitSteps:td.permitSteps,legacyTaskIds:td.legacyTaskIds,notes:[...tc.mapSources.map(n=>plain([n])),...tc.permitAlternative.map(n=>plain([n])),'以上为 2026 年原路书资料和参考图分支，不代表现在的办证政策、住宿价格或道路通行许可。'],sources:[...nodeLinks(tc.mapSources),...nodeLinks(tc.permitAlternative),...Object.entries(tm.ticketResearch).map(([name,t])=>link(name+' · '+t.source,t.url,t.note))],mapAsset:'assets/data/maps/tibet.json',returnOptions:null,drivingAudit:null};
for(const n of [15,16,17])for(const inputs of [{...gb.budgetDefaults},{...gb.budgetDefaults,people:3,rooms:2,loss:25,detour:20,contingency:10}])parity.push({kind:'ganwan',variant:String(n),inputs,expected:gb.estimateBudget(g.makePlan(n),audit,inputs),returnDifference:gr.returnBudgetDifference(g.makePlan(n),audit,returns,inputs)});
const points=Object.fromEntries(Object.entries(gmap.points).map(([id,p])=>[id,Array.isArray(p)?{name:id,coordinates:p}:{...p,coordinates:p.coordinates||[p.lon,p.lat]}]));
output('assets/data/ganwan.json',ganwan);output('assets/data/tibet.json',tibet);
output('assets/data/maps/ganwan.json',{...gmap,points,lakes:[],aliases:{},panels:[{title:'江门往返',bounds:[111.7,22.0,119.4,31.3]},{title:'赣皖游玩区域',bounds:[116.5,29.0,118.65,30.85]}]});
const shieldsLiteral=read(refs.tibet,'src/map-renderer.js').match(/const shields=(\[.*?\]);/s)?.[1];
if(!shieldsLiteral)throw new Error('Legacy highway labels missing');
const roadLabels=vm.runInNewContext(shieldsLiteral).flatMap(([label,lon,lat])=>{let point=null,distance=Infinity;for(const road of tr.roadNetwork.roads.filter(r=>r.ref===label))for(const p of road.coordinates){const d=Math.hypot((p[0]-lon)*.86,p[1]-lat);if(d<distance){point=p;distance=d;}}return point&&distance<=.4?[{id:label,name:label,coordinates:point}]:[];});
output('assets/data/maps/tibet.json',{fetched:tr.roadNetwork.queried,coordinateSystem:'WGS84',roadLabels,points:Object.fromEntries(Object.entries(tr.roadNetwork.points).map(([name,coordinates])=>[name,{name,coordinates}])),roads:tr.roadNetwork.roads,routes:tr.roadNetwork.routes,lakes:tl.mapLakeGeometry,aliases:{'桑桑':'桑桑镇','日喀则扎什伦布寺':'日喀则','日喀则政务大厅':'日喀则'},panels:[{title:'西藏高原公路',bounds:[84.6,27.8,91.7,32.4]}]});
output('assets/data/catalog.json',{schemaVersion:1,sourceCommits:refs,books:[ganwan,tibet].map(b=>({id:b.id,title:b.title,subtitle:b.subtitle,edition:b.edition,description:b.description,asset:`assets/data/${b.id}.json`,cover:b.photos.find(p=>p.id===b.coverId)}))});
output('test/fixtures/legacy-budget-parity.json',parity);copyImages(refs.ganwan,'ganwan');copyImages(refs.tibet,'tibet');
const inventory={sourceCommits:refs,ganwanVariants:ganwanVariants.length,tibetVariants:tibetVariants.length,attractions:ganwan.attractions.reduce((n,g)=>n+g.spots.length,0),tibetChecks:tibet.checks.length,tibetRisks:tibet.risks.length,parityCases:parity.length};
output('assets/data/migration-inventory.json',inventory);console.log(JSON.stringify({mode:check?'verified':'exported',...inventory}));
