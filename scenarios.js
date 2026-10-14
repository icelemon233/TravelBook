// Route decisions transcribed from the user's reference diagram; not a statement of current permit policy.
let permitScenario='B';
let northernBranch='a';
const revisedDates=['9/29','9/30','10/1','10/2'];
function scenarioData(){
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
function applyScenarioData(){
  const state=scenarioData();
  revisedDates.forEach(date=>{
    const d=state.days[date];
    route.splice(route.findIndex(r=>r[0]===date),1,[date,d.points[0]+' → '+d.points.at(-1),d.points.join(' → ')+'；'+d.note,'里程待核实','车程待核实','海拔待核实','高']);
    stays.splice(stays.findIndex(r=>r[0]===date),1,[date,d.points.at(-1),d.hotel,d.note]);
    stayVisuals[date]={price:d.price};
  });
  const newDetail=[],newSegments=[];
  revisedDates.forEach(date=>{const d=state.days[date];d.points.slice(1).forEach((point,i)=>{
    newDetail.push([date,'第 '+(i+1)+' 段 · 时间待定',d.points[i],point,null,null,null,researchedTicketLabel(point),d.note,'高']);
    newSegments.push([date,String(i+1),d.points[i],point,null,'车程待核实',d.roads[i]||'道路待导航确认']);
  });});
  detail.splice(0,detail.length,...detail.filter(r=>!revisedDates.includes(r[0])).concat(newDetail).sort((a,b)=>['9/28',...revisedDates,'10/3','10/4'].indexOf(a[0])-['9/28',...revisedDates,'10/3','10/4'].indexOf(b[0])));
  segments.splice(0,segments.length,...newSegments,...segments.filter(r=>!revisedDates.includes(r[0])));
  document.getElementById('scenarioStatus').textContent='当前预览：'+state.name+(state.north?' / B-'+northernBranch:'')+'。尚未记录实际办证结果；以下路线按所选情形展示。门票已查询并填入预算；9/29—10/2 里程与时刻尚未获取高德结果。';
  document.getElementById('branchField').hidden=!state.north;
}
function drawScenarioTickets(){
  const list=scenarioTicketEntries();
  ticketBody.innerHTML='<p class="ticket-source-note">查询日期：2026-09-20。下列金额已自动计入当前分支门票预算；官方公示、历史公告和平台信息分别标注。费用不含额外停车、观光车或其他消费。</p>'+list.map(t=>'<article class="ticket-entry"><div><span>'+t.status+'</span><h4>'+t.name+'</h4><p>'+t.note+'</p><a href="'+t.url+'" target="_blank" rel="noopener noreferrer">'+t.source+' ↗</a></div><strong>¥'+t.price+'<small> / 人</small></strong></article>').join('');
  if(scenarioData().pending)ticketBody.innerHTML+='<p>Plan C 后续分支取决于办证结果，选择成功或失败后展示对应门票。</p>';
  if(scenarioData().days['9/30'].points.includes('珠峰大本营前'))ticketBody.innerHTML+='<p>Plan A 的“珠峰大本营前”尚未指定具体入口及停车点，不能等同于不进入收费区。其门票、车辆及换乘费用未计入以上合计。</p>';
}
function updateScenarioBudget(){
  const s=scenarioData();
  revisedDates.forEach(date=>{const key='hotel'+date.replace('/','').padStart(4,'0');const id={'9/29':'hotel0929','9/30':'hotel0930','10/1':'hotel1001','10/2':'hotel1002'}[date];const el=document.getElementById(id);el.value=s.days[date].price??'';el.placeholder='待填';document.querySelector('label[for="'+id+'"]').textContent=date+' '+s.days[date].hotel+' / 间';});
  document.getElementById('routeKm').value='';document.getElementById('ticketPerson').value=researchedTicketTotal();
}
