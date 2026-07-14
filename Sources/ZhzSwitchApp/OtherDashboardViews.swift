import SwiftUI

// MARK: - MCP

struct McpDashboard: View {
    private let servers = McpServerVisual.samples

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ModuleHeader(
                title: "MCP 服务器",
                subtitle: "连接工具与数据源",
                actions: [
                    ModuleAction(title: "同步", icon: "arrow.clockwise"),
                    ModuleAction(title: "导入", icon: "square.and.arrow.down"),
                    ModuleAction(title: "新增", icon: "plus", emphasized: true)
                ],
                usesLiquidGlassButtons: true
            )

            HStack(spacing: 8) {
                FilterCapsule(title: "全部", value: "6", active: true)
                FilterCapsule(title: "正常", value: "3")
                FilterCapsule(title: "异常", value: "2")
                FilterCapsule(title: "离线", value: "1")
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 245, maximum: 360), spacing: 18)], spacing: 18) {
                ForEach(Array(servers.enumerated()), id: \.element.name) { index, server in
                    McpServerCard(server: server, tint: index.isMultiple(of: 2) ? .purple : .white)
                }
            }
        }
    }
}

private struct FilterCapsule: View {
    let title: String
    let value: String
    var active = false

    var body: some View {
        NativeLiquidGlassCard(
            tint: active ? .blue : nil,
            cornerRadius: 17,
            fillsAvailableSpace: false
        ) {
            HStack(spacing: 6) {
                Text(title)
                Text(value)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.themeSurface.opacity(0.55), in: Capsule())
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.slate700)
            .padding(.horizontal, 12)
            .frame(minHeight: 34)
        }
    }
}

private struct McpServerCard: View {
    let server: McpServerVisual
    let tint: Color

    var body: some View {
        NativeLiquidGlassCard(tint: tint, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.themeSurface.opacity(0.48))
                        Image(systemName: "server.rack")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.slate800)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(server.name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.slate900)
                        Text(server.command)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.slate600)
                            .lineLimit(1)
                    }
                    Spacer()
                    McpStatusBadge(status: server.status)
                }

                Spacer()
                HStack {
                    Text(server.application)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.slate600)
                    Spacer()
                    VisualToggle(enabled: server.enabled)
                }
            }
            .padding(17)
        }
        .frame(height: 142)
    }
}

private struct McpStatusBadge: View {
    let status: McpServerVisual.Status

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(status.title)
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(status.color)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.13), in: Capsule())
        .overlay { Capsule().stroke(status.color.opacity(0.28), lineWidth: 1) }
    }
}

private struct McpServerVisual {
    enum Status {
        case normal, warning, offline

        var title: String {
            switch self {
            case .normal: "正常"
            case .warning: "异常"
            case .offline: "离线"
            }
        }

        var icon: String {
            switch self {
            case .normal: "checkmark.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .offline: "xmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .normal: .green
            case .warning: .orange
            case .offline: .red
            }
        }
    }

    let name: String
    let command: String
    let application: String
    let status: Status
    let enabled: Bool

    static let samples = [
        McpServerVisual(name: "filesystem", command: "npx @mcp/fs", application: "Claude", status: .normal, enabled: true),
        McpServerVisual(name: "github", command: "npx @mcp/github", application: "Claude · Codex", status: .normal, enabled: true),
        McpServerVisual(name: "supabase", command: "uvx supabase-mcp", application: "Claude", status: .warning, enabled: true),
        McpServerVisual(name: "browser", command: "npx @mcp/browser", application: "Gemini", status: .offline, enabled: false),
        McpServerVisual(name: "postgres", command: "uvx pg-mcp", application: "Claude · Codex", status: .normal, enabled: true),
        McpServerVisual(name: "slack", command: "npx @mcp/slack", application: "Codex", status: .warning, enabled: false)
    ]
}

// MARK: - Prompts

struct PromptsDashboard: View {
    private let prompts = PromptVisual.samples

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ModuleHeader(
                title: "提示词库",
                subtitle: "可复用的 AI 提示词预设",
                actions: [
                    ModuleAction(title: "导入", icon: "square.and.arrow.down"),
                    ModuleAction(title: "导出", icon: "square.and.arrow.up"),
                    ModuleAction(title: "新建", icon: "plus", emphasized: true)
                ],
                usesLiquidGlassButtons: true
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 245, maximum: 360), spacing: 18)], spacing: 18) {
                ForEach(Array(prompts.enumerated()), id: \.element.name) { index, prompt in
                    PromptCard(prompt: prompt, tint: [.pink, .blue, .purple, .green][index % 4])
                }
            }
        }
    }
}

private struct PromptCard: View {
    let prompt: PromptVisual
    let tint: Color

    var body: some View {
        NativeLiquidGlassCard(tint: tint, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                        Text(prompt.category)
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.slate700)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.themeSurface.opacity(0.48), in: Capsule())
                    Spacer()
                    VisualToggle(enabled: true)
                }

                Text(prompt.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.slate900)
                    .padding(.top, 13)
                Text(prompt.preview)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.slate600)
                    .lineLimit(2)
                    .padding(.top, 7)

                Spacer()
                HStack {
                    Text("#\(prompt.tag) · \(prompt.application)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.slate600)
                    Spacer()
                    HStack(spacing: 5) {
                        CompactIconButton(icon: "eye", usesLiquidGlass: true)
                        CompactIconButton(icon: "square.and.pencil", usesLiquidGlass: true)
                        CompactIconButton(icon: "trash", usesLiquidGlass: true)
                    }
                }
            }
            .padding(17)
        }
        .frame(height: 180)
    }
}

private struct PromptVisual {
    let name: String
    let category: String
    let preview: String
    let application: String
    let tag: String

    static let samples = [
        PromptVisual(name: "代码评审专家", category: "开发", preview: "你是一位资深代码评审专家，请按可读性…", application: "Claude", tag: "review"),
        PromptVisual(name: "PRD 草稿生成", category: "产品", preview: "根据以下用户故事，输出标准 PRD 文档…", application: "通用", tag: "pm"),
        PromptVisual(name: "SQL 优化助手", category: "数据", preview: "请分析下方 SQL 的执行计划并给出优化…", application: "Codex", tag: "sql"),
        PromptVisual(name: "翻译润色 (中↔英)", category: "写作", preview: "保留语气与风格，进行高质量双向翻译…", application: "Gemini", tag: "i18n"),
        PromptVisual(name: "Bug 复盘模板", category: "开发", preview: "按 5 Whys 方法引导用户复盘根因…", application: "Claude", tag: "ops"),
        PromptVisual(name: "周报生成", category: "办公", preview: "把零碎的 commit & TODO 列表整理为周报…", application: "通用", tag: "report")
    ]
}

// MARK: - Settings

struct SettingsDashboard: View {
    let themeFamily: AppThemeFamily
    @Binding var themeMode: AppThemeMode

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ModuleHeader(title: "系统设置", subtitle: "通用偏好与数据管理")
            HStack(alignment: .top, spacing: 18) {
                AppearanceSettingsCard(themeFamily: themeFamily, themeMode: $themeMode)
                DataSettingsCard()
            }
            AboutCard()
        }
    }
}

private struct AppearanceSettingsCard: View {
    let themeFamily: AppThemeFamily
    @Binding var themeMode: AppThemeMode

    var body: some View {
        NativeLiquidGlassCard(tint: .blue, cornerRadius: 23) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("外观").font(.system(size: 16, weight: .bold)).foregroundStyle(Color.slate900)
                    Spacer()
                    Text("\(themeFamily.displayName) 主题")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.slate600)
                }
                HStack(spacing: 10) {
                    ForEach(AppThemeMode.allCases) { mode in
                        AppearanceChoice(mode: mode, active: themeMode == mode) {
                            withAnimation(.easeOut(duration: 0.20)) {
                                themeMode = mode
                            }
                        }
                    }
                }
                SettingsRow(title: "开机启动") { VisualToggle(enabled: true) }
                SettingsRow(title: "最小化到托盘") { VisualToggle(enabled: true) }
                SettingsRow(title: "启用胶片颗粒") { VisualToggle(enabled: false) }
                SettingsRow(title: "启用扫描线纹理") { VisualToggle(enabled: true) }
            }
            .padding(19)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
    }
}

private struct AppearanceChoice: View {
    let mode: AppThemeMode
    let active: Bool
    let action: () -> Void

    var body: some View {
        NativeLiquidGlassButton(
            tint: active ? .accentColor : nil,
            cornerRadius: 16,
            action: action
        ) {
            VStack(spacing: 7) {
                Image(systemName: active ? "checkmark.circle.fill" : mode.icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(mode.title).font(.system(size: 11, weight: .bold)).lineLimit(1)
            }
            .foregroundStyle(active ? Color.accentColor : Color.slate700)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
        }
        .accessibilityLabel("\(mode.title)主题")
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

private struct DataSettingsCard: View {
    var body: some View {
        NativeLiquidGlassCard(tint: .purple, cornerRadius: 23) {
            VStack(alignment: .leading, spacing: 15) {
                Text("数据 & 备份").font(.system(size: 16, weight: .bold)).foregroundStyle(Color.slate900)
                SettingsRow(title: "数据库位置") { Text("~/Library/zhz-switch").font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.slate600) }
                SettingsRow(title: "自动备份") { VisualToggle(enabled: true) }
                SettingsRow(title: "缓存大小") { Text("142 MB").foregroundStyle(Color.slate700) }
                HStack(spacing: 8) {
                    HeaderButton(title: "立即备份", icon: "externaldrive", usesLiquidGlass: true)
                    HeaderButton(title: "恢复", icon: "arrow.counterclockwise", usesLiquidGlass: true)
                    HeaderButton(title: "清缓存", icon: "trash", usesLiquidGlass: true)
                }
                .padding(.top, 3)
                Spacer()
            }
            .padding(19)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
    }
}

private struct SettingsRow<Trailing: View>: View {
    let title: String
    @ViewBuilder let trailing: Trailing
    var body: some View {
        NativeLiquidGlassCard(cornerRadius: 15, fillsAvailableSpace: false) {
            HStack {
                Text(title).fontWeight(.medium).foregroundStyle(Color.slate800)
                Spacer()
                trailing
            }
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity, minHeight: 50)
        }
    }
}

private struct AboutCard: View {
    var body: some View {
        NativeLiquidGlassCard(cornerRadius: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("关于 zhz-switch").font(.system(size: 16, weight: .bold)).foregroundStyle(Color.slate900)
                    Text("版本 1.2.6 · macOS Sonoma · MIT License").font(.system(size: 12)).foregroundStyle(Color.slate600)
                }
                Spacer()
                HeaderButton(title: "检查更新", icon: "arrow.clockwise", usesLiquidGlass: true)
                HeaderButton(title: "贡献者", icon: "person.2", usesLiquidGlass: true)
            }
            .padding(.horizontal, 19)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 92)
    }
}
