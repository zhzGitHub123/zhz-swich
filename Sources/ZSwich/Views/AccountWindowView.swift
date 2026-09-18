import SwiftUI

struct AccountWindowView: View {
    let store: AccountStore
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            AccountWindowBackground()

            VStack(spacing: 0) {
                Color.clear.frame(height: ZSwichTheme.titleBarHeight)

                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: ZSwichTheme.sectionSpacing) {
                            ActiveAccountHero(store: store)
                                .revealSection(appeared, delay: 0.05, reduceMotion: reduceMotion)
                            SavedAccountsCard(store: store)
                                .revealSection(appeared, delay: 0.15, reduceMotion: reduceMotion)
                            ActivityLogCard(entries: store.activityLog)
                                .revealSection(appeared, delay: 0.25, reduceMotion: reduceMotion)
                                .frame(maxHeight: .infinity, alignment: .top)
                        }
                        .frame(
                            minHeight: max(0, geometry.size.height - 40),
                            alignment: .top
                        )
                        .padding(.horizontal, ZSwichTheme.windowPadding)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                    }
                }

                PrototypeFooter(store: store)
            }

            PrototypeTitleBar(store: store)
            StatusToast(status: store.status)
        }
        .frame(
            minWidth: ZSwichTheme.windowMinWidth,
            minHeight: ZSwichTheme.windowMinHeight
        )
        .ignoresSafeArea(.container, edges: .top)
        .preferredColorScheme(.dark)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.smooth(duration: 0.5)) {
                    appeared = true
                }
            }
        }
    }
}

private extension View {
    func revealSection(_ appeared: Bool, delay: Double, reduceMotion: Bool) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 12)
            .animation(.smooth(duration: 0.5).delay(delay), value: appeared)
    }
}
