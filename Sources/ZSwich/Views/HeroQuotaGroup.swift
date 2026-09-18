import SwiftUI

struct HeroQuotaGroup: View {
    let store: AccountStore

    var body: some View {
        Group {
            if let usage = store.usage, !usage.windows.isEmpty {
                // 窗口数量与长度随套餐变化：Plus 是 5 小时 + 每周，Pro 只有每周一个窗口。
                HStack(spacing: 14) {
                    ForEach(usage.windows, id: \.self) { window in
                        QuotaCard(
                            title: window.title,
                            systemImage: window.systemImage,
                            window: window
                        )
                    }
                }
            } else if store.isLoadingUsage {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("正在获取当前账号额度…")
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(ZSwichTheme.inset, in: .rect(cornerRadius: 12))
            } else {
                Label(
                    store.usageProblem ?? "额度尚未查询",
                    systemImage: store.usageProblem == nil ? "gauge.with.dots.needle.33percent" : "exclamationmark.triangle"
                )
                .foregroundStyle(store.usageProblem == nil ? Color.secondary : Color.orange)
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(ZSwichTheme.inset, in: .rect(cornerRadius: 12))
            }
        }
    }
}
