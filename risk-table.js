function setupRiskTable(rows){
 const dates=['9/28','9/29','9/30','10/1','10/2','10/3','10/4'];
 const meta={
  R01:['证件与路线',dates.slice(0,5)],R02:['道路与行车',['9/30']],R03:['道路与行车',['9/30','10/1']],
  R04:['证件与路线',['9/29','9/30']],R05:['住宿与补给',['10/1']],R06:['道路与行车',['10/2']],
  R07:['住宿与补给',['10/3','10/4']],R08:['拍摄',['10/3']],R09:['航班衔接',['10/4']],
  R10:['证件与路线',['9/28','9/29']],R14:['证件与路线',['9/30']],
  R11:['车辆与救援',dates],R12:['住宿与补给',dates],R13:['健康',dates]
 };
 const escape=text=>String(text).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 const categories=[...new Set(rows.map(r=>meta[r[0]][0]))];
 const options=items=>items.map(v=>`<option value="${escape(v)}">${escape(v)}</option>`).join('');
 const root=document.getElementById('riskList');
 root.innerHTML=`<form class="risk-filters" id="riskFilters" role="search" aria-label="筛选风险应对">
 <label>日期<select id="riskDate"><option value="">全部日期</option>${options(dates)}</select></label>
 <label>风险等级<select id="riskLevel"><option value="">全部等级</option>${options(['极高','高','中'])}</select></label>
 <label>风险类别<select id="riskCategory"><option value="">全部类别</option>${options(categories)}</select></label>
 <label class="risk-search">关键词<input id="riskSearch" type="search" placeholder="搜索路线、触发条件或应对措施" autocomplete="off"></label>
 <button type="reset">重置筛选</button></form>
 <div class="risk-results"><p id="riskCount" role="status" aria-live="polite"></p><span>日期筛选包含全程事项；手机可横向滑动表格。</span></div>
 <div class="risk-table-scroll" tabindex="0" role="region" aria-label="风险应对表格，可横向滚动">
 <table class="risk-table"><caption>各路线预案风险与应对措施</caption><colgroup><col class="risk-col-id"><col class="risk-col-scope"><col class="risk-col-level"><col class="risk-col-topic"><col class="risk-col-action"><col class="risk-col-trigger"></colgroup>
 <thead><tr><th scope="col">编号 / 类别</th><th scope="col">适用日期 / 场景</th><th scope="col">等级</th><th scope="col">风险与原因</th><th scope="col">应对措施</th><th scope="col">触发条件 / 重点关注</th></tr></thead><tbody id="riskTableBody"></tbody></table></div>`;
 const form=document.getElementById('riskFilters'),date=document.getElementById('riskDate'),level=document.getElementById('riskLevel'),category=document.getElementById('riskCategory'),search=document.getElementById('riskSearch');
 function render(){
  const terms=search.value.trim().toLocaleLowerCase().split(/\s+/).filter(Boolean);
  const result=rows.filter(r=>{const [cat,ds]=meta[r[0]];const text=[...r,cat,...ds].join(' ').toLocaleLowerCase();return (!date.value||ds.includes(date.value))&&(!level.value||level.value===r[3])&&(!category.value||category.value===cat)&&terms.every(t=>text.includes(t));});
  document.getElementById('riskCount').textContent=`显示 ${result.length} / ${rows.length} 项风险`;
  document.getElementById('riskTableBody').innerHTML=result.length?result.map(r=>{const [cat,ds]=meta[r[0]];return `<tr><th scope="row"><strong>${escape(r[0])}</strong><span>${escape(cat)}</span></th><td><b>${ds.length===dates.length?'全程':ds.join('、')}</b><span>${escape(r[1])}</span></td><td><span class="risk-level" data-level="${escape(r[3])}">${escape(r[3])}</span></td><td><strong>${escape(r[2])}</strong><p>${escape(r[4])}</p></td><td>${escape(r[5])}</td><td>${escape(r[6])}</td></tr>`;}).join(''):'<tr><td colspan="6" class="risk-empty">没有符合条件的风险项。可减少关键词，或点击“重置筛选”查看全部。</td></tr>';
 }
 form.addEventListener('submit',e=>e.preventDefault());form.addEventListener('input',render);form.addEventListener('change',render);
 form.addEventListener('reset',()=>{requestAnimationFrame(render)});render();
}
