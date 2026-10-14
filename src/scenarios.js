// Route decisions transcribed from the user's reference diagram; not a statement of current permit policy.


export const revisedDates=['9/29','9/30','10/1','10/2'];
export function scenarioData(permitScenario,northernBranch){
  const north=permitScenario==='B'||permitScenario==='C-fail';
  const south=permitScenario==='A'||permitScenario==='C-ok';
  const pending=permitScenario==='C';
  const days={};
  const day=(date,points,roads,note,hotel,price)=>days[date]={points,roads,note,hotel,price};
  if(permitScenario==='B')day('9/29',['拉萨','羊卓雍措','卡若拉冰川','江孜','日喀则'],['道路待导航确认','道路待导航确认','道路待导航确认','道路待导航确认'],'先办理 / 确认山南地区通行权限，以便走羊卓雍措线路。日喀则全季已订可退。','全季日喀则青岛路酒店',335.47);
  else if(permitScenario==='A')day('9/29',['拉萨','日喀则扎什伦布寺','拉孜'],['拉日高速','道路待导航确认'],'拉萨办证成功，按图中 Plan A 行进；当晚住拉孜。','拉孜住宿（待确认）',null);
  else day('9/29',['拉萨','日喀则政务大厅',...(permitScenario==='C-ok'?['拉孜']:[])],['拉日高速','道路待导航确认'],permitScenario==='C-ok'?'日喀则办理成功，前往拉孜住宿；9/30 起汇入 Plan A。':permitScenario==='C-fail'?'日喀则办理失败，当晚住日喀则全季；9/30 起汇入 Plan B，不补走羊湖—卡若拉冰川—江孜。':'优先在日喀则办理边境通行证：成功后去拉孜；失败则留宿日喀则，9/30 转 Plan B。',permitScenario==='C-ok'?'拉孜住宿（待确认）':pending?'待办证结果：拉孜 / 日喀则全季':'全季日喀则青岛路酒店',permitScenario==='C-fail'?335.47:null);
  if(south){
    day('9/30',['拉孜','珠峰大本营前','G219 南线边境县','萨嘎'],['道路待导航确认','G219 南线','G219 南线'],'图中为“珠峰大本营前”，不擅自扩展为进入大本营；具体停靠点、通行范围和车辆可达性待确认。','兰欧尚品酒店日喀则萨嘎店',863);
    day('10/1',['萨嘎','措勤'],['G216'],'按图中主线抵达措勤住宿。','锦江之星阿里措勤国道216店',858);
    day('10/2',['措勤','扎日南木错','当惹雍措','尼玛'],['道路待导航确认','道路待导航确认','道路待导航确认'],'当晚住尼玛，后续接 10/3 色林措路线。','尚客优那曲尼玛县政府客运站店',419.71);
  }else if(north){
    day('9/30',['日喀则','昂仁县','桑桑镇'],['北线 G349','北线 G349'],'桑桑住宿已确认（据参考图）；店名与价格待补录。','桑桑住宿（已确认，店名待补录）',null);
    const end=northernBranch==='a'?'措勤':northernBranch==='b'?'尼玛':'文布南村';
    day('10/1',['桑桑','达若','措迈','达果','当惹雍措',end],['S209（旧资料常标 S205）','S209','S209','S209','道路待导航确认'],'B-'+northernBranch+'：'+(northernBranch==='a'?'向西去措勤，住宿已订。':northernBranch==='b'?'向东去尼玛，当晚直接入住尼玛。':'住文布南村，有房才订；不提前锁定不可取消住宿。'),northernBranch==='a'?'锦江之星阿里措勤国道216店':northernBranch==='b'?'尼玛住宿（需确认新增一晚）':'文布南村住宿（有房才订）',northernBranch==='a'?858:null);
    day('10/2',northernBranch==='a'?['措勤','扎日南木错','当惹雍措','尼玛']:northernBranch==='b'?['尼玛','当惹雍措','尼玛']:['文布南村','当穹措','尼玛'],['道路待导航确认','道路待导航确认','道路待导航确认'],northernBranch==='b'?'从尼玛折返回来慢玩当惹雍措；为衔接 10/3 出发，暂按返回尼玛安排，回程需核实。':'按所选北线分支抵达尼玛。','尚客优那曲尼玛县政府客运站店',419.71);
  }else revisedDates.slice(1).forEach(date=>day(date,['待日喀则办证结果','成功汇入 Plan A / 失败汇入 Plan B'],['待定'],'办证结果未定，暂不确认当日路线与住宿。','待办证结果',null));
  return {days,north,pending,name:permitScenario==='A'?'Plan A · 拉萨办证成功':permitScenario==='B'?'Plan B · 日喀则方向统一暂停':permitScenario==='C-ok'?'Plan C · 日喀则办理成功':permitScenario==='C-fail'?'Plan C · 日喀则办理失败':'Plan C · 待日喀则办理结果'};
}
