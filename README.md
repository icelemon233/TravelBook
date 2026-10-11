# Cinna Travel · 赣皖自驾旅游攻略

江门出发的电车自驾旅游攻略，采用床车与酒店住宿。默认16天，可调15/17天；日期未定，用Day1开始的相对日程。

线上：<https://icelemon233.github.io/cinna-travel/>；原西藏攻略保留在 <https://icelemon233.github.io/cinna-travel/tibet/>。

## 已确定的约束

- 单司机，每天纯驾驶目标4–5小时；充电、吃饭、休息另计。
- 六站顺序（含浮梁补给）：江门→浮梁→瑶里→婺源北线→深渡→阳产土楼→查济→江门。
- 实际续航约300km，车宿需要整夜空调。车型、电池容量、夜耗尚未知，不承诺固定损耗。
- 床车为主，每隔2–3晚住酒店恢复，不安排民宿。阳产白天游览、山下过夜，不强求日出。
- 长途高速优先；景观路在时间、路况允许时走。快充不限定县城，县城兜底。
- 驾驶上限优先：去程3天、返程4天。16天含1天机动；15天删查济周边一天，17天多一天可挪动缓冲。

## 16天参考安排

| 天数 | 安排 |
| --- | --- |
| Day1 | 江门→韶关片区 |
| Day2 | 韶关→吉安/泰和片区，酒店恢复 |
| Day3 | 吉安/泰和→浮梁，不直接赶入瑶里 |
| Day4 | 浮梁→瑶里 |
| Day5 | 瑶里→菊径→清华 |
| Day6 | 婺源北线，短途与休整 |
| Day7 | 清华→深渡，按完整山区转场安排 |
| Day8 | 阳产游览，下山过夜 |
| Day9 | 阳产片区→查济，完整转场日 |
| Day10 | 查济慢逛，酒店恢复 |
| Day11 | 查济周边/桃花潭，可取消 |
| Day12 | 天气、补觉或转场机动 |
| Day13 | 查济→景德镇/浮梁片区 |
| Day14 | 景德镇/浮梁→吉安/泰和片区 |
| Day15 | 吉安/泰和→韶关；超时则提前在赣南落脚 |
| Day16 | 韶关→江门；必要时使用第17天 |

中继是候选区间，尚未按具体酒店和停车场做实时导航核验。“每天以5小时为上限”不表示每段已经证实能在5小时内完成；若不满足，提前停靠、拆段并使用缓冲，不夜赶。

## 事实与修订

取消首日约900km赶路、泾县专门补电住宿日、未经核实的民宿推荐。原文28/85/90km等道路里程、高速费855元、阳产固定30元均未作为已核实数据写入。

- [深渡新增充电桩](https://www.huangshan.gov.cn/zxzx/qxdt/8412572.html)：20余台，未说明AC/DC或实时可用状态。
- [阳产服务规范工作](https://www.ahjjw.com.cn/html/lvyou/2026/0410/529898.html)：换乘、票务服务调整，价格和时段需复核。
- [查济施工进度](https://www.ahjx.gov.cn/file_xc/6/202604/2026040951deb60bba9c46ccbf419800b50021fa.pdf)：2026年4月已进场施工，不等于已运营。
- [高速补能查询](https://www.mot.gov.cn/zhuanti/2025chunyun/chunyunbaodao/202501/t20250127_4163324.html)：可用e路畅通查询高速充电设施。
- [瑶里交通参考](https://www.jianzhuyichan.com/Pages/ProjectDetails.aspx?id=25)、[查济交通参考](https://www.jianzhuyichan.com/Pages/ProjectDetails.aspx?id=335)：历史资料仅作核查线索。

资料核查日期2026-10-11。不提供实时天气、站点状态、停车许可、房价或路况；具体场站和过夜点须出发前核实。

## 文件与功能

原生HTML/CSS/JavaScript，无构建依赖：

- `index.html`：固定说明与页面结构。
- `autumn/trip-data.js`：逐日路线、补能、过夜条件、来源与变体。
- `autumn/app.js`：阶段筛选、备注、核对清单、本地保存与打印。
- `autumn/energy.js`：行驶窗口和夜耗粗算。容量/夜耗未知时不生成夜间SOC结论。
- `tibet/`：原gh-pages线上西藏页面完整快照，源提交 `f415d3d4a474b9680cbb9e0ced9d02985f2ce75b`，包含样式、脚本、图片。
- `tibet-source.html`：原main的西藏页面源码快照，与原线上版本不同。

备注、酒店预算与核对进度仅保存在当前浏览器localStorage，不上传、不跨设备同步。变体按稳定ID保存备注，不随Day序号改变而错位。

## 本地预览与验证

需要Node.js，无第三方安装依赖。

```sh
npm run dev
npm run check
```

打开 <http://127.0.0.1:4173/>。也可直接运行 `node scripts/dev.mjs`、`node --check autumn/app.js` 和 `node --test scripts/plan.test.mjs`。

## GitHub Pages发布

先提交并推送源码到main，再执行：

```sh
npm run deploy
```

跨平台Node脚本检查工作区干净、运行测试，将静态站与西藏快照同步到gh-pages，正常提交推送，不强推。`deployment.json`记录源提交与关键文件SHA-256，便于核对线上状态。

`DEPLOY_REMOTE` / `DEPLOY_BRANCH`可指定目标，默认沿用origin和gh-pages。推送成功后仍需等待Pages构建完成并核实线上内容。
