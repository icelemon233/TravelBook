import data from './data.json';
import {scenarioData,revisedDates} from './scenarios.js';
import {ticketResearch} from './tickets.js';
export {data,scenarioData,revisedDates,ticketResearch};
export const allDays=['9/27','9/28',...revisedDates,'10/3','10/4'];
export const hotelIds=['hotel0929','hotel0930','hotel1001','hotel1002'];
export const overnight=plan=>plan==='A'?{city:'申扎',hotel:'申扎博翔大酒店',price:347.5}:{city:'班戈',hotel:'华庭酒店那曲班戈店',price:864};
export function ticketEntries(state){return [...new Set(Object.values(state.days).flatMap(d=>d.points))].filter(p=>ticketResearch[p]).map(name=>({name,...ticketResearch[name]}));}
export function scenarioBudget(state){return {routeKm:null,ticketPerson:ticketEntries(state).reduce((s,t)=>s+t.price,0),...Object.fromEntries(revisedDates.map((d,i)=>[hotelIds[i],state.days[d].price]))};}
export function routeRows(state,plan){return data.route.map(r=>{
 const d=state.days[r[0]];if(d)return [r[0],d.points[0]+' → '+d.points.at(-1),d.points.join(' → ')+'；'+d.note,'里程待核实','车程待核实','海拔待核实'];
 if(r[0]==='10/3')return [r[0],'尼玛 → 色林措 → '+overnight(plan).city,'达则错 → 天空之树 → 色林措 → '+overnight(plan).city,plan==='A'?'332.9 km':'333.9 km',plan==='A'?'4 小时 24 分':'4 小时 29 分',r[5]];
 if(r[0]==='10/4')return [r[0],overnight(plan).city+' → 贡嘎机场 → 亚悦','送机后至机场附近酒店；1 人当晚乘机，3 人次日乘机',plan==='A'?'459.4 km':'411.1 km',plan==='A'?'6 小时 10 分':'5 小时 31 分',r[5]];return r;
});}
export function detailRows(state,plan){const base=data.detail.filter(r=>!revisedDates.includes(r[0])&&(!/方案 [AB]/.test(r[1])||r[1].includes('方案 '+plan)));const fresh=revisedDates.flatMap(date=>{const d=state.days[date];return d.points.slice(1).map((p,i)=>[date,'第 '+(i+1)+' 段 · 时间待定',d.points[i],p,null,null,null,ticketResearch[p]?`¥${ticketResearch[p].price} / 人 · ${ticketResearch[p].status}`:p==='珠峰大本营前'?'费用取决于实际进入范围':'途经 / 住宿节点',d.note,'高']);});return [...base,...fresh].sort((a,b)=>allDays.indexOf(a[0])-allDays.indexOf(b[0]));}
export function segmentRows(state,plan){return [...revisedDates.flatMap(date=>{const d=state.days[date];return d.points.slice(1).map((p,i)=>[date,String(i+1),d.points[i],p,null,'车程待核实',d.roads[i]||'道路待导航确认']);}),...data.segments.filter(r=>!revisedDates.includes(r[0])&&(!['A','B'].includes(r[1])||r[1]===plan))];}
export function budgetTotals(v,plan){const num=k=>Number(v[k])||0;const car=num('cars')*num('days')*num('carDay'),fuel=num('routeKm')*num('cars')*num('fuelUse')/100*num('fuelPrice');const hotelKeys=['hotel0928',...hotelIds,plan==='A'?'hotel1003A':'hotel1003B'];const hotels=num('rooms')*hotelKeys.reduce((s,k)=>s+num(k),0)+num('hotel1004');const meals=num('people')*num('mealDays')*num('meals'),tickets=num('people')*num('ticketPerson')+num('extraTicket'),insurance=num('people')*num('insurancePrice'),supplies=2500,camera=num('pocket4p');const base=car+fuel+hotels+meals+tickets+insurance+supplies+camera,reserve=Math.round(base*num('reserve')/100);return {car,fuel,hotels,meals,tickets,insurance,supplies,camera,base,reserve,total:base+reserve,per:num('people')?(base+reserve)/num('people'):0};}
export const riskMeta={R01:['证件与路线',['9/28',...revisedDates]],R02:['道路与行车',['9/30']],R03:['道路与行车',['9/30','10/1']],R04:['证件与路线',['9/29','9/30']],R05:['住宿与补给',['10/1']],R06:['道路与行车',['10/2']],R07:['住宿与补给',['10/3','10/4']],R08:['拍摄',['10/3']],R09:['航班衔接',['10/4']],R10:['证件与路线',['9/28','9/29']],R14:['证件与路线',['9/30']],R11:['车辆与救援',allDays],R12:['住宿与补给',allDays],R13:['健康',allDays]};
export const riskRows=data.risks.map(r=>({key:r[0],id:r[0],scope:r[1],title:r[2],level:r[3],reason:r[4],action:r[5],trigger:r[6],category:riskMeta[r[0]][0],dates:riskMeta[r[0]][1]}));
export const money=n=>Number(n||0).toLocaleString('zh-CN',{minimumFractionDigits:2,maximumFractionDigits:2});
export const drive=n=>n==null?'时间待核实':n===0?'—':`${Math.floor(n)} 小时 ${Math.round(n%1*60)} 分`;
