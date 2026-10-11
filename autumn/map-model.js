// Stable day IDs keep map selections aligned when 15/16/17-day plans renumber.
const paths = {
  'out-1':[['jiangmen','shaoguan']], 'out-2':[['shaoguan','taihe']], 'out-3':[['taihe','fuliang']],
  yaoli:[['fuliang','yaoli']], qinghua:[['yaoli','jujing','qinghua']],
  north:[['qinghua','hongguan','qinghua'],['qinghua','zhangcun','qinghua']],
  shendu:[['qinghua','shendu']], yangchan:[['shendu','yangchan','shendu']],
  'chaji-transfer':[['shendu','chaji']], chaji:[['chaji']],
  taohuatan:[['chaji','taohuatan','chaji']], buffer:[['chaji']], extra:[['chaji']],
  'return-1':[['chaji','jingdezhen']], 'return-2':[['jingdezhen','taihe']],
  'return-3':[['taihe','shaoguan']], 'return-4':[['shaoguan','jiangmen']]
};
const colors = {
  'out-1':'#344d59','out-2':'#7e6036','out-3':'#856579',yaoli:'#b84727',qinghua:'#a67818',
  north:'#347968',shendu:'#426c9a',yangchan:'#96603c','chaji-transfer':'#735a9d',chaji:'#315849',
  taohuatan:'#47849a',buffer:'#827544',extra:'#827544',
  'return-1':'#914e65','return-2':'#5d63a1','return-3':'#98742e','return-4':'#427d79'
};
export function mapDays(plan){
  return plan.map((day,index)=>({...day,number:index+1,color:colors[day.id],paths:paths[day.id]}));
}
export function roadLeg(data,from,to){
  const forward=data.routes[`${from}|${to}`];
  if(forward)return forward.coordinates;
  const reverse=data.routes[`${to}|${from}`];
  return reverse ? [...reverse.coordinates].reverse() : null;
}
export function selectedMapDays(plan,id){
  const days=mapDays(plan);
  return id==='all'?days:days.filter(day=>day.id===id);
}
