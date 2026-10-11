import {mapDays,roadLeg,selectedMapDays} from './map-model.js';
import {places} from './places.js';

const WIDTH=1200, HEIGHT=974;
const INK='#273b30', MUTED='#667164', PAPER='#f7f4eb';
const panels=[
  {x:30,y:172,w:350,h:590,bounds:[112.5,22.15,119.1,31.0],title:'全程 · 江门往返',step:2,
    labels:['jiangmen','shaoguan','taihe','fuliang','chaji','jingdezhen'],
    offsets:{jiangmen:[14,20],shaoguan:[14,5],taihe:[14,5],fuliang:[-20,-12],jingdezhen:[-20,24],chaji:[-18,-12]}},
  {x:410,y:172,w:760,h:590,bounds:[117.0,29.14,118.9,30.73],title:'游玩区域 · 赣东北与皖南',step:.5,
    labels:['fuliang','jingdezhen','yaoli','jujing','qinghua','hongguan','zhangcun','shendu','yangchan','chaji','taohuatan','shexian'],
    offsets:{fuliang:[-18,-12],jingdezhen:[-13,28],yaoli:[-15,-17],jujing:[-45,5],qinghua:[-55,26],hongguan:[8,-17],zhangcun:[14,28],
      shendu:[-38,32],yangchan:[20,-17],chaji:[-65,-12],taohuatan:[12,22],shexian:[-18,-15]}}
];
const mercator=lat=>Math.log(Math.tan(Math.PI/4+lat*Math.PI/360));
function projection(panel){
  const [west,south,east,north]=panel.bounds;
  const left=west*Math.PI/180,right=east*Math.PI/180,top=mercator(north),bottom=mercator(south);
  const scale=Math.min((panel.w-48)/(right-left),(panel.h-44)/(top-bottom));
  const ox=panel.x+(panel.w-(right-left)*scale)/2,oy=panel.y+(panel.h-(top-bottom)*scale)/2;
  return ([lon,lat])=>[ox+(lon*Math.PI/180-left)*scale,oy+(top-mercator(lat))*scale];
}
function inPanel(point,panel){const [x,y]=point,[w,s,e,n]=panel.bounds;return x>=w&&x<=e&&y>=s&&y<=n;}
function intersects(line,panel){
  const [w,s,e,n]=panel.bounds;
  let minX=Infinity,minY=Infinity,maxX=-Infinity,maxY=-Infinity;
  for(const [x,y] of line){minX=Math.min(minX,x);maxX=Math.max(maxX,x);minY=Math.min(minY,y);maxY=Math.max(maxY,y);}
  return maxX>=w&&minX<=e&&maxY>=s&&minY<=n;
}
function text(ctx,label,x,y,size=18,color=INK,align='left'){
  ctx.font=`600 ${size}px "Microsoft YaHei",system-ui,sans-serif`;ctx.textAlign=align;
  ctx.lineJoin='round';ctx.lineWidth=5;ctx.strokeStyle=PAPER;ctx.strokeText(label,x,y);ctx.fillStyle=color;ctx.fillText(label,x,y);
}
function stroke(ctx,line,project,color,width,dash=[]){
  ctx.beginPath();line.forEach((p,i)=>{const [x,y]=project(p);i?ctx.lineTo(x,y):ctx.moveTo(x,y);});
  ctx.strokeStyle=color;ctx.lineWidth=width;ctx.setLineDash(dash);ctx.stroke();ctx.setLineDash([]);
}
function arrow(ctx,line,project,color,fraction){
  const pts=line.map(project),lengths=pts.slice(1).map((p,i)=>Math.hypot(p[0]-pts[i][0],p[1]-pts[i][1]));
  const total=lengths.reduce((a,b)=>a+b,0);if(total<28)return;
  let target=total*fraction,index=0;
  while(index<lengths.length-1&&target>lengths[index])target-=lengths[index++];
  const a=pts[index],b=pts[index+1],ratio=target/(lengths[index]||1),angle=Math.atan2(b[1]-a[1],b[0]-a[0]);
  ctx.save();ctx.translate(a[0]+(b[0]-a[0])*ratio,a[1]+(b[1]-a[1])*ratio);ctx.rotate(angle);
  ctx.beginPath();ctx.moveTo(8,0);ctx.lineTo(-6,-5);ctx.lineTo(-6,5);ctx.closePath();ctx.fillStyle=color;ctx.fill();ctx.restore();
}

export function drawRouteMap(canvas,data,plan,selected='all'){
  const ctx=canvas.getContext('2d');canvas.width=WIDTH*2;canvas.height=HEIGHT*2;ctx.scale(2,2);
  ctx.fillStyle=PAPER;ctx.fillRect(0,0,WIDTH,HEIGHT);
  const days=mapDays(plan),shown=selectedMapDays(plan,selected),active=shown[0];
  text(ctx,'赣皖自驾 · 公路路线图',32,42,25);
  text(ctx,`${plan.length}天方案 · ${selected==='all'?'全部行程':`Day ${active.number} · ${active.route}`}`,32,74,16,MUTED);
  text(ctx,'广东省：江门市、韶关市    江西省：吉安市（泰和县）、景德镇市（浮梁县／瑶里）',32,100,13,MUTED);
  text(ctx,'江西省：上饶市婺源县（菊径／清华／虹关／漳村）    安徽省：黄山市歙县（深渡／阳产）、宣城市泾县（查济／桃花潭）',32,122,13,MUTED);
  text(ctx,'北 N ↑',1168,42,17,INK,'right');
  for(const panel of panels){
    const project=projection(panel);
    text(ctx,panel.title,panel.x+2,panel.y-14,17);
    ctx.save();ctx.beginPath();ctx.rect(panel.x,panel.y,panel.w,panel.h);ctx.clip();
    ctx.fillStyle='#f0f0e4';ctx.fillRect(panel.x,panel.y,panel.w,panel.h);
    const [west,south,east,north]=panel.bounds;
    for(let lon=Math.ceil(west/panel.step)*panel.step;lon<=east;lon+=panel.step){
      stroke(ctx,[[lon,south],[lon,north]],project,'#cbd0be',.7,[3,6]);
      const [x]=project([lon,north]);text(ctx,`${lon}°E`,x,panel.y+panel.h-8,10,MUTED,'center');
    }
    for(let lat=Math.ceil(south/panel.step)*panel.step;lat<=north;lat+=panel.step){
      stroke(ctx,[[west,lat],[east,lat]],project,'#cbd0be',.7,[3,6]);
      const [,y]=project([west,lat]);text(ctx,`${lat}°N`,panel.x+5,y-5,10,MUTED);
    }
    ctx.lineJoin='round';ctx.lineCap='round';
    for(const road of data.roads){
      if(!intersects(road.coordinates,panel))continue;
      const river=road.kind==='river',major=['motorway','trunk'].includes(road.kind);
      stroke(ctx,road.coordinates,project,river?'#9dbfc0':major?'#b6bdaf':'#ced0c0',river?2:major?1.1:.7);
    }
    // Keep inactive routes as pale context; active return dashes expose overlapping outbound colours.
    for(const day of days){
      const highlighted=selected==='all'||selected===day.id;
      for(let branch=0;branch<day.paths.length;branch++){
        const path=day.paths[branch];
        for(let i=1;i<path.length;i++){
          const line=roadLeg(data,path[i-1],path[i]);if(!line||!intersects(line,panel))continue;
          const returning=day.phase==='返程',optional=day.id==='north'&&branch===1;
          if(highlighted&&!returning)stroke(ctx,line,project,PAPER,7);
          stroke(ctx,line,project,highlighted?day.color:'#c0c5b7',highlighted?returning?3:3.6:1.4,returning?[7,6]:optional?[3,5]:[]);
          if(highlighted)arrow(ctx,line,project,day.color,i===1?.42:.68);
        }
      }
    }
    const activePoints=new Set(shown.flatMap(day=>day.paths.flat()));
    for(const id of panel.labels){
      const point=data.points[id];if(!inPanel(point.coordinates,panel))continue;
      const [x,y]=project(point.coordinates),highlighted=activePoints.has(id);
      const stationary=selected!=='all'&&shown.some(day=>day.paths.some(path=>path.length===1&&path[0]===id));
      if(stationary){ctx.beginPath();ctx.arc(x,y,15,0,Math.PI*2);ctx.fillStyle=active.color+'30';ctx.fill();ctx.strokeStyle=active.color;ctx.lineWidth=2;ctx.stroke();}
      ctx.beginPath();ctx.arc(x,y,highlighted?5.5:3.5,0,Math.PI*2);ctx.fillStyle=highlighted?INK:'#929e8d';ctx.fill();ctx.strokeStyle=PAPER;ctx.lineWidth=2;ctx.stroke();
      const [dx,dy]=panel.offsets[id]||[12,-12],align=dx<0?'right':'left';
      if(Math.abs(dx)+Math.abs(dy)>45){ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(x+dx+(dx<0?6:-6),y+dy-6);ctx.strokeStyle='#8b9786';ctx.lineWidth=.7;ctx.stroke();}
      text(ctx,point.name,x+dx,y+dy,panel.w>400?18:15,highlighted?INK:'#76836e',align);
    }
    ctx.restore();ctx.strokeStyle='#c8cfbc';ctx.lineWidth=1;ctx.strokeRect(panel.x,panel.y,panel.w,panel.h);
  }
  text(ctx,'实线：去程与游玩   虚线：返程／可选支线   圆环：原地休整',32,793,14,MUTED);
  days.forEach((day,index)=>{
    const x=32+(index%4)*291,y=829+Math.floor(index/4)*25;
    ctx.globalAlpha=selected==='all'||selected===day.id?1:.4;
    ctx.beginPath();ctx.moveTo(x,y-5);ctx.lineTo(x+21,y-5);ctx.lineWidth=3;ctx.strokeStyle=day.color;ctx.setLineDash(day.phase==='返程'?[5,3]:[]);ctx.stroke();ctx.setLineDash([]);
    const short=day.id==='north'?'婺源北线（二选一）':day.id==='yangchan'?'阳产游览 · 下山过夜':day.id==='chaji-transfer'?'深渡片区 → 查济':day.route.replace(/片区/g,'').replace(/（.*?）/g,'');
    text(ctx,`D${day.number} ${short}`,x+30,y,12,day.color);ctx.globalAlpha=1;
  });
  text(ctx,'© OpenStreetMap contributors / ODbL · OSRM道路参考规划 · WGS84 · 2026-10-11',32,958,12,MUTED);
  text(ctx,'参考路线，非实时导航',1168,958,12,MUTED,'right');
  canvas.setAttribute('aria-label',`${plan.length}天赣皖公路路线图。${shown.map(day=>`Day${day.number}：${day.route}`).join('；')}。左侧全程，右侧游玩区域；地点为区域参考点。`);
}

export function mountRouteMap(){
  const canvas=document.getElementById('route-map-canvas'),filters=document.getElementById('map-days');
  const status=document.getElementById('map-status'),viewport=document.getElementById('map-viewport');
  const zoom=document.getElementById('map-zoom'),download=document.getElementById('map-save');
  let plan=[],selected='all',data=null,loading=false;
  function paint(){
    if(!data||!plan.length)return;
    drawRouteMap(canvas,data,plan,selected);canvas.hidden=false;zoom.disabled=false;download.disabled=false;
    const shown=selectedMapDays(plan,selected);
    status.textContent=selected==='all'?`${plan.length}天方案 · 全部行程`:`Day ${shown[0].number} · ${shown[0].route}`;
    document.getElementById('map-day-summary').textContent=selected==='all'?'选择Day查看当天路线；去程、游玩和返程按天分色。':
      `${shown[0].geography}。${shown[0].focus}。${shown[0].id==='north'?'虹关与漳村为二选一，图中分别标出支线。':shown[0].id==='yangchan'?'阳产标记为村落位置，上山需另行确认山下停车与接驳。':shown[0].id==='chaji-transfer'?'按前晚下山过夜，从深渡片区出发；实际起点以住宿位置为准。':shown[0].paths[0].length===1?'当天原地停留，不绘制新增驾驶路线。':''}`;
    filters.querySelectorAll('button').forEach(button=>button.setAttribute('aria-pressed',String(button.dataset.mapDay===selected)));
  }
  async function load(){
    if(loading)return;loading=true;status.textContent='正在加载路线图…';document.getElementById('map-retry').hidden=true;
    try{const response=await fetch(new URL('./map-data.json',import.meta.url));if(!response.ok)throw new Error('Map data unavailable');data=await response.json();paint();}
    catch{status.textContent='路线图未能加载，请重试。每日行程仍可查看。';document.getElementById('map-retry').hidden=false;}
    finally{loading=false;}
  }
  filters.addEventListener('click',event=>{const button=event.target.closest('[data-map-day]');if(!button)return;selected=button.dataset.mapDay;paint();});
  zoom.addEventListener('click',()=>{const expanded=viewport.classList.toggle('expanded');zoom.textContent=expanded?'缩回全图':'放大查看';zoom.setAttribute('aria-pressed',String(expanded));});
  download.addEventListener('click',()=>{
    const filename=`赣皖${plan.length}天路线图-${selected==='all'?'全程':`Day${mapDays(plan).find(day=>day.id===selected).number}`}.png`;
    download.disabled=true;
    canvas.toBlob(blob=>{download.disabled=false;if(!blob){status.textContent='图片生成失败，请重试。';return;}
      const url=URL.createObjectURL(blob),link=document.createElement('a');link.href=url;link.download=filename;link.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
    },'image/png');
  });
  document.getElementById('map-retry').addEventListener('click',load);
  const directory=document.getElementById('place-directory');
  for(const place of Object.values(places)){
    const item=document.createElement('div'),name=document.createElement('dt'),region=document.createElement('dd');
    name.textContent=place.name;region.textContent=place.region;item.append(name,region);directory.append(item);
  }
  load();
  return {update(next){
    plan=next;if(selected!=='all'&&!plan.some(day=>day.id===selected))selected='all';
    const days=mapDays(plan);filters.replaceChildren();
    for(const [id,label] of [['all','全部行程'],...days.map(day=>[day.id,`Day ${day.number}`])]){
      const button=document.createElement('button');button.type='button';button.dataset.mapDay=id;button.textContent=label;button.setAttribute('aria-pressed',String(id===selected));
      if(id!=='all'){const day=days.find(day=>day.id===id);button.style.setProperty('--day-color',day.color);button.title=day.route;}
      filters.append(button);
    }
    paint();
  }};
}
