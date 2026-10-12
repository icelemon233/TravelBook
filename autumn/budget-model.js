import {drivingFor} from './driving.js';

export const budgetFields = [
  {id:'people',label:'出行人数',unit:'人',value:1,min:1,max:20,step:1},
  {id:'rooms',label:'酒店房间数',unit:'间',value:1,min:1,max:20,step:1},
  {id:'hotel-budget',label:'酒店每间每晚',unit:'元',value:250,min:0,max:100000,step:'any'},
  {id:'food',label:'餐饮每人每天',unit:'元',value:80,min:0,max:100000,step:'any'},
  {id:'consumption',label:'行驶电耗',unit:'kWh / 100km',value:18,min:1,max:100,step:'any'},
  {id:'electricity',label:'综合充电单价',unit:'元 / kWh',value:1.5,min:0,max:100,step:'any'},
  {id:'night-kwh',label:'每个车宿晚用电',unit:'kWh',value:6,min:0,max:100,step:'any'},
  {id:'loss',label:'充电损耗占购电量',unit:'%',value:10,min:0,max:50,step:'any'},
  {id:'detour',label:'里程额外余量',unit:'%',value:10,min:0,max:100,step:'any'},
  {id:'tolls',label:'全程高速费总额',unit:'元 / 车',value:900,min:0,max:100000,step:'any'},
  {id:'tickets',label:'门票与景交合计',unit:'元 / 人 / 全程',value:500,min:0,max:100000,step:'any'},
  {id:'parking',label:'在外每晚停车预算',unit:'元 / 车',value:20,min:0,max:100000,step:'any'},
  {id:'other',label:'其他费用总额',unit:'元 / 全程',value:0,min:0,max:100000,step:'any'},
  {id:'contingency',label:'机动金比例',unit:'%',value:15,min:0,max:100,step:'any'}
];
export const budgetDefaults=Object.fromEntries(budgetFields.map(field=>[field.id,field.value]));
const money=value=>Math.round((value+Number.EPSILON)*100)/100;

export function estimateBudget(plan,audit,inputs){
  for(const field of budgetFields){
    const value=inputs[field.id];
    if(typeof value!=='number'||!Number.isFinite(value)||value<field.min||value>field.max||(field.step===1&&!Number.isInteger(value)))return {status:'invalid'};
  }
  const drives=plan.map(day=>drivingFor(day,audit));
  if(drives.some(drive=>!drive.complete))return {status:'loading'};
  const v=inputs,days=plan.length,hotelNights=plan.filter(day=>day.overnight.mode==='hotel').length,carNights=plan.filter(day=>day.overnight.mode==='car').length;
  const routeKm=Math.round(drives.reduce((sum,drive)=>sum+drive.km,0)*10)/10;
  const budgetKm=routeKm*(1+v.detour/100);
  const driveKwh=budgetKm*v.consumption/100,nightKwh=carNights*v['night-kwh'];
  const purchasedKwh=(driveKwh+nightKwh)/(1-v.loss/100);
  const items={hotel:money(hotelNights*v.rooms*v['hotel-budget']),food:money(days*v.people*v.food),charging:money(purchasedKwh*v.electricity),tolls:money(v.tolls),tickets:money(v.tickets*v.people),parking:money((hotelNights+carNights)*v.parking),other:money(v.other)};
  const subtotal=money(Object.values(items).reduce((sum,cost)=>sum+cost,0)),reserve=money(subtotal*v.contingency/100),total=money(subtotal+reserve);
  return {status:'ready',days,hotelNights,carNights,routeKm,budgetKm,driveKwh,nightKwh,purchasedKwh,items,subtotal,reserve,total,perPerson:money(total/v.people)};
}
