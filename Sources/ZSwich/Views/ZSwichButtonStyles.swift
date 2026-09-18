import SwiftUI

struct ZSwichPrimaryButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration, compact: compact)
    }
}

private struct PrimaryButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let compact: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .font(compact ? .caption.weight(.semibold) : .callout.weight(.semibold))
            .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.48))
            .padding(.horizontal, compact ? 12 : 16)
            .frame(height: compact ? 30 : 38)
            .background {
                ZStack {
                    LinearGradient(
                        colors: [
                            ZSwichTheme.accent.opacity(isHovered ? 1 : 0.88),
                            Color.purple.opacity(isHovered ? 0.92 : 0.74)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    LinearGradient(
                        colors: [.clear, .white.opacity(0.30), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 54)
                    .rotationEffect(.degrees(-18))
                    .offset(x: isHovered ? 100 : -100)
                }
            }
            .clipShape(.rect(cornerRadius: compact ? 8 : 11))
            .overlay {
                RoundedRectangle(cornerRadius: compact ? 8 : 11)
                    .stroke(.white.opacity(isHovered ? 0.28 : 0.14), lineWidth: 1)
            }
            .shadow(
                color: ZSwichTheme.accent.opacity(isEnabled ? (isHovered ? 0.42 : 0.25) : 0),
                radius: isHovered ? 13 : 8,
                y: isHovered ? 5 : 3
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovered ? 1.025 : 1))
            .opacity(isEnabled ? 1 : 0.72)
            .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: configuration.isPressed)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

struct ZSwichSecondaryButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        SecondaryButtonBody(configuration: configuration, compact: compact)
    }
}

private struct SecondaryButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let compact: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .font(compact ? .caption.weight(.medium) : .callout.weight(.medium))
            .foregroundStyle(.white.opacity(isEnabled ? (isHovered ? 0.96 : 0.78) : 0.38))
            .padding(.horizontal, compact ? 11 : 14)
            .frame(height: compact ? 30 : 36)
            .background(
                LinearGradient(
                    colors: [
                        .white.opacity(isHovered ? 0.13 : 0.075),
                        ZSwichTheme.accent.opacity(isHovered ? 0.10 : 0.035)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: .rect(cornerRadius: compact ? 8 : 10)
            )
            .overlay {
                RoundedRectangle(cornerRadius: compact ? 8 : 10)
                    .stroke(.white.opacity(isHovered ? 0.19 : 0.10), lineWidth: 1)
            }
            .shadow(color: .black.opacity(isHovered ? 0.18 : 0.10), radius: 7, y: 3)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(isEnabled ? 1 : 0.72)
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: configuration.isPressed)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

/// 中性图标按钮（行内刷新额度）。尺寸与反馈必须和 ZSwichDangerIconButtonStyle 一致，
/// 否则同一行里的图标按钮会大小不一、悬停手感不同。
struct ZSwichNeutralIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        NeutralIconButtonBody(configuration: configuration)
    }
}

private struct NeutralIconButtonBody: View {
    let configuration: ButtonStyleConfiguration

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .font(.callout)
            .foregroundStyle(
                isEnabled
                    ? Color.white.opacity(isHovered ? 0.95 : 0.55)
                    : Color.white.opacity(0.18)
            )
            // 旋转必须在 frame/background 之前，只转图标；放在后面会连底色方框一起转。
            .rotationEffect(.degrees(isHovered && isEnabled && !reduceMotion ? -8 : 0))
            .frame(width: 30, height: 30)
            .background(
                ZSwichTheme.accent.opacity(isEnabled && isHovered ? 0.16 : 0),
                in: .rect(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ZSwichTheme.accent.opacity(isEnabled && isHovered ? 0.30 : 0), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: configuration.isPressed)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

struct ZSwichDangerIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        DangerIconButtonBody(configuration: configuration)
    }
}

private struct DangerIconButtonBody: View {
    let configuration: ButtonStyleConfiguration

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .font(.callout)
            .foregroundStyle(
                isEnabled
                    ? Color.red.opacity(isHovered ? 0.95 : 0.62)
                    : Color.white.opacity(0.18)
            )
            .rotationEffect(.degrees(isHovered && isEnabled && !reduceMotion ? 2 : 0))
            .frame(width: 30, height: 30)
            .background(
                Color.red.opacity(isEnabled && isHovered ? 0.13 : 0),
                in: .rect(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red.opacity(isEnabled && isHovered ? 0.20 : 0), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: configuration.isPressed)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

struct ZSwichCurrentAccountButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.medium))
            .foregroundStyle(.white.opacity(0.48))
            .padding(.horizontal, 11)
            .frame(height: 30)
            .background(.white.opacity(0.055), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.07), lineWidth: 1)
            }
    }
}
