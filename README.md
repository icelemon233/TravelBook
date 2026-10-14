# Cinna Travel

2026 年 9 月 28 日至 10 月 4 日西藏自驾路书，9 月 27 日晚取车。

全站使用 React 19、Ant Design 6.6.5（中文语言包）及统一主题，依赖版本锁定在 package-lock.json。包括 Tabs 导航、Segmented 方案切换、Select 筛选、Table 表格、InputNumber 预算表单、Checkbox 清单、Collapse 折叠、Steps 办证流程、Timeline 行程、Progress 与 Statistic。

## 开发与构建

需要 Node.js 22 或更高版本。

```bash
npm ci
npm run dev
```

打开 http://127.0.0.1:4173/ 。开发命令先构建再监听源码变更，修改后刷新浏览器。

```bash
npm run build
```

esbuild 将 src/App.jsx 打包为根目录 app.js 与 app.css。构建产物、index.html 和 assets/ 可直接通过静态服务器预览，不依赖 CDN。图片和地图数据均随站点提供。

## 文件与功能

- src/App.jsx：全站 React / Ant Design 组件。
- src/app.css：页面布局和移动端适配；组件样式由 Ant Design 提供，主题配置位于 App.jsx。
- src/data.json：保留的行程、风险、预算及清单数据。
- src/scenarios.js、src/model.js：Plan A / B / C、北线分支、住宿、预算与行程联动。
- src/tickets.js：门票价格、来源日期和适用限制。
- src/map-renderer.js、src/road-network.js、src/map-geography.js：公路路线 Canvas 地图与 OSM / OSRM 数据。

保险默认为 191 元 / 人（10 天），9 月 27 日晚上取车。租车暂按 7 天，以订单时刻为准；餐饮天数独立计算。空缺里程与住宿费用未计入，预算仍为暂计。

清单继续使用 tibet-checklist-personal-v2，兼容原始清单存储。风险表格支持日期、等级、类别与关键词组合筛选，以及等级排序和重置。移动端表格可横向滚动。

## 地图与素材

主要公路和湖形来自 OpenStreetMap / Overpass；彩色行程线来自 OSRM driving 查询（2026-09-20），不包含实时路况或通行许可。日喀则至昂仁通过谢通门方向约束走 G349。湖泊节点是岸边道路参考点，未确认景区入口和停车场。Plan A 未指定的珠峰方向及 G219 边境县路段保留缺口，不绘虚构连线。

数据 © OpenStreetMap contributors，ODbL；网页内保留来源链接。雪山湖泊 logo、风景、装备及浅色山纹背景为 AI 生成素材；山纹不是测绘地形。

## 发布

```bash
npm run deploy
```

需具备 Node.js、Git 及仓库 SSH 推送权限，无需 Bash 或 rsync。脚本先构建，再向 gh-pages 发布静态页面、资源、404 回退页及 deployment.json 校验信息，保留分支历史。所有资源使用相对路径，适用于 GitHub Pages 子目录。

按用户约定，每次完成网站修改并通过相应验证后，自动执行发布，无需再次确认。发布后核对线上 deployment.json 与实际文件哈希，确认线上更新。此约定记录于 AGENTS.md。

## Ant Design 组件复核

已将图片替换为 Image，链接与文案替换为 Typography，首页数字替换为 Statistic，页头、主体、页尾使用 Layout，对齐组使用 Flex，筛选容器使用 Card。说明文字采用结构化内容与 Typography 渲染，移除旧 HTML 注入。普通 div、section、figure、br 仅承担结构或语义；Canvas 保留用于 Ant Design 不提供的地理路线绘制。图片预览关闭以保持现有页面交互。

