// Administrative context shared by daily cards, map captions and destination searches.
export const places = {
  jiangmen:{name:'江门市',region:'广东省江门市'},
  shaoguan:{name:'韶关市',region:'广东省韶关市'},
  taihe:{name:'泰和县',region:'江西省吉安市泰和县'},
  fuliang:{name:'浮梁县',region:'江西省景德镇市浮梁县'},
  yaoli:{name:'瑶里古镇',region:'江西省景德镇市浮梁县'},
  jujing:{name:'菊径村',region:'江西省上饶市婺源县'},
  qinghua:{name:'清华镇',region:'江西省上饶市婺源县'},
  hongguan:{name:'虹关村',region:'江西省上饶市婺源县'},
  zhangcun:{name:'漳村',region:'江西省上饶市婺源县'},
  shendu:{name:'深渡镇',region:'安徽省黄山市歙县'},
  yangchan:{name:'阳产土楼',region:'安徽省黄山市歙县'},
  chaji:{name:'查济古村',region:'安徽省宣城市泾县'},
  taohuatan:{name:'桃花潭',region:'安徽省宣城市泾县'},
  jingdezhen:{name:'景德镇市',region:'江西省景德镇市'},
  shexian:{name:'歙县',region:'安徽省黄山市歙县'}
};
const dayPlaces = {
  'out-1':['jiangmen','shaoguan'],'out-2':['shaoguan','taihe'],'out-3':['taihe','fuliang'],
  yaoli:['fuliang','yaoli'],qinghua:['yaoli','jujing','qinghua'],north:['qinghua','zhangcun','hongguan'],
  shendu:['qinghua','shendu'],yangchan:['shendu','yangchan'],'chaji-transfer':['yangchan','chaji'],
  chaji:['chaji'],taohuatan:['chaji','taohuatan'],buffer:['chaji'],extra:['chaji'],
  'return-1':['chaji','fuliang'],'return-2':['fuliang','taihe'],
  'return-3':['taihe','shaoguan'],'return-4':['shaoguan','jiangmen']
};
export function dayRegions(id){return [...new Set(dayPlaces[id].map(key=>places[key].region))].join(' → ');}
export function fullPlace(key){const place=places[key];return place.region.endsWith(place.name)?place.region:place.region+place.name;}
export function qualifyPlace(name){
  const aliases={'婺源县清华镇':'qinghua','阳产土楼游客中心':'yangchan','桃花潭风景区':'taohuatan'};
  const key=aliases[name]||Object.keys(places).find(key=>places[key].name===name);
  if(!key)return name;
  return aliases[name]&&name!=='婺源县清华镇'?places[key].region+name:fullPlace(key);
}
