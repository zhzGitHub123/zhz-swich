import SwiftUI

struct PrototypeFooter: View {
    let store: AccountStore
    @State private var addHovered = false

    var body: some View {
        HStack(spacing: 16) {
            Label("空闲时不执行后台检查", systemImage: "bolt.slash.fill")
                .foregroundStyle(.secondary)
            Divider().frame(height: 18)
            Label("本地快照 · 0600 权限", systemImage: "checkmark.shield.fill")
                .foregroundStyle(.secondary)

            Spacer()

            if !store.chatGPTRunning {
                Button("打开 ChatGPT", systemImage: "play.fill", action: launchChatGPT)
                    .buttonStyle(ZSwichSecondaryButtonStyle())
                    .disabled(store.isBusy)
            }

            addAccountButton
        }
        .font(.callout)
        .padding(.horizontal, 22)
        .frame(height: 62)
        .background(.black.opacity(0.30))
        .overlay(alignment: .top) {
            Rectangle().fill(ZSwichTheme.hairline).frame(height: 1)
        }
    }

    @ViewBuilder
    private var addAccountButton: some View {
        let label = HStack(spacing: 8) {
            Image(systemName: "plus")
                .rotationEffect(.degrees(addHovered ? 90 : 0))
            Text("添加新账号").bold()
        }

        Button(action: addAccount) { label }
            .buttonStyle(ZSwichPrimaryButtonStyle())
            .disabled(store.isBusy)
            .onHover { addHovered = $0 }
            .animation(.snappy, value: addHovered)
    }

    private func addAccount() {
        Task { await store.startNewLogin() }
    }

    private func launchChatGPT() {
        Task { await store.launchChatGPT() }
    }
}
