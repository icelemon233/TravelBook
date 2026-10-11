const yaoliSource='https://fuliang.gov.cn/zjfl/flly/jqls/t1092389.shtml';
const wuyuanSource='https://discoverwuyuan.com/zh/all-attractions/';
export const attractionGroups=[
  {id:'yaoli',title:'瑶里',region:'江西省 · 景德镇市 · 浮梁县',photo:'yaoli',caption:'瑶里山村景观（区域参考图）',spots:[
    {id:'yaoli-town',name:'瑶里古镇 · 瑶河两岸',dayIds:['yaoli'],type:'主要游览',text:'沿瑶河步行，游览两岸古民居与街巷。当天先逛古镇，再按时间安排周边。',source:yaoliSource},
    {id:'raonan',name:'绕南古窑 · 瓷之源',dayIds:['yaoli'],type:'可选',text:'了解瑶里陶瓷文化与古窑遗存。与古镇分开安排交通；时间或体力不足时取消。',source:yaoliSource}
  ]},
  {id:'wuyuan',title:'婺源北线',region:'江西省 · 上饶市 · 婺源县',photo:'caihong',caption:'清华镇彩虹桥；本图对应彩虹桥',spots:[
    {id:'jujing',name:'菊径村',dayIds:['qinghua'],type:'沿途短停',text:'看溪流环绕的村落格局。停车后步行观景，确认观景位置与通行条件。',source:wuyuanSource},
    {id:'qinghua-town',name:'清华镇 · 老街',dayIds:['qinghua','north'],type:'主要游览',text:'游览老街与河边，作为北线两晚的落脚片区；停车与酒店提前落实。',source:'https://discoverwuyuan.com/zh/rainbow-bridge/'},
    {id:'caihong',name:'彩虹桥',dayIds:['qinghua','north'],type:'周边可选',text:'看廊桥与水岸景观，可与清华老街组合。进桥、票务与开放情况出发前查询。',source:'https://discoverwuyuan.com/zh/rainbow-bridge/'},
    {id:'zhangcun',name:'漳村 · 板凳桥',dayIds:['north'],type:'二选一',text:'以河岸与板凳桥为游览重点。桥体受水位和维护影响，出发前确认现状；与虹关择一。',source:wuyuanSource},
    {id:'hongguan',name:'虹关村 · 古樟',dayIds:['north'],type:'二选一',text:'看村口古樟、溪流和古民居。先核算清华往返车程，与漳村择一，不默认两处顺路。',source:'https://www.jianzhuyichan.com/Pages/ProjectDetails.aspx?id=397'}
  ]},
  {id:'shendu',title:'深渡与新安江',region:'安徽省 · 黄山市 · 歙县',photo:'shendu',caption:'深渡镇码头',spots:[
    {id:'shendu-river',name:'深渡镇 · 新安江江边',dayIds:['shendu'],type:'主要游览',text:'抵达后沿江散步、看码头和江景。默认安排岸上游览；游船需另查班次、票务和耗时。',source:'https://www.huangshan.gov.cn/zxzx/qxdt/8412572.html'}
  ]},
  {id:'yangchan',title:'阳产土楼',region:'安徽省 · 黄山市 · 歙县',photo:'yangchan',caption:'阳产土楼',spots:[
    {id:'yangchan-village',name:'阳产土楼',dayIds:['yangchan'],type:'主要游览',text:'游览山村土楼、坡地街巷，天气与季节合适时看晒秋。白天上山、山下过夜；日落是否停留按下山接驳决定。',source:'https://www.huangshan.gov.cn/zxzx/qxdt/8393315.html'}
  ]},
  {id:'chaji',title:'查济古村',region:'安徽省 · 宣城市 · 泾县',photo:'chaji',caption:'查济古村',spots:[
    {id:'chaji-village',name:'查济古村 · 三溪、古桥与祠堂',dayIds:['chaji-transfer','chaji'],type:'主要游览',text:'抵达当天下午短逛，次日步行游览溪流、古桥与祠堂。景区开放范围和古建能否入内，以当天公布为准。',source:'https://www.xuancheng.gov.cn/News/show/625442.html'}
  ]},
  {id:'taohuatan',title:'桃花潭',region:'安徽省 · 宣城市 · 泾县',photo:'taohuatan',caption:'桃花潭',spots:[
    {id:'taohuatan-scenic',name:'桃花潭景区',dayIds:['taohuatan'],type:'可选',text:'以潭水、古渡和踏歌岸阁一带为游览重点。作为查济周边短途；15天版不安排，疲劳或天气不好时取消。',source:'https://www.xuancheng.gov.cn/News/show/625444.html'}
  ]},
  {id:'huizhou',title:'徽州古城',region:'安徽省 · 黄山市 · 歙县',photo:null,caption:'',spots:[
    {id:'huizhou-city',name:'徽州古城',dayIds:[],type:'原攻略备选',text:'仅在歙县落脚且时间充足时考虑老城街巷游览。未排入默认日程，不挤占山区转场和休息时间；具体古建开放及票务另查。',source:'https://www.huangshan.gov.cn/zxzx/qxdt/8406710.html'}
  ]}
];

export function attractionDays(spot,plan){return plan.flatMap((day,index)=>spot.dayIds.includes(day.id)?[{id:day.id,number:index+1}]:[]);}
