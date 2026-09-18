import SwiftUI

struct SavedAccountsHeader: View {
    var pinnedActionOffset: CGFloat = 0

    private var isPinned: Bool { pinnedActionOffset < -0.5 }

    var body: some View {
        HStack(spacing: 0) {
            cell("账号 / 别名", minWidth: ZSwichTheme.accountColumnMinWidth)
            cell("套餐规格", width: ZSwichTheme.planColumnWidth)
            cell("订阅到期", width: ZSwichTheme.dateColumnWidth)
            cell("最后使用", width: ZSwichTheme.dateColumnWidth)
            cell("最后保存", width: ZSwichTheme.dateColumnWidth)
            cell("额度状态", width: ZSwichTheme.quotaColumnWidth)
            label("操作")
                .frame(
                    width: ZSwichTheme.actionColumnWidth,
                    height: ZSwichTheme.tableHeaderHeight,
                    alignment: .trailing
                )
                .background(PinnedColumnBackground(isPinned: isPinned, tint: .white.opacity(0.025)))
                .offset(x: pinnedActionOffset)
        }
        .frame(maxWidth: .infinity)
        .frame(height: ZSwichTheme.tableHeaderHeight)
        .background(.white.opacity(0.025))
        .overlay(alignment: .bottom) {
            Rectangle().fill(ZSwichTheme.hairline).frame(height: 1)
        }
    }

    private func cell(_ title: String, width: CGFloat, alignment: Alignment = .leading) -> some View {
        label(title)
            .frame(width: width, alignment: alignment)
    }

    private func cell(_ title: String, minWidth: CGFloat) -> some View {
        label(title)
            .frame(minWidth: minWidth, maxWidth: .infinity, alignment: .leading)
    }

    private func label(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
    }
}
