# Cinna Travel Book

- 唯一项目目录为 `D:/Projects/cinna-travel-book`。Android、iOS、Web 使用同一套 Flutter 源码；不得以 WebView 包装旧网页替代迁移。
- 使用按功能组织的 MVVM：不可变领域模型、抽象 Repository、平台 Service、ViewModel 和 View。页面只处理布局与展示，不读写存储、不计算路线或预算。
- core 不导入 app/features；跨功能使用公开接口和领域模型，不导入对方 data/presentation 实现。运行 `pnpm check:boundaries` 验证方向。导出通过组合根读取快照，不持有其他功能的 ViewModel。
- 本地读取失败时禁止自动覆盖旧资料；有效导入成功后解除保护并清除旧预算草稿。文件选择、导入、导出共用 BackupLimits 的容量限制。
- 保留赣皖 15/16/17 天、西藏办证 A/B/C 分支及申扎/班戈方案；旧版规则、来源日期、未核实项、照片作者与 OSM/ODbL 署名必须保留。
- 用户备注和清单使用稳定旅行/日期 ID；预算重置不得清除备注或清单。Web 兼容旧 localStorage 清单和备注；移动端通过 JSON 导入导出迁移。
- 禁止提交用户个人存储、密钥、签名文件和构建产物。源码公开已获用户授权。
- 完成变更后运行 Dart format、Flutter analyze、相关 unit/widget/integration 测试，以及 Android、iOS、Web 构建。真实浏览器交互与构建测试分别记录；没有真机验收不得宣称物理分享、打印、文件系统或正式上架已验证。
- 旧网页和 React 源码仅保留在 archive 分支。发布 Flutter Web 到 `https://icelemon233.github.io/cinna-travel-book/`，保留 Git 历史，不强推；按原有授权，完成验证后自动发布。
- 文案具体、自然，避免空泛旅行鸡汤。迁移不把历史房价、驾驶时间、停车许可和办证流程重新标成当前已核实数据。
