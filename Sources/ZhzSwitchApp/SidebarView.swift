import AppKit
import SwiftUI

struct SidebarView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selection: ModuleKey
    @Binding var themeFamily: AppThemeFamily
    @State private var hoveredItem: ModuleKey?

    private let items = [
        SidebarItem(key: .dashboard, title: "仪表台", icon: "rectangle.3.group.fill", tint: .cyan),
        SidebarItem(key: .providers, title: "提供商", icon: "shippingbox.fill", tint: .blue, badge: "12"),
        SidebarItem(key: .mcp, title: "MCP 服务器", icon: "server.rack", tint: .purple, badge: "8"),
        SidebarItem(key: .prompts, title: "提示词", icon: "text.bubble.fill", tint: .pink),
        SidebarItem(key: .skills, title: "技能", icon: "sparkles", tint: .orange, badge: "新"),
        SidebarItem(key: .usage, title: "使用统计", icon: "chart.bar.fill", tint: .green),
        SidebarItem(key: .settings, title: "设置", icon: "gearshape.fill", tint: .gray)
    ]

    var body: some View {
        NativeLiquidGlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 0) {
                SidebarBrandHeader()
                    .padding(.bottom, 14)

                ProviderFamilySwitcher(selection: $themeFamily)

                VStack(spacing: 6) {
                    ForEach(items) { item in
                        Button {
                            guard selection != item.key else { return }
                            if reduceMotion {
                                selection = item.key
                            } else {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    selection = item.key
                                }
                            }
                        } label: {
                            SidebarRow(
                                item: item,
                                selected: selection == item.key,
                                hovered: hoveredItem == item.key
                            )
                        }
                        .buttonStyle(SidebarButtonStyle())
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .accessibilityAddTraits(selection == item.key ? .isSelected : [])
                        .onContinuousHover { phase in
                            switch phase {
                            case .active:
                                hoveredItem = item.key
                                NSCursor.pointingHand.set()
                            case .ended:
                                if hoveredItem == item.key {
                                    hoveredItem = nil
                                }
                                NSCursor.arrow.set()
                            }
                        }
                    }
                }
                .padding(.top, 22)

                Spacer(minLength: 16)
                SyncStatusCard()
            }
            .padding(18)
        }
    }
}

private struct SidebarBrandHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Image("AppLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.themeBorder.opacity(0.55), lineWidth: 1)
                }
                .shadow(color: .orange.opacity(0.16), radius: 9, y: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text("zhz swich")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.slate900)
                Text("供应商切换器")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.slate600)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.themeSurface.opacity(0.32), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(Color.themeBorder.opacity(0.36), lineWidth: 1)
        }
    }
}

private struct SidebarItem: Identifiable {
    let key: ModuleKey
    let title: String
    let icon: String
    let tint: Color
    var badge: String? = nil
    var id: ModuleKey { key }
}

private struct SidebarRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let item: SidebarItem
    let selected: Bool
    let hovered: Bool

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(item.tint.opacity(selected ? 0.25 : hovered ? 0.20 : 0.14))
                Image(systemName: item.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.slate700)
            }
            .frame(width: 30, height: 30)

            Text(item.title)
                .fontWeight(selected ? .semibold : .medium)
                .foregroundStyle(Color.slate800)
            Spacer()
            if let badge = item.badge {
                Text(badge)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.slate700)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.themeSurface.opacity(0.5), in: Capsule())
                    .overlay { Capsule().stroke(Color.themeBorder.opacity(0.7), lineWidth: 1) }
            }
        }
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity, minHeight: 48)
        .contentShape(Rectangle())
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.themeSurface.opacity(selected ? 0.37 : hovered ? 0.24 : 0))
                .shadow(
                    color: selected ? .indigo.opacity(0.08) : .clear,
                    radius: 10,
                    y: 5
                )
        }
        .overlay(alignment: .leading) {
            if selected {
                Capsule()
                    .fill(LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom))
                    .frame(width: 4, height: 24)
                    .offset(x: -9)
                    .shadow(color: .purple.opacity(0.5), radius: 5)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: hovered)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: selected)
    }
}

private struct SidebarButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.10),
                value: configuration.isPressed
            )
    }
}

private struct SyncStatusCard: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient(colors: [.mint, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text("同步正常")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.slate800)
                Text("刚刚完成云端同步")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.slate600)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color.themeBorder.opacity(0.55), lineWidth: 1)
        }
    }
}
