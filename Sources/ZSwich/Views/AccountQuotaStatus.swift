import SwiftUI

/// 表格里的单账号额度列。额度按需查询：点行内刷新或表头的"查询全部额度"才发请求。
struct AccountQuotaStatus: View {
    let account: AccountRecord
    let store: AccountStore

    private var isLoading: Bool { store.isLoadingUsage(for: account.id) }

    /// 刷新按钮在行尾的操作组里（见 AccountRowActions），这里只负责展示。
    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("查询中…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else if let usage = store.usage(for: account.id), !usage.windows.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(usage.windows, id: \.self) { window in
                    QuotaMiniBar(window: window)
                }
            }
        } else if let problem = store.usageProblem(for: account.id) {
            Label(problem, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
                .lineLimit(1)
                .help(problem)
        } else if account.accessTokenExpiry.map({ $0 <= .now }) == true {
            Label("凭证已过期", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
                .help(AccountStore.expiredCredentialsNote)
        } else {
            Label("未查询", systemImage: "gauge.with.dots.needle.33percent")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

}

private struct QuotaMiniBar: View {
    let window: UsageWindow

    var body: some View {
        let palette = QuotaPalette(remaining: window.remainingPercent)
        HStack(spacing: 5) {
            Text(window.shortLabel)
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.tertiary)
                .frame(width: 26, alignment: .leading)
            ProgressView(value: window.remainingPercent, total: 100)
                .tint(palette.primary)
                .frame(width: 46)
            Text("\(window.remainingPercent, format: .number.precision(.fractionLength(0)))%")
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(palette.primary)
        }
        .help("\(window.title)：剩余 \(Int(window.remainingPercent))%")
    }
}
