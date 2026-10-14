import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {makePlan} from '../autumn/trip-data.js';
import {estimateRange,estimateMorning} from '../autumn/energy.js';
import {mapDays,roadLeg,selectedMapDays} from '../autumn/map-model.js';
import {attractionGroups,attractionDays} from '../autumn/attractions-data.js';
import {drivingFor} from '../autumn/driving.js';
import {estimateBudget,budgetDefaults,budgetFields} from '../autumn/budget-model.js';
import {returnScenario,returnBudgetDifference} from '../autumn/return-options-model.js';

test('两种返程高德记录连续且每天不超过5小时，环线不叠加第18天',()=>{
  const data=JSON.parse(fs.readFileSync('autumn/return-options-data.json','utf8'));
  assert.equal(data.legs.length,9);assert.equal(new Set(data.legs.map(leg=>leg.id)).size,9);
  for(const leg of data.legs){
    const url=new URL(leg.url);assert.equal(url.hostname,'www.amap.com');
    assert.equal(url.searchParams.get('fname'),leg.from);assert.equal(url.searchParams.get('dname'),leg.to);
    assert.ok(url.searchParams.get('fid')&&url.searchParams.get('did'));
    assert.ok(leg.minutes>0&&leg.minutes<=300&&leg.km>0&&leg.tolls>=0);
    assert.match(leg.fromRegion,/省 · .*市/);assert.match(leg.toRegion,/省 · .*市/);
    assert.equal(leg.checkedDate,'2026-10-15');
  }
  for(const n of [15,16,17]){
    const original=makePlan(n),before=structuredClone(original);
    const a=returnScenario(original,data,'short'),b=returnScenario(original,data,'loop');
    assert.equal(a.days,n);assert.equal(b.days,n===17?17:n+1);
    assert.equal(a.km,1365.5);assert.equal(b.km,1486.6);assert.equal(a.minutes,950);assert.equal(b.minutes,1040);
    assert.equal(a.tolls,655);assert.equal(b.tolls,683);
    for(const scenario of [a,b]){
      for(let i=1;i<scenario.legs.length;i++)assert.equal(scenario.legs[i-1].to,scenario.legs[i].from);
      assert.equal(scenario.plan.at(-1).overnight.mode,'home');
      assert.ok(scenario.plan.filter(day=>day.phase!=='返程').every(day=>original.some(old=>old.id===day.id)));
    }
    assert.deepEqual(original,before);
  }
  for(const id of ['loop-4','loop-5'])assert.equal(data.legs.find(leg=>leg.id===id).routeChoice,3);
  assert.match(data.legs.find(leg=>leg.id==='loop-4').roads,/G0421许广/);
  assert.ok(data.options[0].direct.alternativesKm.every(km=>km>=data.options[0].direct.km));
});

test('返程预算差额纳入额外一天和酒店，人数与房间单独联动',()=>{
  const data=JSON.parse(fs.readFileSync('autumn/return-options-data.json','utf8')),audit=JSON.parse(fs.readFileSync('autumn/amap-times.json','utf8'));
  const plan=makePlan(16),result=returnBudgetDifference(plan,audit,data,budgetDefaults);
  assert.ok(Math.abs(result.delta-480.66)<0.03);assert.equal(result.hotels,1);assert.equal(result.days,1);assert.equal(result.cars,0);
  const people=returnBudgetDifference(plan,audit,data,{...budgetDefaults,people:2});
  assert.ok(Math.abs(people.delta-result.delta-92)<0.03);
  const rooms=returnBudgetDifference(plan,audit,data,{...budgetDefaults,rooms:2});
  assert.ok(Math.abs(rooms.delta-result.delta-287.5)<0.03);
  assert.equal(returnBudgetDifference(plan,null,data,budgetDefaults),null);
  assert.equal(returnBudgetDifference(plan,audit,data,{...budgetDefaults,people:NaN}),null);
});

test('预算区分按人、按车和按房计费，包含夜耗、损耗与一次机动金',()=>{
  const plan=[{id:'out-1',overnight:{mode:'car'}},{id:'chaji',overnight:{mode:'hotel'}},{id:'return-4',overnight:{mode:'home'}}];
  const audit={legs:[{id:'out-1',km:100,minutes:100},{id:'return-4',km:200,minutes:150}]};
  const inputs={...budgetDefaults,people:2,rooms:1,'hotel-budget':100,food:10,consumption:20,electricity:2,'night-kwh':5,loss:20,detour:0,tolls:50,tickets:20,parking:5,contingency:10};
  const result=estimateBudget(plan,audit,inputs);
  assert.equal(result.status,'ready');
  assert.equal(result.routeKm,300);assert.equal(result.purchasedKwh,81.25);
  assert.deepEqual(result.items,{hotel:100,food:60,charging:162.5,tolls:50,tickets:40,parking:10,other:0});
  assert.equal(result.subtotal,422.5);assert.equal(result.reserve,42.25);
  assert.equal(result.total,464.75);assert.equal(result.perPerson,232.38);
  const twoRooms=estimateBudget(plan,audit,{...inputs,rooms:2});assert.equal(twoRooms.items.hotel,200);assert.equal(twoRooms.items.tolls,50);
});

test('预算随15/16/17天联动，无效参数或缺失路线不显示不完整总额',()=>{
  const audit=JSON.parse(fs.readFileSync('autumn/amap-times.json','utf8'));
  const variants=[15,16,17].map(length=>estimateBudget(makePlan(length),audit,budgetDefaults));
  for(const [i,result] of variants.entries()){
    assert.equal(result.status,'ready');assert.equal(result.days,15+i);
    assert.equal(result.hotelNights,5);assert.equal(result.carNights,9+i);
    assert.equal(result.items.hotel,1250);assert.equal(result.items.parking,(14+i)*20);
  }
  assert.equal(variants[1].routeKm,3002.4);assert.equal(variants[1].total,6118.91);
  assert.equal(variants[1].routeKm,variants[2].routeKm);
  assert.ok(variants[0].routeKm<variants[1].routeKm);
  assert.ok(variants[0].total<variants[1].total&&variants[1].total<variants[2].total);
  for(const patch of [{people:0},{people:1.5},{rooms:0},{loss:100},{food:NaN},{tolls:-1},{electricity:Infinity},{other:''}])assert.equal(estimateBudget(makePlan(16),audit,{...budgetDefaults,...patch}).status,'invalid');
  assert.equal(estimateBudget(makePlan(16),null,budgetDefaults).status,'loading');
  const zero={...budgetDefaults,...Object.fromEntries(['hotel-budget','food','electricity','tolls','tickets','parking','other'].map(id=>[id,0]))};
  assert.equal(estimateBudget(makePlan(16),audit,zero).total,0);
  assert.equal(new Set(budgetFields.map(field=>field.id)).size,budgetFields.length);
});

test('18条高德查询覆盖所有驾驶日，合计正确且链接对应具体起终点',()=>{
  const audit=JSON.parse(fs.readFileSync('autumn/amap-times.json','utf8'));
  assert.equal(audit.legs.length,18);
  assert.equal(new Set(audit.legs.map(leg=>leg.id)).size,18);
  for(const leg of audit.legs){
    assert.ok(leg.minutes>0&&leg.km>0&&leg.roads);
    const url=new URL(leg.url);assert.equal(url.hostname,'www.amap.com');
    assert.ok(leg.from.endsWith(url.searchParams.get('fname')),leg.id);
    assert.ok(leg.to.endsWith(url.searchParams.get('dname')),leg.id);
    assert.ok(url.searchParams.get('fid')&&url.searchParams.get('did'));
  }
  for(const length of [15,16,17])for(const day of makePlan(length)){
    const drive=drivingFor(day,audit);assert.ok(drive.complete,day.id);
    assert.ok(drive.minutes<=300,day.id);
    if(drive.legs.length){
      assert.equal(drive.minutes,drive.legs.reduce((sum,leg)=>sum+leg.minutes,0));
      for(let i=1;i<drive.legs.length;i++)assert.equal(drive.legs[i-1].to,drive.legs[i].from);
      if(day.overnight.mode!=='home'){
        const normalize=text=>text.replaceAll('（','(').replaceAll('）',')');
        assert.ok(normalize(drive.legs.at(-1).to).endsWith(normalize(day.overnight.place.name)),day.id);
      }
    }
  }
  const plan=makePlan(16);
  assert.equal(drivingFor(plan.find(d=>d.id==='qinghua'),audit).minutes,70);
  assert.equal(drivingFor(plan.find(d=>d.id==='return-2'),audit).minutes,290);
  const highway=audit.legs.find(l=>l.id==='return-1');
  assert.equal(highway.routeChoice,3);assert.match(highway.roads,/G50沪渝高速/);
  assert.match(highway.from,/查济/);assert.match(highway.to,/浮梁/);
  assert.equal(drivingFor(plan[0],{legs:[]}).complete,false);
});

test('每晚住宿覆盖全部版本、同步日程且连续车宿不超过三晚',()=>{
  for(const length of [15,16,17]){
    const plan=makePlan(length);let consecutive=0;
    for(const day of plan){
      const night=day.overnight;
      assert.ok(['car','hotel','home'].includes(night.mode));
      assert.ok(night.place.name&&night.place.address&&night.place.region);
      assert.match(night.place.region,/省 · .*市/);
      assert.ok(day.stay.includes(night.place.name));
      assert.ok(day.sleep.includes(night.reason));
      if(night.mode!=='home')assert.ok(new URL(night.place.source).protocol==='https:');
      if(night.mode==='car'){
        assert.ok(night.fallback?.name&&night.fallback?.source);
        assert.match(night.status,/待确认/);consecutive++;
      }else consecutive=0;
      assert.ok(consecutive<=3,day.id);
      if(night.mode==='hotel')assert.ok(!/民宿|客栈|农家乐/.test(night.place.name));
    }
    assert.equal(plan.filter(d=>d.overnight.mode==='hotel').length,5);
    assert.equal(plan.filter(d=>d.overnight.mode==='car').length,length-6);
    assert.equal(plan.at(-1).overnight.mode,'home');
    assert.equal(plan.find(d=>d.id==='yangchan').overnight.placeId,'shenduPark');
    assert.equal(plan.find(d=>d.id==='chaji-transfer').from,'安徽省黄山市歙县深渡镇');
  }
  const changed=makePlan(16);changed[0].overnight.place.name='changed';
  assert.notEqual(makePlan(16)[0].overnight.place.name,'changed');
});

test('景点目录覆盖12处且各版本Day映射和图片授权有效',()=>{
  const spots=attractionGroups.flatMap(group=>group.spots);
  assert.equal(spots.length,12);
  assert.equal(new Set(spots.map(spot=>spot.id)).size,12);
  const photos=JSON.parse(fs.readFileSync('autumn/photo-sources.json','utf8'));
  for(const group of attractionGroups){
    assert.match(group.region,/省 · .*市 · .*县/);
    if(group.photo){const photo=photos[group.photo];assert.ok(photo.author&&photo.license&&photo.licenseUrl&&photo.source);assert.ok(fs.existsSync(photo.local));}
    for(const spot of group.spots)for(const length of [15,16,17]){
      const plan=makePlan(length),mapped=attractionDays(spot,plan);
      assert.ok(mapped.every(day=>plan[day.number-1].id===day.id));
      assert.equal(mapped.length,spot.dayIds.filter(id=>plan.some(day=>day.id===id)).length);
    }
  }
  const optional=spots.find(spot=>spot.id==='taohuatan-scenic');
  assert.equal(attractionDays(optional,makePlan(15)).length,0);
  assert.equal(attractionDays(optional,makePlan(16))[0].number,11);
});

test('15/16/17天保持六站顺序、三天去程和四天返程',()=>{
  for(const length of [15,16,17]){
    const plan=makePlan(length);
    assert.equal(plan.length,length);
    assert.equal(plan.filter(d=>d.phase==='去程').length,3);
    assert.equal(plan.filter(d=>d.phase==='返程').length,4);
    assert.equal(new Set(plan.map(d=>d.id)).size,length);
    const ids=['yaoli','qinghua','north','shendu','yangchan','chaji-transfer','chaji'].map(id=>plan.findIndex(d=>d.id===id));
    assert.ok(ids.every((index,i)=>index>=0&&(i===0||index>ids[i-1])));
    assert.equal(plan.filter(d=>d.phase==='机动').length,length===17?2:1);
  }
  assert.ok(!makePlan(15).some(d=>d.id==='taohuatan'));
  assert.ok(makePlan(16).some(d=>d.id==='taohuatan'));
});
test('行程版本切换不改变原方案，备注可用稳定ID保存',()=>{
  const before=makePlan(16);const changed=makePlan(17);changed[0].route='changed';
  assert.deepEqual(makePlan(16),before);
  assert.ok(makePlan(15).every(day=>before.some(old=>old.id===day.id)));
});
test('续航计算包含备用SOC与额外缩减，拒绝无效输入',()=>{
  assert.equal(estimateRange(300,80,20,10),162);
  for(const args of [[300,20,80,10],[300,80,80,10],[NaN,80,20,10],[300,101,20,10],[300,80,20,100],[0,80,20,10]])assert.equal(estimateRange(...args),null);
});
test('夜耗计算保留负值以提示电量不足，不掩盖问题',()=>{
  assert.equal(estimateMorning(60,60,6),50);
  assert.equal(estimateMorning(60,10,12),-10);
  assert.equal(estimateMorning(60,60,0),60);
  for(const args of [[0,60,6],[60,101,6],[60,60,-1],[NaN,60,6]])assert.equal(estimateMorning(...args),null);
});
test('首页资源和原线上西藏页面均保留',()=>{
  for(const file of ['index.html','autumn/style.css','autumn/app.js','autumn/trip-data.js','autumn/energy.js','tibet/index.html','tibet/app.js','tibet/app.css','tibet/assets/generated/plateau.webp','tibet-source.html'])assert.ok(fs.existsSync(file),file);
});

test('地图覆盖全部行程版本，Day编号与稳定ID一致',()=>{
  for(const length of [15,16,17]){
    const plan=makePlan(length),days=mapDays(plan);
    assert.equal(days.length,length);
    assert.ok(days.every((day,i)=>day.number===i+1&&/^#[0-9a-f]{6}$/i.test(day.color)&&day.paths.length));
    assert.equal(selectedMapDays(plan,'return-1')[0].number,length-3);
    assert.equal(selectedMapDays(plan,'all').length,length);
    assert.equal(selectedMapDays(plan,'missing').length,0);
  }
  assert.deepEqual(mapDays(makePlan(16)).find(day=>day.id==='chaji-transfer').paths,[['shendu','chaji']]);
});

test('路线采用缓存公路几何，反向返程不改写原坐标',()=>{
  const data=JSON.parse(fs.readFileSync('autumn/map-data.json','utf8'));
  assert.equal(data.coordinateSystem,'WGS84');
  for(const length of [15,16,17])for(const day of mapDays(makePlan(length)))for(const path of day.paths){
    for(const id of path)assert.ok(data.points[id],id);
    for(let i=1;i<path.length;i++){
      const line=roadLeg(data,path[i-1],path[i]);
      assert.ok(line&&line.length>2,`${day.id}: ${path[i-1]}→${path[i]}`);
      assert.ok(line.every(p=>p.length===2&&p.every(Number.isFinite)&&p[0]>112&&p[0]<120&&p[1]>22&&p[1]<32));
    }
  }
  const original=structuredClone(data.routes['jiangmen|shaoguan'].coordinates);
  const reversed=roadLeg(data,'shaoguan','jiangmen');
  assert.deepEqual(reversed,[...original].reverse());
  reversed.push([0,0]);
  assert.deepEqual(data.routes['jiangmen|shaoguan'].coordinates,original);
  assert.equal(roadLeg(data,'jiangmen','chaji'),null);
  assert.ok(data.roads.some(road=>road.kind==='river'));
});
