import AppKit
import SwiftUI

extension View {
    @ViewBuilder
    func interactivePointerStyle() -> some View {
        if #available(macOS 15.0, *) {
            pointerStyle(.link)
        } else {
            onHover { hovering in
                DispatchQueue.main.async {
                    hovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                }
            }
        }
    }
}

struct ModuleAction: Identifiable {
    let title: String
    let icon: String
    var emphasized = false
    var id: String { title }
}

struct ProviderFamilySwitcher: View {
    @Binding var selection: AppThemeFamily

    var body: some View {
        HStack(spacing: 10) {
            ForEach(AppThemeFamily.allCases) { family in
                ProviderFamilyButton(
                    family: family,
                    isSelected: selection == family
                ) {
                    selection = family
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 52)
    }
}

private struct ProviderFamilyButton: View {
    let family: AppThemeFamily
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ProviderFamilyGlyph(family: family, isSelected: isSelected)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(isSelected ? family.accentColor.opacity(0.14) : Color.themeSurface.opacity(isHovered ? 0.34 : 0.20))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(isSelected ? family.accentColor.opacity(0.50) : Color.themeBorder.opacity(0.20), lineWidth: 1)
            }
            .offset(y: isHovered && !reduceMotion ? -1 : 0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .interactivePointerStyle()
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHovered)
        .accessibilityLabel("切换到 \(family.displayName) 大类")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .help(family.displayName)
    }
}

private struct ProviderFamilyGlyph: View {
    let family: AppThemeFamily
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(family.accentColor.opacity(isSelected ? 0.20 : 0.11))

            switch family {
            case .codex:
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 16, weight: .bold))
            case .claude:
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .semibold))
            }
        }
        .foregroundStyle(family.accentColor)
        .frame(width: 38, height: 38)
    }
}

struct ModuleHeader: View {
    let title: String
    let subtitle: String
    var eyebrow = "模块"
    var actions: [ModuleAction] = []
    var usesLiquidGlassButtons = false
    var onAction: ((ModuleAction) -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                Text(title)
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.98))
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.82))
            }
            .shadow(color: Color.black.opacity(0.48), radius: 3, y: 1)
            Spacer(minLength: 12)
            HStack(spacing: 8) {
                ForEach(actions) { action in
                    HeaderButton(
                        title: action.title,
                        icon: action.icon,
                        emphasized: action.emphasized,
                        usesLiquidGlass: usesLiquidGlassButtons,
                        action: onAction.map { handler in { handler(action) } }
                    )
                }
            }
        }
    }
}

struct HeaderButton: View {
    let title: String
    let icon: String
    var emphasized = false
    var usesLiquidGlass = false
    var action: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    @ViewBuilder
    var body: some View {
        if let action {
            if usesLiquidGlass {
                NativeLiquidGlassButton(
                    tint: emphasized ? .purple : nil,
                    cornerRadius: 13,
                    action: action
                ) {
                    content
                }
            } else {
                Button(action: action) {
                    content
                }
                .buttonStyle(.plain)
                .interactivePointerStyle()
            }
        } else if usesLiquidGlass {
            NativeLiquidGlassCard(
                tint: emphasized ? .purple : nil,
                cornerRadius: 13,
                fillsAvailableSpace: false
            ) {
                content
            }
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(Color.slate800)
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 12)
        .frame(minWidth: 74, minHeight: 36)
        .background {
            if !usesLiquidGlass {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(
                        emphasized
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    .cyan.opacity(isHovered ? 0.62 : 0.50),
                                    .purple.opacity(isHovered ? 0.46 : 0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(Color.themeSurface.opacity(surfaceOpacity))
                    )
            }
        }
        .overlay {
            if !usesLiquidGlass {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.themeBorder.opacity(borderLeadingOpacity),
                                Color.themeBorder.opacity(isHovered ? 0.12 : 0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            }
        }
        .offset(y: usesLiquidGlass ? 0 : isHovered ? -1 : 0)
        .shadow(
            color: usesLiquidGlass
                ? .clear
                : colorScheme == .dark
                    ? .black.opacity(isHovered ? 0.22 : 0.14)
                    : .indigo.opacity(isHovered ? 0.16 : 0.10),
            radius: usesLiquidGlass ? 0 : isHovered ? 10 : 7,
            y: usesLiquidGlass ? 0 : isHovered ? 5 : 3
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.18), value: isHovered)
    }

    private var surfaceOpacity: Double {
        if colorScheme == .dark {
            return isHovered ? 0.34 : 0.26
        }
        return isHovered ? 0.52 : 0.38
    }

    private var borderLeadingOpacity: Double {
        if emphasized {
            return isHovered ? 0.42 : 0.32
        }
        if colorScheme == .dark {
            return isHovered ? 0.26 : 0.18
        }
        return isHovered ? 0.34 : 0.26
    }
}

struct VisualToggle: View {
    let enabled: Bool

    var body: some View {
        Capsule()
            .fill(
                enabled
                ? AnyShapeStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))
                : AnyShapeStyle(Color.slate500.opacity(0.24))
            )
            .frame(width: 42, height: 24)
            .overlay(alignment: enabled ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .frame(width: 18, height: 18)
                    .padding(3)
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            }
    }
}

struct CompactIconButton: View {
    let icon: String
    var usesLiquidGlass = false

    @ViewBuilder
    var body: some View {
        if usesLiquidGlass {
            NativeLiquidGlassCard(cornerRadius: 10, fillsAvailableSpace: false) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.slate700)
                    .frame(width: 29, height: 29)
            }
        } else {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.slate700)
                .frame(width: 29, height: 29)
                .background(
                    Color.themeSurface.opacity(0.36),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
        }
    }
}
