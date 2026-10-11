// Concrete planned stops, not bookings or confirmed permission to sleep in a car.
export const nightPlaces = {
  shaoguanPark:{name:'韶州公园北广场东停车场',region:'广东省 · 韶关市 · 武江区',address:'朝阳路，韶州公园北广场游客服务中心旁',source:'https://www.sohu.com/a/541675932_100116740',sourceLabel:'武江公园交通介绍',note:'向管理方确认车内留宿、夜间出入及厕所开放。'},
  shaoguanHotel:{name:'维也纳国际酒店（韶关高铁站广场店）',region:'广东省 · 韶关市 · 武江区',address:'韶关大道南33号星汇商业广场1号综合楼',source:'https://m.ctrip.com/html5/hotel/hoteldetail/123094216.html',sourceLabel:'酒店名称与地址',note:'预订房间；向前台确认本车停车位置、限高与进出时间。'},
  taiheHotel:{name:'维也纳酒店（泰和高铁站店）',region:'江西省 · 吉安市 · 泰和县',address:'泰和大道与井冈山大道交叉路口',source:'https://hotels.ctrip.com/hotels/85300030.html',sourceLabel:'酒店名称与地址',note:'预订房间并确认停车；不把酒店停车场视为车宿点。'},
  taihePark:{name:'泰和站地下停车场',region:'江西省 · 吉安市 · 泰和县',address:'井冈山大道与吉泰大道交口，泰和站',source:'https://www.amap.com/place/B0L6KSOZJZ',sourceLabel:'高德停车场地点',note:'确认允许车内留宿、车高可通行及夜间出入；不使用落客区或大巴车位。'},
  fuliangPark:{name:'浮梁古县衙游客中心停车场',region:'江西省 · 景德镇市 · 浮梁县',address:'县衙路浮梁古县衙东南角，游客中心旁',source:'https://www.amap.com/place/B0HB6ZM33O',sourceLabel:'高德停车场地点',note:'县衙路有施工计划，先确认入口可通行，再确认留宿许可与厕所。'},
  fuliangHotel:{name:'汉庭酒店（景德镇江西陶瓷工业园区店）',region:'江西省 · 景德镇市 · 浮梁县',address:'唐英大道陶瓷工业园派出所北侧约140米',source:'https://m.ctrip.com/html5/hotel/hoteldetail/131945996.html',sourceLabel:'酒店名称与地址',note:'位于浮梁县陶瓷工业园区，非古县衙门口；改住这里后重算次日起点。'},
  yaoliPark:{name:'瑶里古镇停车场',region:'江西省 · 景德镇市 · 浮梁县 · 瑶里镇',address:'瑶里古镇，高德地点编号B0L6OM6IT3（未列门牌号）',source:'https://www.amap.com/place/B0L6OM6IT3',sourceLabel:'高德停车场地点',note:'确认允许车内留宿、夜间厕所与出入；在普通停车位休息，不占充电位。'},
  yaoliHotel:{name:'瑶里卧龙潭宾馆',region:'江西省 · 景德镇市 · 浮梁县 · 瑶里镇',address:'瑶里镇村北头',source:'https://hotels.ctrip.com/hotels/1971308.html',sourceLabel:'宾馆名称与地址',note:'宾馆客房住宿；向前台确认停车入口，不假定车能进入古镇巷道。'},
  qinghuaPark:{name:'彩虹桥景区停车场',region:'江西省 · 上饶市 · 婺源县 · 清华镇',address:'彩虹桥景区取票处门口',source:'https://you.ctrip.com/sight/wuyuan446/16728.html',sourceLabel:'景区停车设施资料',note:'确认夜间是否允许车内留宿、出入和厕所开放；不是县城的同名桥。'},
  qinghuaHotel:{name:'婺源清华园饭店',region:'江西省 · 上饶市 · 婺源县 · 清华镇',address:'清华供销社东南门西南50米，近东源路',source:'https://www.chinaholiday.com/cn/city_8315/328154.html',sourceLabel:'客房与停车资料',note:'按酒店客房安排；高德定位B03190QUG8。订房时确认仍正常营业、房间与停车入口。'},
  shenduPark:{name:'新安江山水画廊风景区停车场',region:'安徽省 · 黄山市 · 歙县 · 深渡镇',address:'深渡镇黄山大道，深渡码头景区停车场',source:'https://you.ctrip.com/sight/shecounty527/55544.html',sourceLabel:'景区停车设施资料',note:'确认车内留宿与夜间出入；不在码头作业区、滨水低洼地或路肩停宿。'},
  shexianHotel:{name:'汉庭酒店（黄山歙县徽州古城店）',region:'安徽省 · 黄山市 · 歙县 · 徽城镇',address:'S215黄山东路汇金大厦',source:'https://m.huazhu.com/Hotel/Detail/2452991',sourceLabel:'华住酒店门店资料',note:'在歙县县城，非深渡镇。若启用，白天转移并把往返驾驶计入5小时上限。'},
  chajiPark:{name:'查济古建筑群游客中心停车场',region:'安徽省 · 宣城市 · 泾县 · 桃花潭镇',address:'查济村查济古建筑群游客中心',source:'https://www.amap.com/place/B0FFL1INVR',sourceLabel:'高德停车场地点',note:'确认车内留宿、夜间厕所与出入；汽车留在景区外，不开进古村。'},
  chajiHotel:{name:'泾县查济宜鸿酒店',region:'安徽省 · 宣城市 · 泾县 · 桃花潭镇',address:'查济景区查济村长生巷12号',source:'https://us.trip.com/hotels/jing-county-hotel-detail-5912122/yihong-hotel/',sourceLabel:'酒店名称与门牌地址',note:'位于景区内，先确认入村票务。汽车按查济景区停车场安排，步行入住；不承诺酒店院内停车或充电。'},
  home:{name:'江门家中',region:'广东省 · 江门市',address:'回家住宿，不安排在外过夜',note:'到家后休息。'}
};

const assignments = {
  'out-1':['car','shaoguanPark','shaoguanHotel','首晚住车里，验证睡眠与整夜空调夜耗。'],
  'out-2':['hotel','taiheHotel',null,'酒店洗澡、补觉。'],
  'out-3':['car','fuliangPark','fuliangHotel','县城补电、补给后在这里车宿，今晚不进瑶里。'],
  yaoli:['car','yaoliPark','yaoliHotel','瑶里游览后车宿；不依赖临时插座补电。'],
  qinghua:['car','qinghuaPark','qinghuaHotel','菊径游览后抵达清华镇，在彩虹桥停车场车宿。'],
  north:['hotel','qinghuaHotel',null,'北线游览结束回清华镇，酒店洗澡、补觉。'],
  shendu:['car','shenduPark','shexianHotel','江边游览后住车里；白天确认未来两晚的留宿许可。'],
  yangchan:['car','shenduPark','shexianHotel','阳产下山后返回深渡同一停车场车宿，不住山上。'],
  'chaji-transfer':['car','chajiPark','chajiHotel','从深渡出发到查济，车停古村外围。'],
  chaji:['hotel','chajiHotel',null,'古村游览后住酒店，洗澡、补觉。'],
  taohuatan:['car','chajiPark','chajiHotel','桃花潭当天往返，晚上返回查济停车场车宿。'],
  buffer:['hotel','chajiHotel',null,'留在查济，返程前住酒店休息。机动日若挪动，住宿同步调整。'],
  extra:['car','chajiPark','chajiHotel','17天版默认继续在查济车宿；若把此日挪作途中缓冲，重新确定当晚停车点。'],
  'return-1':['car','fuliangPark','fuliangHotel','回程第一晚明确停浮梁，复用去程停车点。'],
  'return-2':['car','taihePark','taiheHotel','回程第二晚在泰和站停车场车宿。'],
  'return-3':['hotel','shaoguanHotel',null,'最后一个在外夜晚住酒店，次日返回江门。'],
  'return-4':['home','home',null,'当天回到江门，住家里。']
};

export function overnightFor(id){
  const assignment=assignments[id];
  if(!assignment) throw new Error(`Missing overnight plan: ${id}`);
  const [mode,placeId,fallbackId,reason]=assignment;
  return {mode,placeId,place:{...nightPlaces[placeId]},fallback:fallbackId?{...nightPlaces[fallbackId]}:null,reason,status:mode==='car'?'车内留宿许可待确认':mode==='hotel'?'拟入住 · 未预订':'回家'};
}

export const nightModeLabels={car:'住车里',hotel:'住酒店',home:'住家里'};
