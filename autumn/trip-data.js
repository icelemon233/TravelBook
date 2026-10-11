import {dayRegions,qualifyPlace} from './places.js';
import {overnightFor,nightModeLabels} from './nights-data.js';
export const days = [
  {id:'out-1',phase:'去程',route:'江门 → 韶关',road:'高速优先',drive:'以4–5小时为上限',focus:'只赶路，不安排景点',detail:'默认落脚韶州公园北广场东停车场。出发前用具体停车点核算导航；超过5小时就提前落脚并同步调整住宿，不往山区赶。',charge:'出发前补电；途中按150–180km规划补能窗口，每次选主站与备用站。',from:'江门市',to:'韶关市'},
  {id:'out-2',phase:'去程',route:'韶关 → 泰和',road:'高速优先',drive:'以4–5小时为上限',focus:'继续北上，午间充分休息',detail:'默认住泰和高铁站维也纳酒店，出发前从实际停车点导航至酒店。超过5小时则拆段并同步调整住宿。酒店停车条件与是否能充电分别确认，不以“有停车场”推断有充电桩。',charge:'高速服务区可补能；下高速后的县城站作兜底。抵达时要留出寻找备用站的电量。',from:'韶关市',to:'泰和县'},
  {id:'out-3',phase:'去程',route:'泰和 → 浮梁县城',road:'高速优先',drive:'以4–5小时为上限',focus:'抵达区域门户，今天不进瑶里',detail:'江门至浮梁分3天行驶。若前两天中继提前，今天仍遵守5小时上限；必要时启用第17天缓冲，不夜赶进山。',charge:'在浮梁选择已确认可用的直流站补足次日游览、夜间空调和备用电量。无须机械追求100%。',from:'泰和县',to:'浮梁县'},
  {id:'yaoli',phase:'游玩',route:'浮梁 → 瑶里',road:'白天走国省道',drive:'短转场；当天导航核算',focus:'瑶河两岸游览，绕南古窑按体力选',detail:'按浮梁住宿点至瑶里景区停车点导航核算车程。当天以瑶里古镇为主，周边景点按时间选择。',charge:'镇内场站状态待确认；酒店或停车点充电需核对类型、功率、开放时段和停车限制。',from:'浮梁县',to:'瑶里古镇'},
  {id:'qinghua',phase:'游玩',route:'瑶里 → 菊径 → 清华镇',road:'景观段走国省道',drive:'转场＋停留；路线待导航核验',focus:'菊径短停，下午抵达清华',detail:'途经菊径前往清华，按道路施工、天气和导航选择路线。优先沿途补能；仅在附近没有可靠站时考虑婺源县城。',charge:'出发前检查清华及沿途主站与备用站；核实充电类型、开放时间与可用状态。',from:'瑶里古镇',to:'婺源县清华镇',via:'菊径村'},
  {id:'north',phase:'游玩',route:'婺源北线，清华为基地',road:'乡道按路况选择',drive:'短途，保留半天休息',focus:'默认游览虹关，漳村为替换选项',detail:'北线不是一个紧凑景区。默认前往虹关后返回清华镇酒店，漳村仅作为替换选项；阴雨或疲劳就只逛清华、彩虹桥周边。',charge:'若车宿两晚，先检查空调实际耗电，再决定是否需要补能。',from:'婺源县清华镇',to:'虹关村'},
  {id:'shendu',phase:'游玩',route:'清华 → 深渡',road:'国省道优先；高速为备选',drive:'按一次山区转场安排',focus:'今天只转场＋江边散步',detail:'当天按山区转场安排，车程以实际起终点导航为准。到深渡超过5小时则在歙县落脚，次日再前往江边游览。',charge:'政府确认深渡新增充电桩，但快慢充与可用状态待核实。歙县为备用补能区，不是必须绕行点。',from:'婺源县清华镇',to:'深渡镇'},
  {id:'yangchan',phase:'游玩',route:'深渡 → 阳产 → 深渡',road:'停车换乘，按当日管制',drive:'短转场＋换乘',focus:'阳产土楼、晒秋；日落按末班车决定',detail:'不住民宿，因此不安排山上农家乐。先确认下山末班与步行条件，再决定是否等日落；不强求日出或云海，换乘价格现场核实。',charge:'汽车在山下就只能在山下安排补能，山上住宿不等于车辆可以慢充。',from:'深渡镇',to:'阳产土楼游客中心'},
  {id:'chaji-transfer',phase:'游玩',route:'深渡 → 查济',road:'国省道转场；必要时改高速',drive:'以5小时为上限',focus:'路上少停，抵达后只短逛',detail:'当天按完整转场日安排，提前核对实际车程。国省道车程过长或路况不佳时选择高速，途中减少停留。',charge:'查济充电设施有建设信息，不能据此确认已运营。出发前查主站和备用站，尽量沿行进方向补电。',from:'深渡镇',to:'查济古村'},
  {id:'chaji',phase:'游玩',route:'查济古村游览',road:'停车步行',drive:'尽量不挪车',focus:'清晨古桥、三溪与祠堂',detail:'当天以古村步行为主，游览古桥、溪流沿线和祠堂。进村票务、开放范围与车位以当日公布为准，不把景区内住宿等同于可开车进村。',charge:'用实际SOC和昨夜空调耗电决定补能，不为了“充满”专程远跑泾县。',from:'查济古村',to:'查济古村'},
  {id:'taohuatan',phase:'游玩',route:'查济周边／桃花潭，可选',road:'短途国省道',drive:'短途往返，导航后再决定',focus:'天气好出门，疲劳就取消',detail:'这是15天版优先删除的一天。桃花潭不是必打卡；来回驾驶、门票与停车符合当日状态才去。',charge:'按下一天安排补电，至少留出夜间空调与备用站所需电量。',from:'查济古村',to:'桃花潭风景区'},
  {id:'buffer',phase:'机动',route:'查济／天气／补觉机动日',road:'按状态决定',drive:'优先0小时',focus:'应对降雨、路况和补能变化',detail:'这一天有明确用途：补觉、等待好天气、吸收前面转场延误。前面已用掉就不重复增加；一切顺利也可提前返程。',charge:'返程前查好次日两套补能方案，补到满足行程即可。',from:'查济古村',to:'查济古村'},
  {id:'return-1',phase:'返程',route:'查济 → 浮梁县城',road:'高速优先',drive:'以4–5小时为上限',focus:'分4天南下，不专程绕泾县充电',detail:'默认在浮梁古县衙景区停车场过夜，复用去程落脚点。若地图显示路线不顺，选同走廊、满足5小时上限的中继点。',charge:'沿高速服务区补能，城市站作备用；不要等剩余电量只够到唯一站点。',from:'查济古村',to:'浮梁县'},
  {id:'return-2',phase:'返程',route:'浮梁 → 泰和',road:'高速优先',drive:'以4–5小时为上限',focus:'只安排赶路与午休',detail:'不使用“景德镇一天直奔赣州”作为默认任务。默认从浮梁前往泰和站停车场；开始导航前确认具体终点车时。',charge:'以150–180km为初步补能窗口，结合高速实测续航修正。',from:'浮梁县',to:'泰和县'},
  {id:'return-3',phase:'返程',route:'泰和 → 韶关',road:'高速优先',drive:'以4–5小时为上限',focus:'若导航过长，提前在赣南落脚',detail:'这是需重点复核的一段：若实际起点使到韶关超过5小时，就提前停靠并启用第17天，不用“明天到家”迫使今天赶路。',charge:'午休与补能结合；保留站点故障和排队的时间余量。',from:'泰和县',to:'韶关市'},
  {id:'return-4',phase:'返程',route:'韶关 → 江门',road:'高速优先',drive:'以4–5小时为上限',focus:'白天回家，疲劳就再停一次',detail:'如果前一晚提前落在赣南，今天先重算导航；无法在驾驶上限内回家就使用第17天，不夜赶。',charge:'不要为“到家正好低电量”挤掉备用电量，沿途仍按可用站补能。',from:'韶关市',to:'江门市'}
];

export const sources = [
  ['瑶里所属地区','浮梁县政府；江西省景德镇市浮梁县瑶里镇','https://fuliang.gov.cn/zjfl/flly/jqls/t1092389.shtml'],
  ['婺源所属地区','中央纪委网站；江西省上饶市婺源县','https://m.ccdi.gov.cn/content/b1/a0/4956.html'],
  ['阳产所属地区','黄山市政府；安徽省黄山市歙县深渡镇','https://www.huangshan.gov.cn/zxzx/qxdt/8418306.html'],
  ['查济所属地区','宣城市政府；安徽省宣城市泾县桃花潭镇','https://www.xuancheng.gov.cn/News/show/625442.html'],
  ['深渡新增20余台新能源充电桩','黄山市政府；未标明AC/DC，不代表实时可用','https://www.huangshan.gov.cn/zxzx/qxdt/8412572.html'],
  ['阳产换乘及旅游服务规范工作','安徽经济网，2026-04-10；换乘价格与时段另核实','https://www.ahjjw.com.cn/html/lvyou/2026/0410/529898.html'],
  ['查济充电桩建设进度','泾县政府2026年4月文件；施工信息不等于运营状态','https://www.ahjx.gov.cn/file_xc/6/202604/2026040951deb60bba9c46ccbf419800b50021fa.pdf'],
  ['高速补能查询指引','交通运输部；可通过e路畅通查询高速充电设施','https://www.mot.gov.cn/zhuanti/2025chunyun/chunyunbaodao/202501/t20250127_4163324.html'],
  ['瑶里交通参考','传统村落资料；历史交通数据，最终以实际停车点导航为准','https://www.jianzhuyichan.com/Pages/ProjectDetails.aspx?id=25'],
  ['查济交通参考','传统村落资料；当前停车与票务须复核','https://www.jianzhuyichan.com/Pages/ProjectDetails.aspx?id=335']
];

export function makePlan(length=16) {
  const plan = days.map(day => ({...day}));
  if (Number(length) === 15) plan.splice(plan.findIndex(day => day.id === 'taohuatan'),1);
  if (Number(length) === 17) plan.splice(12,0,{id:'extra',phase:'机动',route:'额外天气／转场缓冲',road:'按状态决定',drive:'优先休息',focus:'用于天气、休息或分段行驶',detail:'这是可挪动的第17天额度：默认显示在返程前，也可用于去程或返程多拆一段。顺利时无需用满，不添加新目的地。',charge:'根据实际位置核实场站，不假定与前一天相同。',from:'查济古村',to:'查济古村'});
  return plan.map(day=>{
    const overnight=overnightFor(day.id);
    return {...day,overnight,stay:`${nightModeLabels[overnight.mode]} · ${overnight.place.name}；${overnight.place.region}；${overnight.place.address}`,sleep:`${overnight.reason} ${overnight.status}。${overnight.place.note}`,geography:dayRegions(day.id),from:qualifyPlace(day.from),to:qualifyPlace(day.to),...(day.via?{via:qualifyPlace(day.via)}:{})};
  });
}
