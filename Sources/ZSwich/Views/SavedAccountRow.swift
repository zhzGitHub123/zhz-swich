import SwiftUI

struct SavedAccountRow: View {
    let account: AccountRecord
    let store: AccountStore
    /// 见 SavedAccountsCard：横向滚动时操作列靠它贴住可视右边缘。
    var pinnedActionOffset: CGFloat = 0
    let deleteAction: () -> Void

    @State private var isHovered = false

    private var isPinned: Bool { pinnedActionOffset < -0.5 }

    var body: some View {
        let isCurrent = account.id == store.current?.accountID

        HStack(spacing: 0) {
            HStack(spacing: 12) {
                AccountAvatar(account: account, isCurrent: isCurrent)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(account.email)
                            .lineLimit(1)
                        if isCurrent {
                            Text("使用中")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.10), in: .rect(cornerRadius: 4))
                        }
                    }
                    if let name = account.name, !name.isEmpty {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(minWidth: ZSwichTheme.accountColumnMinWidth, maxWidth: .infinity, alignment: .leading)

            AccountPlanBadge(account: account)
                .padding(.horizontal, 12)
                .frame(width: ZSwichTheme.planColumnWidth, alignment: .leading)

            OptionalDateText(date: account.subscriptionUntil)
                .padding(.horizontal, 12)
                .frame(width: ZSwichTheme.dateColumnWidth, alignment: .leading)
            OptionalDateText(date: account.lastUsedAt, includesTime: true)
                .padding(.horizontal, 12)
                .frame(width: ZSwichTheme.dateColumnWidth, alignment: .leading)
            OptionalDateText(date: account.lastSavedAt, includesTime: true)
                .padding(.horizontal, 12)
                .frame(width: ZSwichTheme.dateColumnWidth, alignment: .leading)

            AccountQuotaStatus(account: account, store: store)
                .padding(.horizontal, 12)
                .frame(width: ZSwichTheme.quotaColumnWidth, alignment: .leading)

            AccountRowActions(
                isCurrent: isCurrent,
                isBusy: store.isBusy,
                isSwitching: store.switchingAccountID == account.id,
                isRefreshingUsage: store.isLoadingUsage(for: account.id),
                canRefreshUsage: !store.isRefreshingAllUsage,
                refreshUsageAction: { Task { await store.refreshUsage(for: account.id) } },
                switchAction: switchAccount,
                deleteAction: deleteAction
            )
            .padding(.horizontal, 12)
            .frame(
                width: ZSwichTheme.actionColumnWidth,
                height: ZSwichTheme.tableRowHeight,
                alignment: .trailing
            )
            .background(PinnedColumnBackground(isPinned: isPinned, tint: rowTint))
            .offset(x: pinnedActionOffset)
        }
        .font(.callout)
        .frame(maxWidth: .infinity)
        .frame(height: ZSwichTheme.tableRowHeight)
        .background(rowTint)
        .offset(y: isHovered ? -1 : 0)
        .animation(.snappy, value: isHovered)
        .onHover { isHovered = $0 }
        .overlay(alignment: .bottom) {
            Rectangle().fill(.white.opacity(0.05)).frame(height: 1)
        }
    }

    /// 行底色。悬浮的操作格要叠同一层底色，否则钉住时会比整行浅一块。
    private var rowTint: Color {
        if account.id == store.current?.accountID { return ZSwichTheme.accent.opacity(0.055) }
        return isHovered ? Color.white.opacity(0.045) : Color.clear
    }

    private func switchAccount() {
        Task { await store.switchTo(accountID: account.id) }
    }
}
