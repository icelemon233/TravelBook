import {makePlan,sources} from './trip-data.js';
import {estimateRange,estimateMorning} from './energy.js';
import {mountRouteMap} from './route-map.js';
import {mountAttractions} from './attractions.js';

const $ = id => document.getElementById(id);
const key = 'cinna-ganwan-v1';
const escape = value => String(value).replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
let saved = {};
try { const value=JSON.parse(localStorage.getItem(key)||'{}'); if(value && typeof value==='object' && !Array.isArray(value)) saved=value; } catch { storageError(); }
saved.notes = saved.notes && typeof saved.notes==='object' && !Array.isArray(saved.notes) ? saved.notes : {};
saved.checks = saved.checks && typeof saved.checks==='object' && !Array.isArray(saved.checks) ? saved.checks : {};
saved.inputs = saved.inputs && typeof saved.inputs==='object' && !Array.isArray(saved.inputs) ? saved.inputs : {};
let length = [15,16,17].includes(Number(saved.length)) ? Number(saved.length) : 16;
let phase = '全部';
let expanded = false;
const openDays = new Set(['out-1']);
const routeMap = mountRouteMap();
const attractions=mountAttractions(id=>{
  phase='全部';
  $('filters').querySelectorAll('[data-phase]').forEach(el=>el.setAttribute('aria-pressed',String(el.dataset.phase==='全部')));
  openDays.add(id);render();
  location.hash='day-'+id;
  document.getElementById('day-'+id)?.querySelector('summary').focus({preventScroll:true});
});
function storageError(){ $('storage-status').textContent='浏览器未能读取或保存本地数据，当前仍可使用页面；请另行记录备注。'; }
function save(){ try { localStorage.setItem(key,JSON.stringify(saved)); } catch { storageError(); } }
function mapLink(place){ return `https://uri.amap.com/search?keyword=${encodeURIComponent(place)}&view=map`; }
function render(){
  const plan=makePlan(length);
  routeMap.update(plan);
  attractions.update(plan);
  $('length').value=String(length);
  $('stat-days').innerHTML=`${length}<span>天</span>`;
  $('plan-counts').textContent=['去程','游玩','机动','返程'].map(p=>`${p}${plan.filter(day=>day.phase===p).length}天`).join(' / ');
  $('variant-note').textContent=length===15?'删去查济周边一天，保留六站、驾驶上限与机动日。':length===17?'增加一天可挪动缓冲；去程或返程超时就用它拆段，不添加景点。':'机动日可以移到任何需要它的位置；一切顺利可提前返程。';
  const hotelIds=['out-2','north','chaji','buffer','return-3'];
  $('hotel-nights').textContent=`参考恢复晚：${plan.map((day,index)=>hotelIds.includes(day.id)?`D${index+1}`:null).filter(Boolean).join('、')}；可随睡眠状态提前，非已预订。`;
  $('days').innerHTML=plan.map((day,index)=>`<details class="day" id="day-${day.id}" data-id="${day.id}" ${phase!=='全部'&&day.phase!==phase?'hidden':''} ${(expanded||openDays.has(day.id))?'open':''}><summary><span class="day-num">DAY ${String(index+1).padStart(2,'0')}</span><span class="day-heading"><strong>${escape(day.route)}</strong><span class="day-location">${escape(day.geography)}</span><small>${escape(day.focus)}</small></span><span class="phase phase-${day.phase}">${day.phase}</span></summary><div class="day-body"><p class="day-intro">${escape(day.detail)}</p><dl class="day-facts"><div><dt>道路与驾驶预算</dt><dd>${escape(day.road)} · ${escape(day.drive)}</dd></div><div><dt>落脚候选</dt><dd>${escape(day.stay)}</dd></div><div><dt>补能安排</dt><dd>${escape(day.charge)}</dd></div><div><dt>过夜与恢复</dt><dd>${escape(day.sleep)}</dd></div></dl><div class="map-links"><a href="${mapLink(day.from)}" target="_blank" rel="noopener noreferrer">查起点 ↗</a>${day.via?`<a href="${mapLink(day.via)}" target="_blank" rel="noopener noreferrer">查途经点 ↗</a>`:''}<a href="${mapLink(day.to)}" target="_blank" rel="noopener noreferrer">查终点 ↗</a><span class="fine">地点搜索，不代表路线或停车许可已核验</span></div><label class="day-note ${saved.notes[day.id]?'':'empty'}">自己的落脚点／主备充电站／确认结果<textarea data-note="${day.id}" maxlength="4000" placeholder="例如：酒店名称、停车许可、主充电站与备用站……">${escape(saved.notes[day.id]||'')}</textarea></label></div></details>`).join('');
  $('days').querySelectorAll('details').forEach(el=>el.addEventListener('toggle',()=>{ if(el.open) openDays.add(el.dataset.id); else openDays.delete(el.dataset.id); }));
  $('expand').textContent=expanded?'收起全部详情':'展开全部详情';
}
$('length').addEventListener('change',event=>{ length=Number(event.target.value); saved.length=length; save(); render(); });
$('filters').addEventListener('click',event=>{ const button=event.target.closest('[data-phase]'); if(!button) return; phase=button.dataset.phase; $('filters').querySelectorAll('[data-phase]').forEach(el=>el.setAttribute('aria-pressed',String(el===button))); render(); });
$('expand').addEventListener('click',()=>{ expanded=!expanded; if(!expanded)openDays.clear(); render(); });
$('days').addEventListener('input',event=>{ const id=event.target.dataset.note; if(!id)return; saved.notes[id]=event.target.value; event.target.closest('.day-note').classList.toggle('empty',!event.target.value); save(); });

const checks=[
  ['route','每天实际导航不超过5小时','用具体停车场／酒店做起终点，必要时提前落脚或拆段。'],
  ['charge','下一段主站与备用站都查过','确认AC/DC、接口、开放时间、近期状态及备用站可达。'],
  ['sleep','车宿点已获准过夜','确认停车许可、厕所、夜间出入和噪声，不只看地图有停车场。'],
  ['hotel','酒店恢复晚已有安排','床车每2–3晚恢复一次，停车与充电分别确认。'],
  ['night','整夜空调耗电有实测依据','睡前SOC覆盖夜耗、次日路程与备用电量。'],
  ['shuttle','阳产换乘与下山时间已查清','不按固定30元或固定末班时间做承诺。'],
  ['weather','天气、路况与开放情况已查','阴雨、封路或疲劳时使用机动日，不强求云海日出。'],
  ['offline','证件、随车用品与离线地图备齐','车宿用品、饮水、洗漱、补胎用品与道路救援信息。']
];
$('checks').innerHTML=checks.map(([id,title,body])=>`<label class="check-item"><input type="checkbox" data-check="${id}" ${saved.checks[id]===true?'checked':''}><span><strong>${title}</strong><small>${body}</small></span></label>`).join('');
function progress(){ $('check-progress').textContent=`${$('checks').querySelectorAll('input:checked').length} / ${checks.length} 已确认`; }
$('checks').addEventListener('change',event=>{ if(!event.target.dataset.check)return; saved.checks[event.target.dataset.check]=event.target.checked; save(); progress(); });
$('sources').innerHTML=sources.map(([title,description,url])=>`<div class="source"><a href="${url}" target="_blank" rel="noopener noreferrer">${title} ↗</a><p>${description}</p></div>`).join('');

const inputIds=['range','start-soc','reserve-soc','derate','battery','bed-soc','night-use','hotel-budget'];
for(const id of inputIds) { if(typeof saved.inputs[id]==='string') $(id).value=saved.inputs[id]; $(id).addEventListener('input',()=>{saved.inputs[id]=$(id).value;save(); calculate();}); }
function number(id){ const el=$(id); return el.value==='' || !el.validity.valid ? NaN : Number(el.value); }
function calculate(){
  const distance=estimateRange(number('range'),number('start-soc'),number('reserve-soc'),number('derate'));
  $('range-result').classList.toggle('error',distance===null);
  $('range-result').textContent=distance===null?'请填入有效数值，出发SOC需高于抵达保留SOC。':`粗估可规划 ${Math.floor(distance)} km`;
  const missing=$('battery').value===''||$('night-use').value==='';
  const morning=estimateMorning(number('battery'),number('bed-soc'),number('night-use'));
  $('night-result').classList.toggle('error',!missing && (morning===null||morning<20));
  $('night-result').textContent=missing?'填写电池容量与整夜总耗电后计算。':morning===null?'请检查电池容量、睡前SOC与整夜总耗电。':morning<0?'预计夜耗超过睡前可用电量，请先补电或改住酒店。':`早晨粗估剩余 ${morning.toFixed(1)}%${morning<20?'，需重新安排补能或过夜。':'；还需核对次日及备用站路程。'}`;
}
let printState=[];
window.addEventListener('beforeprint',()=>{printState=[...$('days').querySelectorAll('details')].map(el=>({el,open:el.open}));printState.forEach(({el})=>el.open=true);});
window.addEventListener('afterprint',()=>{printState.forEach(({el,open})=>el.open=open);printState=[];});
$('print').addEventListener('click',()=>window.print());
const observer=new IntersectionObserver(entries=>{ const current=entries.filter(entry=>entry.isIntersecting).sort((a,b)=>a.boundingClientRect.top-b.boundingClientRect.top)[0]; if(!current)return; document.querySelectorAll('.rail nav a').forEach(a=>{const active=a.hash===`#${current.target.id}`;a.classList.toggle('active',active);if(active)a.setAttribute('aria-current','location');else a.removeAttribute('aria-current');}); },{rootMargin:'-15% 0px -65% 0px'});
document.querySelectorAll('.section').forEach(section=>observer.observe(section));
render(); progress(); calculate();
