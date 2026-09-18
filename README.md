# Z-Swich

macOS 菜单栏工具：一键切换 ChatGPT 桌面版（Codex 内核，bundle id `com.openai.codex`）的登录账号。
只替换登录凭证，本地会话记录、项目、配置、插件全部原样保留。

![Z-Swich 账号管理窗口](docs/screenshots/main-window.png)

<sub>账号管理窗口：顶部为当前账号与额度窗口（剩余百分比与重置倒计时），下方为已保存账号表格，可单独查询额度或一键切换。截图中的账号信息已打码。</sub>

## 原理

ChatGPT 桌面版的账号身份只由 `~/.codex/auth.json` 一个文件决定。
Z-Swich 为每个账号保存一份该文件的快照，切换时：

1. 保存当前账号的最新令牌（应对 refresh_token 轮转）
2. 优雅退出 ChatGPT（不强杀，等它自己写完数据）
3. 把目标账号的快照写回 `auth.json`
4. 重新启动 ChatGPT

## 构建

需要 Xcode 26 / Swift 6，macOS 15 以上。

日常开发和归档推荐打开正式的 macOS App 工程：

```bash
open ZSwich.xcodeproj
```

在 Xcode 中选择 `ZSwich` Scheme 和 `My Mac`，使用 `Product → Archive`。归档会被识别为
`macOS App Archive`，可在 Organizer 中通过 `Distribute App` 执行签名、公证与导出。

不使用 Xcode 工程时，仍可通过 SwiftPM 脚本构建：

```bash
./Packaging/build-app.sh
```

脚本产物在 `build/Z-Swich.app`，可直接 `open` 或拷贝到 `~/Applications`。

## 使用

1. 启动后菜单栏出现 Z 形双向切换图标。打开菜单时，当前登录账号会被收录或更新。
2. **添加新账号**：点「添加新账号」。Z-Swich 会保存当前账号、退出 ChatGPT 并让它进入登录页；
   登录第二个账号后，再打开 Z-Swich 菜单或账号窗口即可收录。
3. **切换**：点列表里的任意账号。
4. **账号窗口**：从菜单点「打开账号窗口」，可查看完整账号表格、运行状态、5 小时/每周剩余额度和本次活动日志。
5. **删除**：在账号窗口点行尾垃圾桶，只删 Z-Swich 的快照，不影响 ChatGPT。

账号窗口采用深色 Liquid Glass 视觉语言，并保持内容层与操作层分离：顶部状态、Toast 和底部操作区强调玻璃层次，账号表格与日志保持清晰的内容卡片。macOS 15 以上均有一致的可读性。

额度只在打开账号窗口或手动刷新时查询，不轮询、不落盘。查询使用当前 `auth.json` 中的访问令牌与账号 ID，
只保留解析后的百分比和重置时间；该接口属于 ChatGPT 桌面端内部接口，未来若发生变更，界面会显示查询失败但不影响账号切换。

## 界面与交互

账号窗口按设计原型复刻，支持窗口缩放和窄窗口重排。底部操作栏固定可见，账号表格在空间不足时横向滚动，活动日志会使用剩余高度。

额度颜色按剩余比例统一显示：

- 低于 20%：红色告警
- 20–49%：橙黄色提醒
- 50% 及以上：绿色正常

窗口打开时提供以下动效：

- 当前账号头像悬停放大、轻微 3D 倾斜、图标弹跳和状态光晕
- 两张额度卡悬停抬升、鼠标跟随光晕、边框与阴影反馈
- 额度进度条首次展开、数值变化、循环流光和悬停增强
- 运行状态呼吸、分区错峰入场、账号行抬升、日志插入、Toast、按钮扫光及切换加载

这些动画只在窗口存在时运行，并遵循 macOS「减少动态效果」设置；关闭窗口后不会留下动画、定时器或额度轮询。

命令行模式（适合快捷指令、脚本）：

```bash
Z-Swich.app/Contents/MacOS/Z-Swich --list
Z-Swich.app/Contents/MacOS/Z-Swich --switch someone@example.com
Z-Swich.app/Contents/MacOS/Z-Swich --new-login
```

## 注意

- **不要在 ChatGPT 里点「登出」**。登出会让服务器吊销令牌，对应快照就失效了。换号一律用 Z-Swich。
- 快照含有登录令牌，以 0600 权限保存在 `~/Library/Application Support/Z-Swich/snapshots/`，与 ChatGPT 自己存放 `auth.json` 的安全级别一致。
- 尊重 `CODEX_HOME` 环境变量。
- `cli_auth_credentials_store` 未配置或为 `file` 时可用；`keyring`/`auto` 模式会明确提示且不会改写凭证。
- 仅支持新版 ChatGPT（com.openai.codex）。旧版经典 ChatGPT（com.openai.chat）开了沙盒且登录态在钥匙串，不适用。
