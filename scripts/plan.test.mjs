import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {makePlan} from '../autumn/trip-data.js';
import {estimateRange,estimateMorning} from '../autumn/energy.js';

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
