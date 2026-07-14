import AppKit
import SwiftUI

struct GlassCard<Content: View>: View {
    var tint: Color = .white
    var cornerRadius: CGFloat = 24
    var showsBackgroundGradient = true
    var isHoverEffectEnabled = false
    var fillsAvailableSpace = true
    @ViewBuilder let content: Content
    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appThemeFamily) private var themeFamily

    var body: some View {
        let palette = AppThemePalette.resolve(family: themeFamily, colorScheme: colorScheme)

        content
            .frame(
                maxWidth: fillsAvailableSpace ? .infinity : nil,
                maxHeight: fillsAvailableSpace ? .infinity : nil,
                alignment: .topLeading
            )
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        if showsBackgroundGradient {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [palette.glassHighlight, tint.opacity(palette.tintOpacity), palette.glassShadow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
            }
            .overlay {
                RefractionHighlights(cornerRadius: cornerRadius)
            }
            .overlay {
                ScanlineTexture()
                    .blendMode(.overlay)
                    .opacity(0.34)
            }
            .overlay {
                AnimatedGlassEffects(
                    isActive: isHoverEffectEnabled && isHovered,
                    reduceMotion: reduceMotion
                )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(colors: palette.glassBorder, startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(isHoverEffectEnabled && isHovered ? 1.004 : 1)
            .animation(.easeOut(duration: 0.24), value: isHovered)
            .onHover { isHovered = isHoverEffectEnabled && $0 }
    }
}

private struct RefractionHighlights: View {
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.82), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                    Spacer()
                }

                HStack(spacing: 0) {
                    LinearGradient(
                        colors: [.white.opacity(0.62), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: 1)
                    Spacer()
                }

                Circle()
                    .fill(.white.opacity(0.30))
                    .frame(width: min(proxy.size.width, 160), height: min(proxy.size.width, 160))
                    .blur(radius: 34)
                    .position(x: 18, y: 12)

                Circle()
                    .fill(.white.opacity(0.11))
                    .frame(width: 190, height: 190)
                    .blur(radius: 42)
                    .position(x: proxy.size.width - 8, y: proxy.size.height + 12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }
}

private struct ScanlineTexture: View {
    var body: some View {
        Canvas { context, size in
            for y in stride(from: CGFloat.zero, through: size.height, by: 3) {
                context.fill(
                    Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                    with: .color(.white.opacity(0.12))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

private struct AnimatedGlassEffects: View {
    let isActive: Bool
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive || reduceMotion)) { timeline in
            GeometryReader { proxy in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let sheenProgress = reduceMotion ? 0.45 : time.truncatingRemainder(dividingBy: 3.2) / 3.2
                let auroraAngle = reduceMotion ? 18 : time.truncatingRemainder(dividingBy: 7) / 7 * 360

                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [
                                    Color.cyan.opacity(0.34),
                                    Color.purple.opacity(0.30),
                                    Color.pink.opacity(0.30),
                                    Color.mint.opacity(0.30),
                                    Color.cyan.opacity(0.34)
                                ],
                                center: .center
                            )
                        )
                        .frame(width: proxy.size.width * 1.35, height: proxy.size.width * 1.35)
                        .rotationEffect(.degrees(auroraAngle))
                        .scaleEffect(isActive ? 1.18 : 1.08)
                        .offset(x: isActive ? proxy.size.width * 0.05 : 0, y: isActive ? -proxy.size.height * 0.04 : 0)
                        .blur(radius: 38)
                        .blendMode(.screen)
                        .opacity(isActive ? 0.72 : 0)

                    LinearGradient(
                        colors: [.clear, .white.opacity(0.58), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.48, height: proxy.size.height * 1.8)
                    .rotationEffect(.degrees(20))
                    .blur(radius: 6)
                    .blendMode(.overlay)
                    .offset(x: -proxy.size.width * 0.72 + proxy.size.width * 2.05 * sheenProgress)
                    .opacity(isActive && !reduceMotion ? 0.88 : 0)
                }
                .animation(.easeInOut(duration: 0.7), value: isActive)
            }
        }
        .allowsHitTesting(false)
    }
}

struct RotatingActiveBorder: View {
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let angle = reduceMotion ? 0 : time.truncatingRemainder(dividingBy: 3) / 3 * 360

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: 0x38BDF8),
                            Color(hex: 0x818CF8),
                            Color(hex: 0xF472B6),
                            Color(hex: 0x34D399),
                            Color(hex: 0x38BDF8)
                        ],
                        center: .center,
                        startAngle: .degrees(angle),
                        endAngle: .degrees(angle + 360)
                    ),
                    lineWidth: 2
                )
                .shadow(color: .purple.opacity(0.34), radius: 9)
        }
        .allowsHitTesting(false)
    }
}

extension Color {
    static let slate500 = adaptive(light: 0x64748B, dark: 0x94A3B8)
    static let slate600 = adaptive(light: 0x475569, dark: 0xCBD5E1)
    static let slate700 = adaptive(light: 0x334155, dark: 0xD7E0EC)
    static let slate800 = adaptive(light: 0x1E293B, dark: 0xE2E8F0)
    static let slate900 = adaptive(light: 0x0F172A, dark: 0xF8FAFC)
    static let themeSurface = adaptive(light: 0xFFFFFF, dark: 0x94A3B8)
    static let themeBorder = adaptive(light: 0xFFFFFF, dark: 0xCBD5E1)

    static func adaptive(light: UInt, dark: UInt) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                let hex = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
                return NSColor(
                    srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                    green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255,
                    alpha: 1
                )
            }
        )
    }

    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

struct AppThemePalette {
    let background: [Color]
    let hemisphereColors: [Color]
    let hemisphereRim: [Color]
    let hemisphereGlow: Color
    let glassHighlight: Color
    let glassShadow: Color
    let glassBorder: [Color]
    let tintOpacity: Double
    let noiseOpacity: Double

    static func resolve(family: AppThemeFamily, colorScheme: ColorScheme) -> AppThemePalette {
        switch family {
        case .codex:
            codex(colorScheme: colorScheme)
        case .claude:
            claude(colorScheme: colorScheme)
        }
    }

    private static func codex(colorScheme: ColorScheme) -> AppThemePalette {
        if colorScheme == .dark {
            return AppThemePalette(
                background: [Color(hex: 0x020308), Color(hex: 0x070A13), Color(hex: 0x110817)],
                hemisphereColors: [Color(hex: 0x2413A8), Color(hex: 0x1736E8), Color(hex: 0x6E1EFF), Color(hex: 0xD02EFF)],
                hemisphereRim: [Color(hex: 0xF1FFB6), .cyan, Color(hex: 0x477BFF), .purple, .pink],
                hemisphereGlow: Color(hex: 0x6B2CFF),
                glassHighlight: .white.opacity(0.10),
                glassShadow: .black.opacity(0.08),
                glassBorder: [.white.opacity(0.24), .white.opacity(0.07)],
                tintOpacity: 0.12,
                noiseOpacity: 0.07
            )
        }

        return AppThemePalette(
            background: [Color(hex: 0xCCD8E8), Color(hex: 0xD8CFE4), Color(hex: 0xE5D2DB)],
            hemisphereColors: [Color(hex: 0x5068E8).opacity(0.48), Color(hex: 0x7860E9).opacity(0.44), Color(hex: 0xBC59D5).opacity(0.40)],
            hemisphereRim: [.white.opacity(0.70), .cyan.opacity(0.55), .purple.opacity(0.52), .pink.opacity(0.46)],
            hemisphereGlow: .purple.opacity(0.34),
            glassHighlight: .white.opacity(0.36),
            glassShadow: .white.opacity(0.10),
            glassBorder: [.white.opacity(0.72), .white.opacity(0.20)],
            tintOpacity: 0.16,
            noiseOpacity: 0.10
        )
    }

    private static func claude(colorScheme: ColorScheme) -> AppThemePalette {
        if colorScheme == .dark {
            return AppThemePalette(
                background: [Color(hex: 0x070403), Color(hex: 0x100907), Color(hex: 0x150811)],
                hemisphereColors: [Color(hex: 0x7C2D20), Color(hex: 0xD85B39), Color(hex: 0xC24C70), Color(hex: 0x7133B8)],
                hemisphereRim: [Color(hex: 0xFFE8B5), Color(hex: 0xFF9A62), .pink, .purple],
                hemisphereGlow: Color(hex: 0xD85B68),
                glassHighlight: .white.opacity(0.10),
                glassShadow: .black.opacity(0.09),
                glassBorder: [.white.opacity(0.22), .white.opacity(0.06)],
                tintOpacity: 0.12,
                noiseOpacity: 0.07
            )
        }

        return AppThemePalette(
            background: [Color(hex: 0xDCCBC1), Color(hex: 0xE5D8CC), Color(hex: 0xDACED3)],
            hemisphereColors: [Color(hex: 0xC96749).opacity(0.46), Color(hex: 0xDF8A5E).opacity(0.42), Color(hex: 0xB65A86).opacity(0.36)],
            hemisphereRim: [.white.opacity(0.72), Color(hex: 0xFFB178).opacity(0.62), .pink.opacity(0.46), .purple.opacity(0.40)],
            hemisphereGlow: Color(hex: 0xD97757).opacity(0.30),
            glassHighlight: .white.opacity(0.38),
            glassShadow: .white.opacity(0.10),
            glassBorder: [.white.opacity(0.72), .white.opacity(0.20)],
            tintOpacity: 0.16,
            noiseOpacity: 0.10
        )
    }
}
