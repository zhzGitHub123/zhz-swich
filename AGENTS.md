# AGENTS.md

zhz-switch-design为原型设计稿，只读不可修改删除编辑

## 语言

使用中文说明思路、计划、步骤和结果。

## 工作方式

- 先给结论或结果，再补必要上下文。
- 能合理假设就继续，不为低风险细节反复确认。
- 先读真实文件和上下文，再修改。
- 不添加无关功能，不做顺手重构。
- 代码和文档都保持小而清晰，避免过度设计。

## 调试与实现

- 先追根因，不做只压症状的补丁。
- 错误要显式暴露，不吞异常、不伪成功。
- 如果问题来自重复逻辑、双重真值或跨模块状态，按结构性问题处理。
- 改动保持最小闭环，该删的死代码和重复分支一起删。

## 验证

- 改完先跑最相关的验证。
- 能跑就跑，不能跑要说明原因。
- 不把静态阅读包装成运行时验证。

## 本机命令约定

优先用 `rtk` 代理 shell 命令，例如：

```bash
rtk git status
rtk xcodebuild -project ZhzSwitch.xcodeproj -scheme ZhzSwitchApp build
```

## 项目定位

- 当前项目是 macOS 原生 SwiftUI 应用，Xcode 工程为 `ZhzSwitch.xcodeproj`，Scheme 为 `ZhzSwitchApp`。
- `zhz-switch-design/` 是 React 设计原型，只作为视觉真值来源，始终只读。
- 视觉仍以设计稿为真值；提供商模块已接入真实业务（SwiftData 持久化、增删改查与激活切换），其余页面未经用户要求不提前接业务逻辑，也不复用原型中的前端运行时代码。
- 业务层位于 `Sources/ZhzSwitchCore`（SwiftData 仓库 `ProviderRepository`、数据模型等），界面通过 `ProviderListStore` 访问，不直接操作仓库。
- 原生入口是 `Sources/ZhzSwitchApp/ZhzSwitchApp.swift`；`MainWindowView.swift` 只保留应用外壳（主题环境注入、全局背景、页面路由），各页面与共享组件已按下方“SwiftUI 复用基线”拆分为独立文件。

## 当前还原进度

- “提供商”页面已完成视觉还原并接入真实数据：列表来自 `ProviderListStore`（SwiftData 持久化），支持新增、编辑、复制、删除与激活切换，新增 / 编辑表单为 `ProviderEditorView`。
- 已实现浅蓝—紫—粉渐变背景、背景噪点、磨砂玻璃、折射高光、扫描线纹理、悬停极光与扫光、活动卡片旋转渐变描边。
- 已实现 256 点玻璃侧栏、顶部工具栏、活跃提供商大卡及供应商 Bento 卡片；侧栏顶部含 Codex / Claude 家族切换器（`ProviderFamilySwitcher`），切换同时联动全局主题家族。
- 已完成“仪表台”页面（`ConfigurationDashboardView`）：只读展示 `~/.codex/config.toml` 与 `~/.claude/settings.json` 中当前生效的配置，支持手动刷新。
- 已实现设置页“浅色 / 深色 / 跟随系统”主题切换，选择通过 `AppStorage` 持久化。
- Codex 与 Claude 两套主题家族均已可用，浅色与深色模式各有独立的背景、玻璃、边框和语义文字配色。
- 已修正设置页“关于 / 检查更新”卡片的内容垂直居中。
- 其余页面（MCP / 提示词 / 技能 / 使用统计）已有视觉还原，数据仍为设计稿静态样例；后续按页面接入真实数据。
- 环境变量模块已从侧栏与页面路由中移除，不再作为应用功能维护。

## 主题架构

- 主题分为两层：`AppThemeFamily` 表示主题家族，`AppThemeMode` 表示浅色、深色或跟随系统。
- 已注册 `.codex` 与 `.claude` 两个家族，`AppThemePalette.resolve` 为两者分别提供浅色 / 深色配色；后续新增家族时继续在此集中扩展，不要把家族颜色条件散落到各个视图。
- 主题家族和明暗模式分别使用 `appearance.theme.family`、`appearance.theme.mode` 持久化。
- `MainWindowView` 负责注入主题家族并设置 `preferredColorScheme`；页面组件不得再次强制指定浅色或深色。
- 全局背景和玻璃容器从 `AppThemePalette` 取值，文字、表面和边框优先使用 `slate*`、`themeSurface`、`themeBorder` 等语义颜色。
- 新增界面必须同时检查 Codex 与 Claude 两个家族的浅色和深色效果；不要重新引入只适用于浅色的硬编码白色表面。

## 设计稿文件映射

设计稿源码 → 对应 SwiftUI 文件：

- 应用壳层与背景：`zhz-switch-design/src/app/App.tsx` → `MainWindowView.swift`
- 侧栏：`zhz-switch-design/src/app/components/sidebar-nav.tsx` → `SidebarView.swift`
- 提供商页面：`zhz-switch-design/src/app/components/providers-view.tsx` → `ProvidersDashboardView.swift`
- 使用统计页面：`zhz-switch-design/src/app/components/usage-view.tsx` → `UsageDashboardView.swift`
- 其他页面（MCP / 提示词 / 技能 / 设置）：`zhz-switch-design/src/app/components/other-views.tsx` → `OtherDashboardViews.swift`
- 玻璃组件：`zhz-switch-design/src/app/components/glass.tsx` → `GlassComponents.swift`
- 动效与活动描边：`zhz-switch-design/src/styles/globals.css` → `GlassComponents.swift`
- 主题变量：`zhz-switch-design/src/styles/theme.css` → `GlassComponents.swift`（`AppThemePalette`、`Color` 语义色扩展）

仪表台页（`ConfigurationDashboardView.swift`）与提供商新增 / 编辑表单（`ProviderEditorView.swift`）为原生新增功能页，无对应设计稿。

新页面只读取对应设计文件、共享玻璃组件和必要样式，不要重新遍历整个设计稿目录。

## SwiftUI 复用基线

继续还原页面时优先复用已有组件，按文件查找：

- `MainWindowView.swift`：`AuroraBackground`、`NoiseTexture`（全局背景）、主题环境注入与页面路由（`ModuleKey` 含仪表台 dashboard 在内共 7 个模块），并持有共享的 `ProviderListStore` 实例。
- `SidebarView.swift`：固定侧栏 `SidebarView`，顶部为家族切换器。
- `GlassComponents.swift`：`GlassCard`、`RefractionHighlights`、`ScanlineTexture`、`AnimatedGlassEffects`（玻璃容器、悬停极光与扫光）、`RotatingActiveBorder`（活动卡片动态描边）、`AppThemePalette`、`Color` 语义色扩展（`slate*`、`themeSurface`、`themeBorder`、`adaptive`）。
- `DashboardComponents.swift`：跨页面通用小组件 `ModuleHeader`、`ModuleAction`、`HeaderButton`、`VisualToggle`、`CompactIconButton`、`ProviderFamilySwitcher`（Codex / Claude 家族切换器）。
- `ProviderListStore.swift`：提供商列表状态源，封装 `ZhzSwitchCore` 的 SwiftData 仓库，提供增删改查与激活切换。
- `ProviderEditorView.swift`：提供商新增 / 编辑表单。
- `ConfigurationDashboardView.swift`：仪表台页，只读展示 Codex / Claude 本地生效配置。

`ProviderGlyph`、`StatusBadge` 等页面专属子组件保留在各自页面文件内（如 `ProvidersDashboardView.swift`），不是跨页面通用组件，不要从其他页面文件引用。

不要为新页面复制玻璃效果或跨页面小组件；应复用或小幅扩展 `GlassComponents.swift` / `DashboardComponents.swift`，避免形成多套视觉真值。

新增页面级 Swift 文件后，必须同步在 `ZhzSwitch.xcodeproj/project.pbxproj` 手动登记（`PBXBuildFile`、`PBXFileReference`、`ZhzSwitchApp` 分组的 `children`、`PBXSourcesBuildPhase` 的 `files` 共 4 处），本工程未使用 Xcode 16 的文件系统同步分组，遗漏任何一处都会导致新文件不参与编译。

## 新页面还原流程

1. 先读本文件，再只读目标页面对应的设计稿源码。
2. 提取页面结构、文案、栅格、尺寸、颜色、圆角、阴影和动效。
3. 在 SwiftUI 中复用现有背景、侧栏和玻璃组件，仅新增目标页面视图。
4. 保持设计稿文案和视觉状态；按钮可静态展示，不提前实现业务逻辑。
5. 构建成功后通知用户，请用户手动启动、切换页面并提供截图；不能把静态阅读或构建成功当作视觉验收。

## 视觉验证权限

- 视觉验证由用户手动操作，助手不得自行启动或激活 App、点击页面、移动鼠标、调用截图工具。
- 需要验证时，直接请用户打开对应页面并提供截图，再根据截图修正。

## 构建与单实例验证

每次重新构建或启动前，必须先关闭所有旧测试实例，防止同时打开多个 App：

```bash
pkill -x 'zhz swich' || true
rtk xcodebuild -quiet -project ZhzSwitch.xcodeproj -scheme ZhzSwitchApp -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/zhz-switch-derived CODE_SIGNING_ALLOWED=NO build
```

- 构建前先关闭旧实例；构建后由用户决定何时启动应用。
- 沙箱中可能出现 CoreSimulator、FSEvents 或日志权限告警；以 macOS 构建退出码和 `xcodebuild: ok` 为准，不要输出整段无关日志。
