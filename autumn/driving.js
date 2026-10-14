export const drivingLegIds={
  'out-1':['out-1'],'out-2':['out-2'],'out-3':['out-3'],yaoli:['yaoli'],qinghua:['qinghua-a','qinghua-b'],north:['north-a','north-b'],shendu:['shendu'],yangchan:['yangchan-a','yangchan-b'],'chaji-transfer':['chaji-transfer'],taohuatan:['taohuatan-a','taohuatan-b'],'return-1':['return-1'],'return-2':['return-2'],'return-3':['return-3'],'return-4':['return-4']
};
export function drivingFor(day,audit){
  if(['chaji','buffer','extra'].includes(day.id))return {complete:true,minutes:0,km:0,legs:[],label:'不安排驾车 · 停车步行／休息'};
  const ids=day.drivingLegIds||drivingLegIds[day.id]||[];
  const legs=ids.map(id=>audit?.legs?.find(leg=>leg.id===id)).filter(Boolean);
  if(!ids.length||legs.length!==ids.length)return {complete:false,legs,label:'高德具体起终点核对中'};
  const minutes=legs.reduce((sum,leg)=>sum+leg.minutes,0),km=Math.round(legs.reduce((sum,leg)=>sum+leg.km,0)*10)/10;
  const duration=`${minutes>=60?`${Math.floor(minutes/60)}小时`:''}${minutes%60?`${minutes%60}分钟`:''}`;
  return {complete:true,minutes,km,legs,label:`高德预计${duration} · ${km}km${legs.length>1?'（分段合计）':''}${minutes>300?' · 超过5小时，需拆段':minutes>=270?' · 接近5小时上限':''}`};
}

const escape=value=>String(value).replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
export function drivingLinks(drive){return drive.legs.map((leg,i)=>`<a href="${escape(leg.url)}" target="_blank" rel="noopener noreferrer">${drive.legs.length>1?`第${i+1}段`:'本段'}高德路线 ↗</a>`).join('');}
export function renderDriving(plan,audit){
  document.getElementById('driving-rows').innerHTML=plan.map((day,index)=>{
    const drive=drivingFor(day,audit);
    return `<tr><th scope="row">Day${index+1}</th><td><strong>${escape(day.route)}</strong><p>${escape(drive.label)}</p>${drive.legs.length?`<details><summary>起终点、道路与查询依据</summary>${drive.legs.map(leg=>`<p>${escape(leg.from)} → ${escape(leg.to)}<br><small>${escape(leg.roads)} · ${escape(leg.policy)}${leg.routeChoice>1?` · 当次第${leg.routeChoice}个方案，重开后请按上述道路选择`:''}</small></p>`).join('')}<div class="night-links">${drivingLinks(drive)}</div></details>`:''}</td></tr>`;
  }).join('');
}
