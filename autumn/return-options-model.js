import {estimateBudget} from './budget-model.js?v=returns-1';

export function returnScenario(plan,data,id){
  const option=data.options.find(option=>option.id===id);
  if(!option)throw new Error('Unknown return option');
  const legs=option.legIds.map(id=>data.legs.find(leg=>leg.id===id));
  if(legs.some(leg=>!leg))throw new Error('Missing return leg');
  // The existing extra day becomes the fifth return day, rather than adding an 18th day.
  const prefix=plan.filter(day=>day.phase!=='返程'&&(id!=='loop'||day.id!=='extra'));
  const returnDays=legs.map((leg,i)=>({id:leg.id,phase:'返程',drivingLegIds:[leg.id],route:`${leg.fromLabel} → ${leg.toLabel}`,overnight:{mode:option.nightModes[i]}}));
  return {option,legs,plan:[...prefix,...returnDays],firstDay:prefix.length+1,days:prefix.length+legs.length,km:Math.round(legs.reduce((sum,leg)=>sum+leg.km,0)*10)/10,minutes:legs.reduce((sum,leg)=>sum+leg.minutes,0),tolls:legs.reduce((sum,leg)=>sum+leg.tolls,0),movedExtra:id==='loop'&&plan.some(day=>day.id==='extra')};
}

export function returnBudgetDifference(plan,audit,data,inputs){
  if(!data||!audit)return null;
  const combined={legs:[...audit.legs,...data.legs]};
  const scenarios=['short','loop'].map(id=>returnScenario(plan,data,id));
  // Only compare differences: outbound tolls are shared and cancel. Never present these totals as whole-trip quotes.
  const estimates=scenarios.map(scenario=>estimateBudget(scenario.plan,combined,{...inputs,tolls:scenario.tolls}));
  if(estimates.some(result=>result.status!=='ready'))return null;
  return {delta:Math.round((estimates[1].total-estimates[0].total)*100)/100,days:scenarios[1].days-scenarios[0].days,hotels:estimates[1].hotelNights-estimates[0].hotelNights,cars:estimates[1].carNights-estimates[0].carNights};
}
