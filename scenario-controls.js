function syncScenarioControls(){
 const isC=permitScenario.startsWith('C');
 document.querySelectorAll('[name="permitPrimary"]').forEach(input=>input.checked=input.value===(isC?'C':permitScenario));
 document.querySelectorAll('[name="permitOutcome"]').forEach(input=>input.checked=input.value===permitScenario);
 document.querySelectorAll('[name="branchChoice"]').forEach(input=>input.checked=input.value===northernBranch);
 document.getElementById('permitResult').hidden=!isC;
 document.getElementById('branchStep').textContent=isC?'03':'02';
}
function setupScenarioControls(){
 const setSelect=(id,value)=>{const select=document.getElementById(id);select.value=value;select.dispatchEvent(new Event('change',{bubbles:true}));};
 document.querySelector('.scenario-fields').addEventListener('change',event=>{
  const input=event.target;
  if(input.name==='permitPrimary'||input.name==='permitOutcome')setSelect('permitScenario',input.value);
  if(input.name==='branchChoice')setSelect('northernBranch',input.value);
 });syncScenarioControls();
}
