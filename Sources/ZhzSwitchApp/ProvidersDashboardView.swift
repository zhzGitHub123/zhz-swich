import SwiftUI

struct ProvidersDashboard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let family: AppThemeFamily
    @ObservedObject var store: ProviderListStore
    @State private var isAddingProvider = false
    @State private var providerBeingEdited: ProviderProfile?
    @State private var providerPendingDeletion: ProviderProfile?
    private var providers: [ProviderVisual] {
        managedProviders.map(ProviderVisual.init)
    }

    private var managedProviders: [ProviderProfile] {
        store.providers.filter { $0.family == family.rawValue }
    }

    private var featuredProvider: ProviderVisual? {
        providers.first(where: { $0.status == .active }) ?? providers.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ModuleHeader(
                title: "提供商",
                subtitle: "统一管理 \(family.displayName) 的 API 密钥与端点",
                eyebrow: "模块 / Providers / \(family.displayName)",
                actions: [
                    ModuleAction(title: "筛选", icon: "line.3.horizontal.decrease"),
                    ModuleAction(title: "排序", icon: "arrow.up.arrow.down"),
                    ModuleAction(title: "导入", icon: "square.and.arrow.down"),
                    ModuleAction(title: "导出", icon: "square.and.arrow.up"),
                    ModuleAction(title: "新增", icon: "plus", emphasized: true)
                ],
                usesLiquidGlassButtons: true,
                onAction: { action in
                    if action.title == "新增" {
                        isAddingProvider = true
                    }
                }
            )

            if let featuredProvider {
                GeometryReader { proxy in
                    let featuredWidth = max(310, proxy.size.width * 0.41)
                    HStack(alignment: .top, spacing: 18) {
                        FeaturedProviderCard(
                            provider: featuredProvider,
                            onEdit: storedProvider(for: featuredProvider).map { selectedProvider in
                                { providerBeingEdited = selectedProvider }
                            }
                        )
                            .id(featuredProvider.id)
                            .transition(.opacity.combined(with: .scale(scale: 0.985)))
                            .frame(width: featuredWidth)

                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)],
                            spacing: 18
                        ) {
                            ForEach(providers) { provider in
                                ProviderTile(
                                    provider: provider,
                                    canSwitch: storedProvider(for: provider)?.isActive == false,
                                    canEdit: storedProvider(for: provider) != nil,
                                    canDelete: store.providers.contains(where: { $0.id == provider.id }),
                                    onSwitch: {
                                        switchProvider(provider)
                                    },
                                    onEdit: {
                                        providerBeingEdited = storedProvider(for: provider)
                                    },
                                    onDelete: {
                                        providerPendingDeletion = storedProvider(for: provider)
                                    }
                                )
                            }
                        }
                    }
                }
                .frame(height: 516)
            } else {
                NativeLiquidGlassCard(tint: .blue, cornerRadius: 24) {
                    ContentUnavailableView("暂无提供商", systemImage: "shippingbox", description: Text("点击右上角“新增”创建第一个提供商。"))
                        .frame(maxWidth: .infinity, minHeight: 320)
                }
            }
        }
        .animation(
            reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.86),
            value: featuredProvider?.id
        )
        .sheet(isPresented: $isAddingProvider) {
            ProviderEditorView { provider in
                var next = provider
                next.family = family.rawValue
                try store.add(next)
            }
        }
        .sheet(item: $providerBeingEdited) { provider in
            ProviderEditorView(provider: provider) { updatedProvider in
                try store.update(updatedProvider)
            }
        }
        .alert(
            "删除供应商？",
            isPresented: Binding(
                get: { providerPendingDeletion != nil },
                set: { if !$0 { providerPendingDeletion = nil } }
            ),
            presenting: providerPendingDeletion
        ) { provider in
            Button("删除", role: .destructive) {
                delete(provider)
            }
            Button("取消", role: .cancel) {
                providerPendingDeletion = nil
            }
        } message: { provider in
            Text("“\(provider.name)”将从 SwiftData 中永久删除，此操作无法撤销。")
        }
        .alert("提供商数据错误", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.clearError() } }
        )) {
            Button("好", role: .cancel) { store.clearError() }
        } message: {
            Text(store.errorMessage ?? "未知错误")
        }
    }

    private func delete(_ provider: ProviderProfile) {
        providerPendingDeletion = nil
        do {
            try store.delete(provider)
        } catch {
            // ProviderListStore 会保留原数据，并通过 errorMessage 显示失败原因。
        }
    }

    private func storedProvider(for visual: ProviderVisual) -> ProviderProfile? {
        store.providers.first(where: { $0.id == visual.id })
    }

    private func switchProvider(_ visual: ProviderVisual) {
        guard let provider = storedProvider(for: visual), !provider.isActive else { return }
        do {
            try store.setActive(provider)
        } catch {
            // ProviderListStore 会保留原状态，并通过 errorMessage 显示失败原因。
        }
    }
}

private struct FeaturedProviderCard: View {
    let provider: ProviderVisual
    let onEdit: (() -> Void)?

    var body: some View {
        NativeLiquidGlassCard(tint: provider.tint, cornerRadius: 27) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("当前活跃")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.slate600)
                        Text(provider.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.slate900)
                        Text("\(provider.app) · \(provider.model)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.slate600)
                    }
                    Spacer()
                    ProviderGlyph(provider: provider, size: 58)
                }

                HStack(spacing: 10) {
                    MetricCard(label: "今日请求", value: "1,284")
                    MetricCard(label: "Token", value: "342K")
                    MetricCard(label: "成本", value: "$3.21")
                }
                .padding(.top, 26)

                Spacer()

                HStack(spacing: 9) {
                    if let onEdit {
                        HeaderButton(
                            title: "编辑配置",
                            icon: "slider.horizontal.3",
                            usesLiquidGlass: true,
                            action: onEdit
                        )
                    }
                }
            }
            .padding(22)
        }
        .frame(height: 332)
    }
}

private struct MetricCard: View {
    let label: String
    let value: String

    var body: some View {
        NativeLiquidGlassCard(cornerRadius: 16, fillsAvailableSpace: false) {
            VStack(alignment: .leading, spacing: 5) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.slate600)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.slate900)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }
}

private struct ProviderTile: View {
    let provider: ProviderVisual
    let canSwitch: Bool
    let canEdit: Bool
    let canDelete: Bool
    let onSwitch: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        NativeLiquidGlassCard(tint: provider.tint, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    ProviderGlyph(provider: provider, size: 42)
                    Spacer()
                    StatusBadge(status: provider.status)
                }

                Text(provider.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.slate900)
                    .padding(.top, 13)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
                Text(provider.app)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.slate600)
                    .padding(.top, 2)

                Spacer(minLength: 8)
                if provider.status == .active {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("正在使用")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(15)
        }
        .overlay {
            if canSwitch {
                Button(action: onSwitch) {
                    Color.clear
                        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("切换到 \(provider.name)")
                .accessibilityLabel("切换到 \(provider.name)")
            }
        }
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: 6) {
                if canEdit {
                    ProviderTileActionButton(
                        icon: "slider.horizontal.3",
                        help: "编辑配置",
                        accessibilityLabel: "编辑 \(provider.name)",
                        action: onEdit
                    )
                }
                if canDelete {
                    ProviderTileActionButton(
                        icon: "trash",
                        help: "删除供应商",
                        accessibilityLabel: "删除 \(provider.name)",
                        isDestructive: true,
                        action: onDelete
                    )
                }
            }
            .padding(15)
        }
        .overlay {
            if provider.status == .active {
                RotatingActiveBorder(cornerRadius: 22)
            }
        }
        .frame(height: 160)
        .offset(y: isHovered ? -2 : 0)
        .shadow(color: .indigo.opacity(isHovered ? 0.12 : 0), radius: 12, y: 7)
        .animation(.easeOut(duration: 0.22), value: isHovered)
        .onHover { isHovered = $0 }
        .interactivePointerStyle()
    }
}

private struct ProviderTileActionButton: View {
    let icon: String
    let help: String
    let accessibilityLabel: String
    var isDestructive = false
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        NativeLiquidGlassButton(
            tint: isDestructive ? .red : nil,
            cornerRadius: 9,
            action: action
        ) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: 28, height: 28)
                .offset(y: isHovered && !reduceMotion ? -1 : 0)
                .shadow(color: shadowColor, radius: isHovered ? 6 : 0, y: isHovered ? 3 : 0)
        }
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHovered)
        .help(help)
        .accessibilityLabel(accessibilityLabel)
    }

    private var foregroundColor: Color {
        if isDestructive {
            return isHovered ? .white : .red
        }
        return isHovered ? .slate900 : .slate700
    }

    private var shadowColor: Color {
        isDestructive ? Color.red.opacity(0.25) : Color.indigo.opacity(0.16)
    }
}

private struct ProviderGlyph: View {
    let provider: ProviderVisual
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(LinearGradient(colors: provider.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            Text(provider.glyph)
                .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .stroke(Color.themeBorder.opacity(0.42), lineWidth: 1)
        }
        .shadow(color: provider.colors.last?.opacity(0.28) ?? .clear, radius: 10, y: 6)
    }
}

private struct StatusBadge: View {
    let status: ProviderStatus

    var body: some View {
        Text(status.title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(status.foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.background, in: Capsule())
            .overlay { Capsule().stroke(status.border, lineWidth: 1) }
    }
}

private enum ProviderStatus {
    case active
    case idle
    case warning

    var title: String {
        switch self {
        case .active: "活跃"
        case .idle: "待机"
        case .warning: "异常"
        }
    }

    var foreground: Color {
        switch self {
        case .active: Color.adaptive(light: 0x047857, dark: 0x6EE7B7)
        case .idle: Color.slate700
        case .warning: Color.adaptive(light: 0xB45309, dark: 0xFCD34D)
        }
    }

    var background: Color {
        switch self {
        case .active: .green.opacity(0.18)
        case .idle: .white.opacity(0.45)
        case .warning: .yellow.opacity(0.22)
        }
    }

    var border: Color {
        switch self {
        case .active: .green.opacity(0.32)
        case .idle: .white.opacity(0.65)
        case .warning: .orange.opacity(0.32)
        }
    }
}

private struct ProviderVisual: Identifiable {
    let id: UUID
    let name: String
    let app: String
    let status: ProviderStatus
    let colors: [Color]
    let tint: Color
    let glyph: String
    let model: String

    init(profile: ProviderProfile) {
        id = profile.id
        name = profile.name
        app = profile.note.isEmpty ? "自定义提供商" : profile.note
        status = profile.isActive ? .active : (profile.isValidURL ? .idle : .warning)
        colors = [Color(hex: 0x7DD3FC), Color(hex: 0x6366F1)]
        tint = .white
        glyph = profile.avatarText
        model = URLComponents(string: profile.normalizedBaseURL)?.host ?? profile.normalizedBaseURL
    }
}
