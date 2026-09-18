import SwiftUI

struct PrototypeTitleBar: View {
    let store: AccountStore
    @State private var refreshRotation = 0.0

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                Text("Z-Swich")
                    .font(.headline)
                Text("•")
                    .foregroundStyle(.tertiary)
                Text("ChatGPT 账号管理与智能切换器")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            ChatGPTRunningBadge(isRunning: store.chatGPTRunning)
            Spacer()

            Button(action: refresh) {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(refreshRotation))
                    Text(store.isLoadingUsage ? "同步中…" : "同步状态")
                }
                    .font(.callout)
            }
            .buttonStyle(ZSwichSecondaryButtonStyle(compact: true))
            .disabled(store.isLoadingUsage || store.current == nil)
        }
        .padding(.leading, 86)
        .padding(.trailing, 20)
        .frame(height: ZSwichTheme.titleBarHeight)
        .background(.black.opacity(0.18))
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle().fill(ZSwichTheme.hairline).frame(height: 1)
        }
    }

    private func refresh() {
        withAnimation(.linear(duration: 0.7)) {
            refreshRotation += 360
        }
        Task { await store.refreshUsage(force: true) }
    }
}
