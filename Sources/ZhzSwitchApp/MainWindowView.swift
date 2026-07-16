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
        case .dashboard:
            ConfigurationDashboard(
                providerStore: providerStore,
                onOpenProviders: { family in
                    themeFamily = family
                    selectedModule = .providers
                },
                onNavigate: { module in
                    selectedModule = module
                }
            )
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
    @AppStorage(AppBackground.styleKey) private var backgroundStyle = AppBackground.Style.house
    @AppStorage(AppBackground.customImageRevisionKey) private var customImageRevision = 0
    @State private var defaultImage = AppBackground.bundledDefaultImage()
    @State private var customImage = AppBackground.customImage()

    var body: some View {
        let palette = AppThemePalette.resolve(family: themeFamily, colorScheme: colorScheme)

        GeometryReader { proxy in
            let diameter = max(max(proxy.size.width * 0.95, proxy.size.height * 1.40), 900)

            ZStack {
                switch backgroundStyle {
                case .house:
                    if let defaultImage {
                        backgroundImage(defaultImage, size: proxy.size)
                    } else {
                        themeAurora(palette: palette, size: proxy.size, diameter: diameter)
                    }
                case .aurora:
                    themeAurora(palette: palette, size: proxy.size, diameter: diameter)
                case .softGlow:
                    softGlow(palette: palette, size: proxy.size)
                case .custom:
                    if let customImage {
                        backgroundImage(customImage, size: proxy.size)
                    } else {
                        themeAurora(palette: palette, size: proxy.size, diameter: diameter)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .onChange(of: customImageRevision) {
            customImage = AppBackground.customImage()
        }
    }

    private func backgroundImage(_ image: NSImage, size: CGSize) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
    }

    private func themeAurora(
        palette: AppThemePalette,
        size: CGSize,
        diameter: CGFloat
    ) -> some View {
        ZStack {
            LinearGradient(
                colors: palette.background,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GradientHemisphere(
                colors: palette.hemisphereColors,
                rimColors: palette.hemisphereRim,
                glow: palette.hemisphereGlow,
                diameter: diameter
            )
            .frame(width: diameter, height: diameter)
            .position(x: size.width / 2, y: -diameter * 0.18)

            NoiseTexture()
                .blendMode(.overlay)
                .opacity(palette.noiseOpacity)
        }
    }

    private func softGlow(palette: AppThemePalette, size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: palette.background,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [themeFamily.accentColor.opacity(colorScheme == .dark ? 0.48 : 0.30), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: max(size.width, size.height) * 0.75
            )
            RadialGradient(
                colors: [palette.hemisphereGlow.opacity(0.34), .clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: max(size.width, size.height) * 0.62
            )
            NoiseTexture()
                .blendMode(.overlay)
                .opacity(palette.noiseOpacity * 0.65)
        }
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
