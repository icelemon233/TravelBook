# Cinna Travel Book

[English](README.md) | 简体中文

Android、iOS、Web 共用的 Flutter 旅行路书，合并 `cinna-travel` 与 `cinna-travel-archive`。完整迁移赣皖自驾攻略和西藏路书，保留原数据、图片、参考来源与 Git 历史。

Web 发布地址：[icelemon233.github.io/cinna-travel-book](https://icelemon233.github.io/cinna-travel-book/)。原西藏入口位于新站的 `tibet/`，跳转到对应 Flutter 页面。

## 功能

- 赣皖 15/16/17 天，西藏 A/B/C 办证分流、北线 a/b/c 分支、申扎/班戈方案，共 33 个组合。
- 每日行程、导航分段、个人备注、具体住宿与备用酒店；12 处景点及图片授权。
- 缓存的真实 OSM/OSRM 道路与湖泊，日期筛选、缩放、高清 PNG 导出；缺失道路不补画直线。
- 可编辑旅行预算与费用明细、返程两方案对比、电车续航和车宿夜耗粗算。未知里程或价格保持未知。
- 48 项西藏准备清单、14 项风险的组合筛选、原办证顺序、事实与来源。
- 设备本地保存、旧网页备注/清单迁移、JSON 备份导入导出、完整中文 PDF 和系统打印。
- 小屏底部导航、大屏目录；中文字体与 PDF.js 本地提供，Web 资源按版本缓存。

所有旅行资料沿用原核查日期。资料迁移不表示实时房价、天气、充电站、停车过夜许可或办证政策已经重新核实。备注与清单不上传，不自动跨设备同步。

## 架构

按功能组织的 MVVM，使用不可变领域模型、抽象 Repository、独立 ViewModel 和平台 Service。`app/` 是依赖注入组合根；Widget 不执行预算、路线规则或存储操作。复杂计算为纯 Dart，可独立测试。

```text
lib/
  app/                     组合根、路由、主题、自适应导航
  core/                    JSON 边界、平台适配、共用 UI
  features/
    books/                 旅行册模型、目录与资产 Repository
    preferences/           本地资料、迁移、备份和写入队列
    itinerary/             每日行程与备注
    budget/                费用计算、验证与编辑
    map/                   几何投影、绘制、筛选与快照
    preparation/           准备清单
    risks/                 风险筛选
    attractions/           景点目录
    stays/ returns/ energy/ permits/ sources/ overview/ export/
assets/
  data/                    版本化路书数据与道路缓存
  images/                  原始图片与署名
  fonts/                   Noto Sans SC、OFL 与来源记录
tools/                     固定快照导出、资源校验、预览、发布
```

更多设计、状态边界与验证策略见 [架构说明](docs/architecture.md)。三端使用原生 Flutter 组件，没有把旧网页包装进 WebView。

## 开发

固定 Flutter **3.47.7 / Dart 3.13.5**，依赖锁定在 `pubspec.lock`。辅助工具使用 Node.js 24 与 pnpm 11.25.0。

```sh
flutter pub get --enforce-lockfile
flutter run -d chrome
dart format --output=none --set-exit-if-changed lib test integration_test tools/generate_icons.dart
flutter analyze --no-pub
flutter test --no-pub
```

Android 构建需 Android SDK/JDK；iOS 构建需 macOS/Xcode。当前 CI 同时验证 Android 开发包、iOS 模拟器和未签名设备构建、Flutter Web，并在一次性 Android/iOS 模拟器中运行启动与原生存储测试。

```sh
flutter build apk --debug --no-pub
flutter build ios --simulator --debug --no-codesign --no-pub
flutter build ios --release --no-codesign --no-pub
flutter build web --release --no-pub --base-href /cinna-travel-book/ --no-web-resources-cdn --no-wasm-dry-run
node tools/prepare-web.mjs
node tools/serve-web.mjs
```

预览为 `http://127.0.0.1:18760/cinna-travel-book/`。Web 采用 hash 路由，例如 `#/book/tibet/itinerary?day=10%2F1`。iOS 未签名构建不能直接安装到 iPhone；正式签名、系统分享/打印和上架需要实际设备验收。

## 旧数据与历史

- `archive/static-web-20261017`：原赣皖网站及当时西藏发布快照。
- `archive/react-antd-20260920`：原西藏 React/Ant Design 完整源码。
- `archive/pre-antd`：原 Ant Design 迁移前版本。
- 合并父节点保留两个仓库的历史，归档分支可独立检出恢复。

```sh
pnpm install --frozen-lockfile --ignore-scripts
pnpm verify:assets
```

数据导出器直接读取固定 Git 提交，不依赖旧本地目录，也不把旧 JavaScript 放进客户端。36 组旧预算结果用于迁移对照，覆盖各方案、人数/房间数联动、充电损耗与返程差额。

Web 自动兼容同一 origin 下的 `cinna-ganwan-v1`、`tibet-checklist-personal-v2`、`tibet-checklist`，保留原键。移动端或不同设备用备份迁移。预算重置不清空备注和清单；导入失败不覆盖现有数据；保存失败会保留会话数据并提示备份。

## 发布与资源授权

推送 `main` 后，GitHub Actions 在代码检查及三端构建通过后自动发布 GitHub Pages。`deployment.json` 记录源提交和静态文件 SHA-256，发布后需核对线上状态。也可用 `pnpm deploy` 查看或触发当前 main 的发布流程，需要已认证的 GitHub CLI。

公路与湖泊数据 © OpenStreetMap contributors，ODbL；路线参考 OSRM。赣皖照片按各自 CC 授权保留原文件、作者与来源，在页面按比例裁切显示。西藏原有生成配图明确标注为 AI 意境素材。中文字体为 Noto Sans SC（SIL OFL 1.1）；PDF.js 为 Apache-2.0。授权与来源文件随资源保留。
