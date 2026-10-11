import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {makePlan} from '../autumn/trip-data.js';
import {estimateRange,estimateMorning} from '../autumn/energy.js';
import {mapDays,roadLeg,selectedMapDays} from '../autumn/map-model.js';

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
