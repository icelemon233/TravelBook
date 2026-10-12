import {budgetFields,budgetDefaults,estimateBudget} from './budget-model.js';

const yuan=value=>new Intl.NumberFormat('zh-CN',{style:'currency',currency:'CNY',maximumFractionDigits:2}).format(value);
const number=value=>new Intl.NumberFormat('zh-CN',{maximumFractionDigits:1}).format(value);
export function mountBudget(savedInputs,onChange){
  const form=document.getElementById('budget-inputs');
  form.innerHTML=budgetFields.map(field=>`<label>${field.label}<span class="budget-unit">${field.unit}</span><input id="${field.id}" data-budget="${field.id}" type="number" min="${field.min}" max="${field.max}" step="${field.step}" value="${field.value}" required></label>`).join('');
  for(const field of budgetFields){
    const input=document.getElementById(field.id),saved=savedInputs[field.id];
    if(typeof saved==='string'&&saved.trim()!=='')input.value=saved;
  }
  let plan=[],audit=null;
  function update(nextPlan=plan,nextAudit=audit){
    plan=nextPlan;audit=nextAudit;
    const inputs=Object.fromEntries(budgetFields.map(field=>{const el=document.getElementById(field.id);el.setAttribute('aria-invalid',String(!el.validity.valid));return [field.id,el.value===''||!el.validity.valid?NaN:Number(el.value)];}));
    const result=estimateBudget(plan,audit,inputs),ready=result.status==='ready';
    document.getElementById('budget-total').textContent=ready?yuan(result.total):'—';
    document.getElementById('budget-person').textContent=ready?yuan(result.perPerson):'—';
    document.getElementById('budget-reserve').textContent=ready?yuan(result.reserve):'—';
    document.getElementById('budget-context').textContent=ready?`${result.days}天 · ${inputs.people}人 · ${inputs.rooms}间房 · 酒店${result.hotelNights}晚 · 车宿${result.carNights}晚 · 高德路线合计${number(result.routeKm)}km`:'按当前行程版本测算';
    document.getElementById('budget-status').textContent=result.status==='invalid'?'请检查预算参数：不得留空或超出范围，人数与房间数需为整数。':result.status==='loading'?'正在读取高德路线里程，稍后显示预算。':'已按当前参数计算；修改后自动更新，仅保存在当前浏览器。';
    if(!ready){document.getElementById('budget-rows').innerHTML='<tr><td colspan="3">填写有效参数并加载路线后显示明细。</td></tr>';document.getElementById('budget-energy').textContent='';return;}
    const rows=[
      ['酒店',`${result.hotelNights}晚 × ${inputs.rooms}间 × ${yuan(inputs['hotel-budget'])}`,result.items.hotel],
      ['餐饮',`${result.days}天 × ${inputs.people}人 × ${yuan(inputs.food)}`,result.items.food],
      ['充电',`预计购电${number(result.purchasedKwh)}kWh × ${yuan(inputs.electricity)}/kWh`,result.items.charging],
      ['高速通行',`全车全程暂按${yuan(inputs.tolls)}预留`,result.items.tolls],
      ['门票与景交',`${inputs.people}人 × 全程${yuan(inputs.tickets)}/人`,result.items.tickets],
      ['停车',`${result.hotelNights+result.carNights}个在外夜晚 × ${yuan(inputs.parking)}`,result.items.parking],
      ['其他费用','全程自定义费用',result.items.other],
      ['基础费用小计','以上七项合计',result.subtotal],
      ['机动金',`基础费用 × ${inputs.contingency}%`,result.reserve],
      ['合计','基础费用＋机动金',result.total]
    ];
    document.getElementById('budget-rows').innerHTML=rows.map(([name,basis,cost],i)=>`<tr${i===9?' class="budget-grand"':''}><th scope="row">${name}</th><td>${basis}</td><td>${yuan(cost)}</td></tr>`).join('');
    document.getElementById('budget-energy').textContent=`充电口径：${number(result.routeKm)}km ×（1＋${inputs.detour}%里程余量）＝${number(result.budgetKm)}km；行驶用电${number(result.driveKwh)}kWh＋车宿用电${number(result.nightKwh)}kWh，再除以（1－${inputs.loss}%充电损耗）。按全程能耗折算购电成本，包含出发前补入的电量。`;
  }
  form.addEventListener('input',event=>{if(!event.target.dataset.budget)return;onChange(event.target.id,event.target.value);update();});
  document.getElementById('budget-reset').addEventListener('click',()=>{for(const field of budgetFields){document.getElementById(field.id).value=budgetDefaults[field.id];onChange(field.id,String(budgetDefaults[field.id]));}update();});
  return {update};
}
