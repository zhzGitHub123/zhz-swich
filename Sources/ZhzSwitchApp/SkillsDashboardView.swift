import AppKit
import SwiftUI

struct SkillsDashboard: View {
    let family: AppThemeFamily
    @ObservedObject var store: SkillListStore

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .bottom, spacing: 10) {
                Spacer(minLength: 12)
                SkillSearchField(text: $store.searchText)
                HeaderButton(
                    title: "安装",
                    icon: "plus",
                    emphasized: true,
                    usesLiquidGlass: true
                ) {
                    chooseSkillDirectory()
                }
            }

            SkillSummaryCard(family: family, store: store)

            if let message = store.errorMessage {
                SkillErrorBanner(message: message, onDismiss: store.clearError)
            }

            if store.filteredSkills.isEmpty {
                SkillEmptyState(hasQuery: !store.searchText.isEmpty)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 220, maximum: 310), spacing: 18)],
                    spacing: 18
                ) {
                    ForEach(Array(store.filteredSkills.enumerated()), id: \.element.id) { index, skill in
                        SkillCard(
                            skill: skill,
                            tint: skillTint(for: skill, index: index),
                            onToggle: { store.toggle(skill) }
                        )
                    }
                }
            }
        }
        .onAppear {
            store.load(target: target)
        }
        .onChange(of: family) { _, _ in
            store.load(target: target)
        }
    }

    private var target: TargetApp {
        switch family {
        case .codex: .codex
        case .claude: .claude
        }
    }

    private func skillTint(for skill: SkillRecord, index: Int) -> Color {
        if !skill.isEnabled { return .gray }
        if skill.isReadOnly { return .orange }
        return index.isMultiple(of: 2) ? .white : .blue
    }

    private func chooseSkillDirectory() {
        let panel = NSOpenPanel()
        panel.title = "安装技能"
        panel.message = "请选择包含 SKILL.md 的技能目录"
        panel.prompt = "安装"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let directory = panel.url else { return }
        store.install(from: directory)
    }
}

private struct SkillSearchField: View {
    @Binding var text: String

    var body: some View {
        NativeLiquidGlassCard(cornerRadius: 13, fillsAvailableSpace: false) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                TextField("搜索技能…", text: $text)
                    .textFieldStyle(.plain)
                if !text.isEmpty {
                    NativeLiquidGlassButton(cornerRadius: 9, action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("清空搜索")
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.slate600)
            .padding(.horizontal, 12)
            .frame(width: 190)
            .frame(minHeight: 36)
        }
    }

    private func clearSearch() {
        text = ""
    }
}

private struct SkillSummaryCard: View {
    let family: AppThemeFamily
    @ObservedObject var store: SkillListStore

    var body: some View {
        NativeLiquidGlassCard(tint: .orange, cornerRadius: 24) {
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("实时数据")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.slate600)
                    Text("\(family.displayName) 已发现 \(store.skills.count) 个技能")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.slate900)
                    Text(store.activeDirectory().path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.slate600)
                        .lineLimit(1)
                }
                Spacer()
                HStack(spacing: 14) {
                    SkillMetric(title: "已启用", value: store.enabledCount, color: .green)
                    SkillMetric(title: "已停用", value: store.disabledCount, color: .orange)
                    if store.systemCount > 0 {
                        SkillMetric(title: "系统", value: store.systemCount, color: .blue)
                    }
                    HeaderButton(
                        title: "刷新",
                        icon: "arrow.clockwise",
                        usesLiquidGlass: true
                    ) {
                        store.refresh()
                    }
                }
            }
            .padding(21)
        }
        .frame(height: 122)
    }
}

private struct SkillMetric: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.slate600)
        }
        .frame(minWidth: 42)
    }
}

private struct SkillErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        NativeLiquidGlassCard(tint: .red, cornerRadius: 18) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.slate700)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                NativeLiquidGlassButton(tint: .red, cornerRadius: 9, action: onDismiss) {
                    Image(systemName: "xmark")
                        .frame(width: 28, height: 28)
                }
                .accessibilityLabel("关闭提示")
            }
            .padding(14)
        }
    }
}

private struct SkillEmptyState: View {
    let hasQuery: Bool

    var body: some View {
        NativeLiquidGlassCard(tint: .orange, cornerRadius: 22) {
            VStack(spacing: 10) {
                Image(systemName: hasQuery ? "magnifyingglass" : "sparkles")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.orange)
                Text(hasQuery ? "没有匹配的技能" : "尚未安装本地技能")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.slate900)
                Text(hasQuery ? "换个关键词试试" : "点击右上角“安装”，选择包含 SKILL.md 的目录")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.slate600)
            }
            .frame(maxWidth: .infinity, minHeight: 150)
        }
    }
}

private struct SkillCard: View {
    let skill: SkillRecord
    let tint: Color
    let onToggle: () -> Void

    var body: some View {
        NativeLiquidGlassCard(tint: tint, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.55), .orange.opacity(0.72)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Image(systemName: skill.isReadOnly ? "lock.fill" : "sparkles")
                            .foregroundStyle(.white)
                    }
                    .frame(width: 44, height: 44)
                    Spacer()
                    toggle
                }

                Text(skill.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.slate900)
                    .lineLimit(1)
                    .padding(.top, 12)

                Text(skill.summary)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.slate600)
                    .lineLimit(3)
                    .padding(.top, 4)

                Spacer(minLength: 10)

                HStack(spacing: 6) {
                    Label(sourceTitle, systemImage: sourceIcon)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(skill.isEnabled ? "已启用" : "已停用")
                        .foregroundStyle(skill.isEnabled ? Color.green : Color.orange)
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.slate700)
            }
            .padding(16)
        }
        .frame(height: 190)
        .help(skill.location.path)
    }

    @ViewBuilder
    private var toggle: some View {
        if skill.isReadOnly {
            VisualToggle(enabled: true)
                .opacity(0.62)
                .help("系统技能由客户端管理")
        } else {
            Button(action: onToggle) {
                VisualToggle(enabled: skill.isEnabled)
            }
            .buttonStyle(.plain)
            .interactivePointerStyle()
            .accessibilityLabel("\(skill.isEnabled ? "停用" : "启用")技能 \(skill.name)")
        }
    }

    private var sourceTitle: String {
        switch skill.origin {
        case .system: "系统技能"
        case .local: "本地目录"
        case .linked: "共享链接"
        }
    }

    private var sourceIcon: String {
        switch skill.origin {
        case .system: "gearshape.fill"
        case .local: "folder.fill"
        case .linked: "link"
        }
    }
}
