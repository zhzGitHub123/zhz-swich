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
        HStack(spacing: 14) {
            ForEach(AppThemeFamily.allCases) { family in
                ProviderFamilyButton(
                    family: family,
                    isSelected: selection == family
                ) {
                    selection = family
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60)
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
            ZStack {
                Circle()
                    .fill(buttonFill)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.24 : 0.15),
                                Color.white.opacity(0.02),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .strokeBorder(Color.white.opacity(isSelected ? 0.28 : 0.12), lineWidth: 1)
                    .padding(2)

                ProviderFamilyGlyph(family: family, isSelected: isSelected)
            }
            .frame(width: 52, height: 52)
            .overlay {
                Circle()
                    .strokeBorder(outerBorder, lineWidth: isSelected ? 1.5 : 1)
            }
            .shadow(
                color: isSelected
                    ? family.accentColor.opacity(0.34)
                    : Color.black.opacity(isHovered ? 0.14 : 0.08),
                radius: isSelected ? 12 : 7,
                y: isSelected ? 5 : 3
            )
            .scaleEffect(isHovered && !reduceMotion ? 1.035 : 1)
            .offset(y: isHovered && !reduceMotion ? -1 : 0)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .onHover { isHovered = $0 }
        .interactivePointerStyle()
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHovered)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.20), value: isSelected)
        .accessibilityLabel("切换到 \(family.displayName) 大类")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .help(family.displayName)
    }

    private var buttonFill: some ShapeStyle {
        LinearGradient(
            colors: isSelected
                ? [family.accentColor.opacity(0.82), family.accentColor.opacity(0.48)]
                : [Color.themeSurface.opacity(isHovered ? 0.48 : 0.34), Color.themeSurface.opacity(0.16)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var outerBorder: some ShapeStyle {
        LinearGradient(
            colors: isSelected
                ? [Color.white.opacity(0.58), family.accentColor.opacity(0.88), family.accentColor.opacity(0.30)]
                : [Color.white.opacity(0.20), Color.themeBorder.opacity(0.36)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ProviderFamilyGlyph: View {
    let family: AppThemeFamily
    let isSelected: Bool

    var body: some View {
        Image(logoAssetName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(isSelected ? Color.white : family.accentColor)
            .frame(width: family == .codex ? 25 : 27, height: family == .codex ? 25 : 27)
            .shadow(color: Color.black.opacity(isSelected ? 0.18 : 0), radius: 2, y: 1)
            .accessibilityHidden(true)
    }

    private var logoAssetName: String {
        switch family {
        case .codex: "GPTLogo"
        case .claude: "ClaudeLogo"
        }
    }
}

struct ModuleActionsBar: View {
    let actions: [ModuleAction]
    var usesLiquidGlassButtons = false
    var onAction: ((ModuleAction) -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
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
    var accessibilityLabel = "状态"

    @Environment(\.appThemeFamily) private var themeFamily
    @State private var isOn: Bool

    init(enabled: Bool, accessibilityLabel: String = "状态") {
        self.enabled = enabled
        self.accessibilityLabel = accessibilityLabel
        _isOn = State(initialValue: enabled)
    }

    var body: some View {
        Toggle(accessibilityLabel, isOn: $isOn)
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(themeFamily.accentColor)
            .padding(6)
            .contentShape(Rectangle())
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(isOn ? "开启" : "关闭")
            .onChange(of: enabled) { _, newValue in
                isOn = newValue
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
