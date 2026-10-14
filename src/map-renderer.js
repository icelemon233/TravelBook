import {roadNetwork} from './road-network.js';
import {mapLakeGeometry} from './map-geography.js';
import {scenarioData,revisedDates} from './scenarios.js';
// WGS84 place/lake reference coordinates from OpenStreetMap / Nominatim, 2026-09-20.
// Road geometry: OpenStreetMap / Overpass; routed polylines: OSRM driving.
const mapPlaces={
 '拉萨':[91.1173,29.6542], '羊卓雍措':[90.7486,28.9769], '卡若拉冰川':[90.1641,28.8992],
 '江孜':[89.6036,28.9157], '日喀则':[88.8807,29.2714], '拉孜':[87.6899,29.1588],
 '昂仁县':[87.2252,29.3021], '桑桑镇':[86.7239,29.4205], '达若':[86.9370,30.0715],
 '措迈':[86.9003,30.4357], '达果':[86.6721,30.7671], '萨嘎':[85.2311,29.3330],
 '措勤':[85.1579,31.0197], '扎日南木错':[85.6038,30.9076], '当惹雍措':[86.5760,31.0610],
 '文布南村':[86.7556,31.3425], '当穹措':[86.7517,31.5711], '尼玛':[87.2353,31.7869],
 '达则错':[87.5100,31.8983], '色林措':[89.0793,31.8400], '申扎':[88.7063,30.9292],
 '班戈':[90.0084,31.3977], '贡嘎机场':[90.9080,29.2963]
};
const mapAliases={'桑桑':'桑桑镇','日喀则扎什伦布寺':'日喀则','日喀则政务大厅':'日喀则'};
Object.assign(mapPlaces,roadNetwork.points);
const mapColors={'9/28':'#344d59','9/29':'#b84727','9/30':'#9b7114','10/1':'#18776f','10/2':'#5555a1','10/3':'#306a99','10/4':'#8b4466'};

export const mapTerrain=new Image();mapTerrain.src='assets/generated/route-terrain.png';

export function mapDayData(permitScenario,northernBranch,activePlan){
 const state=scenarioData(permitScenario,northernBranch);const overnight=activePlan==='A'?'申扎':'班戈';
 return [
  {date:'9/28',points:['拉萨'],note:'拉萨集合、办证与适应海拔'},
  ...revisedDates.map(date=>({date,points:state.days[date].points,note:state.days[date].note})),
  {date:'10/3',points:['尼玛','达则错','色林措',overnight],note:'途经天空之树；未取得独立点位，地图不单独落点。'},
  {date:'10/4',points:[overnight,'贡嘎机场'],note:'送机后入住机场附近酒店。'}
 ];
}
export function drawRouteMap(canvas,{permitScenario,northernBranch,activePlan,mapSelectedDay}){
 if(!canvas)return;
 const ctx=canvas.getContext('2d'),W=1200,H=840,scale=2;
 canvas.width=W*scale;canvas.height=H*scale;ctx.scale(scale,scale);
 const xy=([lon,lat])=>[65+(lon-84.6)/7.1*1070,65+(32.4-lat)/4.6*710];
 const label=(text,x,y,size=20,color='#172a36',align='left')=>{ctx.font=`600 ${size}px "Microsoft YaHei", sans-serif`;ctx.textAlign=align;ctx.lineWidth=5;ctx.lineJoin='round';ctx.strokeStyle='#f7f5ef';ctx.strokeText(text,x,y);ctx.fillStyle=color;ctx.fillText(text,x,y);};
 ctx.fillStyle='#f4f1e8';ctx.fillRect(0,0,W,H);
 if(mapTerrain.complete&&mapTerrain.naturalWidth){ctx.globalAlpha=.18;ctx.drawImage(mapTerrain,0,0,W,H);ctx.globalAlpha=1;}
 ctx.strokeStyle='#b7c1ba';ctx.lineWidth=.65;ctx.setLineDash([3,7]);
 for(let lon=85;lon<=91;lon++){const [x]=xy([lon,30]);ctx.beginPath();ctx.moveTo(x,40);ctx.lineTo(x,H-45);ctx.stroke();label(lon+'°E',x,H-85,13,'#64736c','center');}
 for(let lat=28;lat<=32;lat++){const [,y]=xy([86,lat]);ctx.beginPath();ctx.moveTo(35,y);ctx.lineTo(W-35,y);ctx.stroke();label(lat+'°N',14,y-9,13,'#64736c');}
 ctx.setLineDash([]);
 for(const lake of mapLakeGeometry){
  const polygons=lake.type==='Polygon'?[lake.coordinates]:lake.coordinates;
  for(const rings of polygons){ctx.beginPath();for(const ring of rings){ring.forEach((point,i)=>{const p=xy(point);i?ctx.lineTo(...p):ctx.moveTo(...p)});ctx.closePath();}ctx.fillStyle='#a0c5c8';ctx.strokeStyle='#6a9fa7';ctx.lineWidth=1;ctx.fill('evenodd');ctx.stroke();}
 }
 const path=coordinates=>{ctx.beginPath();coordinates.forEach((p,i)=>i?ctx.lineTo(...xy(p)):ctx.moveTo(...xy(p)));};
 ctx.save();ctx.beginPath();ctx.rect(35,80,1130,673);ctx.clip();
 // Draw roads even when a date filter hides the corresponding itinerary legs.
 ctx.lineJoin='round';ctx.lineCap='round';
 for(const road of roadNetwork.roads){path(road.coordinates);ctx.lineWidth=road.ref.startsWith('G42')?1.6:1;ctx.strokeStyle=road.ref.startsWith('G42')?'#a5aea7':'#b8bcb2';ctx.stroke();}
 // Include rural connectors used by routed legs but absent from the major-road layer.
 for(const road of Object.values(roadNetwork.routes)){path(road.coordinates);ctx.lineWidth=.7;ctx.strokeStyle='#b8bcb2';ctx.stroke();}
 ctx.restore();
 const shields=[['G216',85.25,30.05],['G219',85.5,29.35],['G318',88.2,29.12],['G349',88.25,29.43],['G349',89.65,28.86],['S209',86.94,30.28],['G317',88.30,31.70],['G317',89.60,31.45],['G562',88.95,30.2],['G4218',90.0,29.35],['G109',91.03,30.2]];
 for(const [ref,lon,lat] of shields){let best=null,dist=Infinity;for(const r of roadNetwork.roads.filter(r=>r.ref===ref)){for(const p of r.coordinates){const d=Math.hypot((p[0]-lon)*.86,p[1]-lat);if(d<dist){best=p;dist=d;}}}if(!best||dist>.4)continue;const [x,y]=xy(best);ctx.fillStyle='#fcfcf7';ctx.strokeStyle='#a7b4ae';ctx.lineWidth=1;const w=ref.length*8+12;ctx.fillRect(x-w/2,y-28,w,20);ctx.strokeRect(x-w/2,y-28,w,20);label(ref,x,y-14,12,'#60736b','center');}
 label('纳木错',...xy([90.59,30.75]),18,'#4c818d');
 label('藏北湖区',655,94,27,'#728582');label('阿里 · 措勤',110,212,22,'#728582');
 label('日喀则方向',387,626,22,'#728582');label('北 N',1110,61,18,'#344d59','center');
 const state=scenarioData(permitScenario,northernBranch),days=mapDayData(permitScenario,northernBranch,activePlan),selected=days.filter(d=>mapSelectedDay==='全部'||d.date===mapSelectedDay);
 const canonical=p=>mapAliases[p]||p;const visible=new Set(),gaps=[];
 for(const day of selected){
  // Pending Plan C has no continuous confirmed itinerary after 9/29.
  if(state.pending&&day.date!=='9/28'&&day.date!=='9/29')continue;
  const names=day.points.map(canonical);names.filter(p=>mapPlaces[p]).forEach(p=>visible.add(p));
  const color=mapColors[day.date];
  for(let i=1;i<names.length;i++){
   const route=roadNetwork.routes[names[i-1]+'|'+names[i]];
   if(!route){gaps.push(day.date+' '+names[i-1]+' → '+names[i]);continue;}
   const points=route.coordinates.map(xy);
   path(route.coordinates);ctx.lineWidth=6;ctx.strokeStyle='#faf8f1';ctx.stroke();
   ctx.lineWidth=3;ctx.strokeStyle=color;ctx.stroke();
   const lengths=points.slice(1).map((p,i)=>Math.hypot(p[0]-points[i][0],p[1]-points[i][1]));const total=lengths.reduce((a,b)=>a+b,0);let walked=0,index=0;while(index<lengths.length-1&&walked+lengths[index]<total*.55){walked+=lengths[index++];}
   const a=points[index],b=points[index+1];if(!b||total<12)continue;
   const angle=Math.atan2(b[1]-a[1],b[0]-a[0]);const t=(total*.55-walked)/(lengths[index]||1),x=a[0]+(b[0]-a[0])*t,y=a[1]+(b[1]-a[1])*t;
   ctx.save();ctx.translate(x,y);ctx.rotate(angle);ctx.beginPath();ctx.moveTo(7,0);ctx.lineTo(-5,-5);ctx.lineTo(-5,5);ctx.closePath();ctx.fillStyle=color;ctx.fill();ctx.restore();
  }
 }
 // Label placement separates the dense lake district and the three southern stops.
 const offsets={ '拉萨':[15,-14], '贡嘎机场':[17,24], '羊卓雍措':[15,35], '卡若拉冰川':[-8,66], '江孜':[-54,31],
 '日喀则':[14,-14], '拉孜':[0,38], '昂仁县':[-9,33], '桑桑镇':[-93,-5], '达若':[17,7], '措迈':[17,6],
 '达果':[20,16], '措勤':[-66,-17], '扎日南木错':[-100,44], '当惹雍措':[-112,-14],
 '文布南村':[-105,0], '当穹措':[-91,-2], '尼玛':[-67,-8], '达则错':[8,-23], '色林措':[13,-13],
 '申扎':[15,17], '班戈':[15,-13], '萨嘎':[-58,29] };
 for(const name of visible){const [x,y]=xy(mapPlaces[name]);ctx.beginPath();ctx.arc(x,y,5.5,0,Math.PI*2);ctx.fillStyle='#172a36';ctx.fill();ctx.lineWidth=2;ctx.strokeStyle='#fff';ctx.stroke();const [dx,dy]=offsets[name]||[12,-12];if(Math.abs(dy)>35){ctx.beginPath();ctx.moveTo(x,y+8);ctx.lineTo(x+dx,y+dy-22);ctx.strokeStyle='#566a6b';ctx.lineWidth=1;ctx.stroke();}label(name,x+dx,y+dy);}
 if((permitScenario==='A'||permitScenario==='C-ok')&&(mapSelectedDay==='全部'||mapSelectedDay==='9/30')){
  label('9/30 经珠峰方向、G219 南线',391,705,21,'#8a6210');
  label('具体停靠点未指定，此段暂不连线',391,737,17,'#52626a');
 }
 if(state.pending){label('9/30 起：等待办证结果后选择 A 或 B',130,375,26);}
 label('西藏 · 沿公路看全程',69,34,19);label('灰线：主要公路 · 彩线：道路规划 · 非实时导航',1165,812,14,'#52626a','right');
 const title=state.name+(state.north?' / B-'+northernBranch:'')+' · 10/3 住'+(activePlan==='A'?'申扎':'班戈');
 label(title+' · '+(mapSelectedDay==='全部'?'全程':mapSelectedDay),69,60,15,'#52626a');
 days.forEach((day,i)=>{const x=90+i*155;ctx.beginPath();ctx.moveTo(x,774);ctx.lineTo(x+24,774);ctx.lineWidth=4;ctx.strokeStyle=mapColors[day.date];ctx.stroke();label(day.date,x+34,781,17,mapColors[day.date]);});
 label('© OpenStreetMap contributors / ODbL · AI 山纹装饰',69,812,13,'#52626a');

 canvas.dataset.missingLegs=String(gaps.length);
 canvas.setAttribute('aria-label',title+'。'+selected.map(d=>d.date+'：'+d.points.join(' → ')).join('；'));
}
