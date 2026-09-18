import SwiftUI

struct AccountRowActions: View {
    let isCurrent: Bool
    let isBusy: Bool
    var isSwitching = false
    var isRefreshingUsage = false
    var canRefreshUsage = true
    let refreshUsageAction: () -> Void
    let switchAction: () -> Void
    let deleteAction: () -> Void

    @State private var refreshRotation = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // 三个按钮同属一组，间距统一 10；两个图标按钮共用 30×30 的尺寸与悬停反馈。
        HStack(spacing: 10) {
            Button(action: refresh) {
                if isRefreshingUsage {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(refreshRotation))
                }
            }
            .buttonStyle(ZSwichNeutralIconButtonStyle())
            .disabled(!canRefreshUsage || isRefreshingUsage)
            .help("查询该账号额度，不会切换账号")
            .accessibilityLabel("查询该账号额度")

            if isCurrent {
                Button(action: {}) {
                    Label("当前账号", systemImage: "checkmark.circle.fill")
                }
                    .buttonStyle(ZSwichCurrentAccountButtonStyle())
                    .disabled(true)
                    .accessibilityLabel("当前正在使用的账号")
            } else {
                Button(action: switchAction) {
                    HStack(spacing: 6) {
                        if isSwitching {
                            ProgressView()
                                .controlSize(.mini)
                                .tint(.white)
                        }
                        Text(isSwitching ? "正在切换" : "切换至此")
                        if !isSwitching {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .contentTransition(.interpolate)
                }
                .buttonStyle(ZSwichPrimaryButtonStyle(compact: true))
                .disabled(isBusy)
                .help("安全退出 ChatGPT 并切换到此账号")
            }

            Button("移除账号", systemImage: "trash", role: .destructive, action: deleteAction)
                .labelStyle(.iconOnly)
                .buttonStyle(ZSwichDangerIconButtonStyle())
                .disabled(isCurrent || isBusy)
                .help(isCurrent ? "当前账号不能移除" : "只移除 Z-Swich 快照")
        }
    }

    private func refresh() {
        if !reduceMotion {
            withAnimation(.linear(duration: 0.7)) { refreshRotation += 360 }
        }
        refreshUsageAction()
    }
}
