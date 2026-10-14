import {returnScenario,returnBudgetDifference} from './return-options-model.js';
import {budgetFields} from './budget-model.js?v=returns-1';

const escape=value=>String(value).replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
const duration=minutes=>`${Math.floor(minutes/60)}小时${minutes%60?`${minutes%60}分`:''}`;
const yuan=value=>`¥${new Intl.NumberFormat('zh-CN',{maximumFractionDigits:0}).format(value)}`;
const modeText={car:'拟住车里 · 停车点待定',hotel:'拟住酒店 · 门店待定',home:'回家'};
const change=(value,unit)=>value===0?`${unit}不变`:`${unit}${value>0?'增加':'减少'}${Math.abs(value)}`;
export function renderReturnOptions(plan,data,audit){
  const host=document.getElementById('return-options-list');
  if(!data){host.innerHTML='<p class="fine">正在读取高德返程查询记录。</p>';return;}
  const scenarios=data.options.map(option=>returnScenario(plan,data,option.id));
  host.innerHTML=scenarios.map(scenario=>{
    const {option,legs}=scenario;
    return `<article class="return-card return-${option.id}"><div class="return-card-head"><span class="mini-label">${option.subtitle}</span><h3>${option.title}</h3><p class="return-route">${option.route}</p><div class="return-metrics"><span><strong>${scenario.km.toLocaleString('zh-CN')}</strong>km</span><span><strong>${duration(scenario.minutes)}</strong>纯驾驶</span><span><strong>${legs.length}天</strong>返程</span></div><p>${option.summary}</p><p class="fine">按当前${plan.length}天版的游玩安排衔接，全程共${scenario.days}天。${scenario.movedExtra?'原额外缓冲日移给返程，不叠加第18天。':''}</p></div><div class="return-days">${legs.map((leg,i)=>`<div class="return-day"><div class="return-day-label">返程第${i+1}天 <span>Day${scenario.firstDay+i}</span></div><div><h4>${leg.fromLabel} → ${leg.toLabel}</h4><p class="return-region">${leg.fromRegion} → ${leg.toRegion}</p><p><b>${duration(leg.minutes)} · ${leg.km}km</b></p><p class="return-stay">${modeText[option.nightModes[i]]}${option.nightModes[i]!=='home'?`<br>落脚区：${leg.toRegion}`:''}</p><details><summary>高德参考点与道路</summary><p>${escape(leg.from)} → ${escape(leg.to)}</p><p>${escape(leg.roads)}</p>${leg.routeChoice>1?'<p class="return-choice">当次选择第3个方案；重新打开后按上述道路选择，避免默认路线走回来时走廊。</p>':''}<p>高德小客车通行估算：${yuan(leg.tolls)}</p><a href="${escape(leg.url)}" target="_blank" rel="noopener noreferrer">打开本段高德路线 ↗</a></details></div></div>`).join('')}</div><div class="return-card-foot"><p>${option.note}</p><p>分段通行费估算合计${yuan(scenario.tolls)}，不含充电、停车与餐饮。</p>${option.direct?`<a href="${escape(option.direct.url)}" target="_blank" rel="noopener noreferrer">查看直达高速候选 ↗</a>`:''}</div></article>`;
  }).join('');
  const [short,loop]=scenarios;
  document.getElementById('return-comparison').textContent=`方案B比A多${Math.round((loop.km-short.km)*10)/10}km、${duration(loop.minutes-short.minutes)}纯驾驶，分段通行费估算多${yuan(loop.tolls-short.tolls)}。推荐优先选A；想换一条长途走廊、接受5天返程则选B。`;
  renderReturnCost(plan,data,audit);
}
export function renderReturnCost(plan,data,audit){
  const inputs=Object.fromEntries(budgetFields.map(field=>{const el=document.getElementById(field.id);return [field.id,!el||el.value===''||!el.validity.valid?NaN:Number(el.value)];}));
  const difference=returnBudgetDifference(plan,audit,data,inputs);
  document.getElementById('return-budget-diff').textContent=difference?`按上方预算参数（${inputs.people}人、${inputs.rooms}间房），方案B比A预计${difference.delta>=0?'多':'少'}约${yuan(Math.abs(difference.delta))}，含机动金。${change(difference.days,'天数')}、${change(difference.hotels,'酒店晚数')}、${change(difference.cars,'车宿晚数')}；通行费差额采用本次高德估算。此处仅比较差额，不覆盖上方原方案总预算。`:'填写有效预算参数并加载路线后，显示两种返程的预算差额。';
}
