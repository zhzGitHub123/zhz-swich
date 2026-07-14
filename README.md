# zhz-swich

`zhz-swich` 是一个原生 macOS Swift 应用，目标是用最少常驻资源完成 Codex 与 Claude 订阅地址的本地切换。

## 产品定位

- 面向经常在 Codex、Claude 或不同订阅源之间切换的 macOS 用户。
- 只管理本机配置，不做代理、不劫持流量、不托管订阅、不同步云端数据。
- 操作以用户主动触发为主，避免后台轮询、长连接和隐式网络活动。
- 失败必须显式暴露，不能用静默兜底制造“已成功”的假象。

## 初始功能范围

- 管理 Codex 与 Claude 的订阅地址档案。
- 一键切换当前启用地址。
- 切换前备份原始配置，支持回滚。
- 显示当前目标、最近一次切换结果和失败原因。
- 对订阅地址做格式校验，可选手动连通性检查。
- 提供菜单栏快速切换入口和简洁设置窗口。

## 非目标

- 不实现网络代理、流量转发或抓包。
- 不解析复杂订阅内容，初期只处理地址本身。
- 不做账号系统、远程同步、团队协作或插件市场。
- 不内置大体积依赖、脚本运行时、浏览器内核或跨平台框架。
- 不在后台定时刷新订阅地址。

## 技术方向

- 原生 Swift。
- 标准 Xcode macOS App 工程作为唯一工程入口。
- SwiftUI 负责主要界面。
- AppKit 只用于菜单栏、系统集成和 SwiftUI 不擅长的 macOS 能力。
- 本地持久化优先使用小型 Codable 数据文件。
- 可能包含敏感信息的字段进入 Keychain，日志只保留脱敏内容。

## 开发命令

### Xcode

标准 Xcode 工程：

```bash
open ZhzSwitch.xcodeproj
```

在 Xcode 中选择：

```text
Scheme: ZhzSwitchApp
Destination: My Mac
```

本机运行：

```text
Product -> Run
```

打包归档：

```text
Product -> Archive
```

当前工程使用本地 ad-hoc 签名，适合自己机器运行和验证。正式分发给其他用户前，需要在 Xcode 里配置开发者团队、证书签名和公证。

命令行验证 Xcode 工程：

```bash
xcodebuild -project ZhzSwitch.xcodeproj -scheme ZhzSwitchApp -configuration Release -destination platform=macOS build
xcodebuild -project ZhzSwitch.xcodeproj -scheme ZhzSwitchApp -configuration Release -destination generic/platform=macOS archive
```

打包脚本会生成本地可安装的 DMG：

```bash
./scripts/package-dmg.sh
```

产物路径：

```bash
dist/zhz swich-0.1.0.dmg
```

当前签名方式是 ad-hoc 本地签名，适合自己机器安装运行；正式分发前还需要开发者证书签名和公证。

## 文档索引

- [产品需求](docs/PRODUCT_SPEC.md)
- [架构设计](docs/ARCHITECTURE.md)
- [切换目标与配置模型](docs/CONFIG_TARGETS.md)
- [性能与耗电预算](docs/PERFORMANCE_BUDGET.md)
- [界面与交互规范](docs/UI_UX.md)
- [安全与隐私](docs/SECURITY_PRIVACY.md)
- [开发计划](docs/DEVELOPMENT_PLAN.md)
- [技术决策记录](docs/TECHNICAL_DECISIONS.md)

## 当前状态

仓库当前已完成标准 Xcode 原生 macOS App 工程：

- `ZhzSwitchCore` 核心库。
- `ZhzSwitchApp` SwiftUI 主窗口和菜单栏入口。
- 已实现供应商列表、本地 JSON 持久化、当前使用项切换、复制、编辑、删除和新增。
- 已实现订阅地址脱敏、切换服务编排、文件型目标适配器和 JSON 档案存储。
