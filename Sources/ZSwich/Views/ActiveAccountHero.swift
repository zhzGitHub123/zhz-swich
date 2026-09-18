import SwiftUI

struct ActiveAccountHero: View {
    let store: AccountStore
    @State private var refreshRotation = 0.0
    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.windowIsVisible) private var visibility

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 28) {
                    ActiveAccountIdentity(store: store)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HeroQuotaGroup(store: store)
                        .frame(width: 480)
                }

                VStack(alignment: .leading, spacing: 18) {
                    ActiveAccountIdentity(store: store)
                    HeroQuotaGroup(store: store)
                }
            }

            Divider().overlay(.white.opacity(0.08))

            HStack(spacing: 10) {
                HStack(spacing: 7) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(ZSwichTheme.accent)
                        .symbolEffect(.pulse, isActive: !reduceMotion && (visibility?.isVisible ?? true))
                    Text("切换前会保存最新凭证，安全退出并重新启动 ChatGPT")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Button(action: refresh) {
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(refreshRotation))
                        Text(store.isLoadingUsage ? "刷新中…" : "刷新当前额度")
                    }
                }
                .buttonStyle(ZSwichSecondaryButtonStyle(compact: true))
                .disabled(store.isLoadingUsage || store.current == nil)
            }.frame(height: 20)
        }
        .padding(22)
        .background {
            ZStack {
                LinearGradient(
                    colors: [Color.indigo.opacity(0.20), ZSwichTheme.card.opacity(0.94)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [Color.purple.opacity(isHovered ? 0.28 : 0.20), .clear],
                    center: .bottomLeading,
                    startRadius: 8,
                    endRadius: isHovered ? 430 : 360
                )
            }
            .clipShape(.rect(cornerRadius: ZSwichTheme.largeRadius))
        }
        .overlay {
            RoundedRectangle(cornerRadius: ZSwichTheme.largeRadius)
                .stroke(ZSwichTheme.accent.opacity(isHovered ? 0.48 : 0.32), lineWidth: 1)
        }
        .shadow(
            color: ZSwichTheme.accent.opacity(isHovered ? 0.22 : 0.13),
            radius: isHovered ? 32 : 24,
            y: isHovered ? 8 : 0
        )
        .scaleEffect(isHovered && !reduceMotion ? 1.002 : 1)
        .animation(reduceMotion ? nil : .smooth(duration: 0.32), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private func refresh() {
        withAnimation(.linear(duration: 0.7)) {
            refreshRotation += 360
        }
        Task { await store.refreshUsage(force: true) }
    }
}
