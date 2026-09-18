import SwiftUI

struct SavedAccountsCard: View {
    let store: AccountStore

    @State private var searchText = ""
    @State private var pendingDelete: AccountRecord?
    @State private var showsDeleteConfirmation = false
    @State private var headerHovered = false
    @State private var searchHovered = false
    @State private var tableWidth = ZSwichTheme.accountTableMinWidth
    /// 操作列为了贴住可视右边缘需要左移的距离（≤ 0）。表格没被横向裁掉时为 0，此时该列不悬浮。
    @State private var pinnedActionOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "person.2")
                        .foregroundStyle(headerHovered ? ZSwichTheme.accent : Color.primary)
                        .scaleEffect(headerHovered && !reduceMotion ? 1.12 : 1)
                        .symbolEffect(.bounce, options: .nonRepeating, value: headerHovered)
                    Text("已保存账号")
                        .font(.headline)
                }
                .contentShape(.rect)
                .onHover { headerHovered = $0 }
                .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: headerHovered)
                Text(filteredAccounts.count, format: .number)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(ZSwichTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ZSwichTheme.accent.opacity(0.14), in: .capsule)

                Spacer()
                Text("切换前会安全退出并重新启动 ChatGPT")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // 额度按需查询：每个账号用自己快照里的令牌请求，不需要切换过去。
                Button {
                    Task { await store.refreshAllUsage() }
                } label: {
                    Label(
                        store.isRefreshingAllUsage ? "查询中…" : "查询全部额度",
                        systemImage: "gauge.with.dots.needle.67percent"
                    )
                }
                .buttonStyle(ZSwichSecondaryButtonStyle(compact: true))
                .disabled(store.isRefreshingAllUsage || store.accounts.isEmpty)
                .help("用各账号自己保存的凭证查询额度，不会切换账号")

                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(searchText.isEmpty ? Color.secondary : ZSwichTheme.accent)
                        .scaleEffect(searchHovered && !reduceMotion ? 1.08 : 1)
                    TextField("搜索账号或别名…", text: $searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 170)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(ZSwichTheme.inset, in: .rect(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            searchText.isEmpty && !searchHovered
                                ? ZSwichTheme.hairline
                                : ZSwichTheme.accent.opacity(0.65)
                        )
                }
                .shadow(color: ZSwichTheme.accent.opacity(searchHovered ? 0.10 : 0), radius: 8)
                .onHover { searchHovered = $0 }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: searchHovered)
            }

            if store.accounts.isEmpty {
                ContentUnavailableView(
                    "暂无账号",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("登录 ChatGPT 后，再打开菜单或窗口即可收录当前账号。")
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ScrollView(.horizontal) {
                    VStack(spacing: 0) {
                        SavedAccountsHeader(pinnedActionOffset: pinnedActionOffset)
                        if filteredAccounts.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                                .frame(maxWidth: .infinity, minHeight: 120)
                        } else {
                            ForEach(filteredAccounts) { account in
                                SavedAccountRow(
                                    account: account,
                                    store: store,
                                    pinnedActionOffset: pinnedActionOffset,
                                    deleteAction: { requestDelete(account) }
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                    }
                    .animation(.smooth, value: filteredAccounts.map(\.id))
                    .frame(width: tableWidth)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    // 内容比视口宽多少还没滚出来，操作列就左移多少；滚到最右端时归零。
                    min(0, geometry.contentOffset.x + geometry.containerSize.width - geometry.contentSize.width)
                } action: { _, offset in
                    pinnedActionOffset = offset
                }
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    tableWidth = max(width, ZSwichTheme.accountTableMinWidth)
                }
                .background(ZSwichTheme.inset, in: .rect(cornerRadius: 12))
                .clipShape(.rect(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                }
            }
        }
        .padding(18)
        .background(ZSwichTheme.card.opacity(0.86), in: .rect(cornerRadius: ZSwichTheme.largeRadius))
        .overlay {
            RoundedRectangle(cornerRadius: ZSwichTheme.largeRadius)
                .stroke(ZSwichTheme.hairline, lineWidth: 1)
        }
        .confirmationDialog(
            "移除账号快照？",
            isPresented: $showsDeleteConfirmation,
            presenting: pendingDelete
        ) { account in
            Button("移除 \(account.email)", role: .destructive) {
                withAnimation(.smooth) {
                    store.delete(accountID: account.id)
                }
            }
            Button("取消", role: .cancel) {}
        } message: { _ in
            Text("只会删除 Z-Swich 保存的快照，不会改动 ChatGPT 的本地数据。")
        }
    }

    private var filteredAccounts: [AccountRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return store.accounts }
        return store.accounts.filter { account in
            [account.email, account.name, account.planLabel]
                .compactMap { $0?.lowercased() }
                .contains { $0.contains(query) }
        }
    }

    private func requestDelete(_ account: AccountRecord) {
        pendingDelete = account
        showsDeleteConfirmation = true
    }
}
