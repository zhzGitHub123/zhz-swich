import AppKit
import SwiftUI

enum AppThemeFamily: String, CaseIterable, Identifiable {
    case codex
    case claude

    var id: Self { self }

    var displayName: String {
        switch self {
        case .codex: "Codex"
        case .claude: "Claude"
        }
    }

    var subtitle: String {
        switch self {
        case .codex: "OpenAI"
        case .claude: "Anthropic"
        }
    }

    var accentColor: Color {
        switch self {
        case .codex: .cyan
        case .claude: Color(hex: 0xD97757)
        }
    }
}

enum AppThemeMode: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: Self { self }

    var title: String {
        switch self {
        case .light: "浅色"
        case .dark: "深色"
        case .system: "跟随系统"
        }
    }

    var icon: String {
        switch self {
        case .light: "sun.max"
        case .dark: "moon"
        case .system: "display"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}

private enum ThemePreference {
    static let familyKey = "appearance.theme.family"
    static let modeKey = "appearance.theme.mode"
}

private struct AppThemeFamilyKey: EnvironmentKey {
    static let defaultValue = AppThemeFamily.codex
}

extension EnvironmentValues {
    var appThemeFamily: AppThemeFamily {
        get { self[AppThemeFamilyKey.self] }
        set { self[AppThemeFamilyKey.self] = newValue }
    }
}

struct MainWindowView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(ThemePreference.familyKey) private var themeFamily = AppThemeFamily.codex
    @AppStorage(ThemePreference.modeKey) private var themeMode = AppThemeMode.light
    @State private var selectedModule: ModuleKey = .dashboard
    @StateObject private var providerStore = ProviderListStore()
    @StateObject private var skillStore = SkillListStore()

    var body: some View {
        ZStack {
            AuroraBackground()

            HStack(alignment: .top, spacing: 22) {
                SidebarView(selection: $selectedModule, themeFamily: $themeFamily)
                    .frame(width: 256)

                VStack {
                    ScrollView(showsIndicators: false) {
                        selectedModuleView
                            .id(selectedModule)
                            .transition(
                                reduceMotion
                                    ? .identity
                                    : .asymmetric(
                                        insertion: .opacity.combined(with: .offset(y: 6)),
                                        removal: .opacity
                                    )
                            )
                            .frame(maxWidth: 1_400)
                            .padding(.horizontal, 4)
                            .padding(.top, 8)
                            .padding(.bottom, 42)
                    }
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.20), value: selectedModule)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(22)
        }
        .frame(minWidth: 1_180, minHeight: 720)
        .font(.system(size: 14, weight: .regular, design: .rounded))
        .environment(\.appThemeFamily, themeFamily)
        .preferredColorScheme(themeMode.preferredColorScheme)
    }

    @ViewBuilder
    private var selectedModuleView: some View {
        switch selectedModule {
        case .dashboard: ConfigurationDashboard()
        case .providers: ProvidersDashboard(family: themeFamily, store: providerStore)
        case .mcp: McpDashboard()
        case .prompts: PromptsDashboard()
        case .skills: SkillsDashboard(family: themeFamily, store: skillStore)
        case .usage: UsageDashboard()
        case .settings: SettingsDashboard(themeFamily: themeFamily, themeMode: $themeMode)
        }
    }
}

enum ModuleKey: String, Hashable {
    case dashboard
    case providers
    case mcp
    case prompts
    case skills
    case usage
    case settings
}

struct AuroraBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appThemeFamily) private var themeFamily

    var body: some View {
        let palette = AppThemePalette.resolve(family: themeFamily, colorScheme: colorScheme)

        GeometryReader { proxy in
            let diameter = max(max(proxy.size.width * 0.95, proxy.size.height * 1.40), 900)

            ZStack {
                LinearGradient(
                    colors: palette.background,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let imageURL = Bundle.main.url(forResource: "test", withExtension: "png"),
                   let backgroundImage = NSImage(contentsOf: imageURL) {
                    Image(nsImage: backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    GradientHemisphere(
                        colors: palette.hemisphereColors,
                        rimColors: palette.hemisphereRim,
                        glow: palette.hemisphereGlow,
                        diameter: diameter
                    )
                    .frame(width: diameter, height: diameter)
                    .position(x: proxy.size.width / 2, y: -diameter * 0.18)

                    NoiseTexture()
                        .blendMode(.overlay)
                        .opacity(palette.noiseOpacity)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }
}

private struct GradientHemisphere: View {
    let colors: [Color]
    let rimColors: [Color]
    let glow: Color
    let diameter: CGFloat

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.22), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: diameter * 0.72
                        )
                    )
                    .blendMode(.screen)
            }
            .overlay {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [glow.opacity(0.38), .clear],
                            center: .bottom,
                            startRadius: 0,
                            endRadius: diameter * 0.58
                        )
                    )
                    .blendMode(.plusLighter)
            }
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: rimColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            }
            .shadow(color: glow.opacity(0.72), radius: 74, y: 18)
            .allowsHitTesting(false)
    }
}

private struct NoiseTexture: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 6
            for y in stride(from: CGFloat.zero, through: size.height, by: spacing) {
                for x in stride(from: CGFloat.zero, through: size.width, by: spacing) {
                    let seed = sin(Double(x * 12.9898 + y * 78.233)) * 43_758.5453
                    let value = abs(seed - seed.rounded(.towardZero))
                    guard value > 0.56 else { continue }
                    context.fill(
                        Path(CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(.white.opacity(0.22 + value * 0.18))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}
