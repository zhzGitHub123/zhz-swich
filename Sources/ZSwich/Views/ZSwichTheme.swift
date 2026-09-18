import SwiftUI

enum ZSwichTheme {
    static let windowMinWidth: CGFloat = 820
    static let windowMinHeight: CGFloat = 520
    static let windowPadding: CGFloat = 22
    static let titleBarHeight: CGFloat = 52
    static let sectionSpacing: CGFloat = 16
    static let largeRadius: CGFloat = 22
    static let cardRadius: CGFloat = 16
    static let controlRadius: CGFloat = 12

    static let accent = Color(red: 0.39, green: 0.40, blue: 0.95)
    static let canvas = Color(red: 0.043, green: 0.051, blue: 0.078)
    static let card = Color(red: 0.075, green: 0.086, blue: 0.125)
    static let inset = Color.black.opacity(0.26)
    static let hairline = Color.white.opacity(0.08)
    /// 表格区域的等效实色（card 0.86 叠 inset 后的近似值），供固定列做不透明底。
    static let pinnedColumn = Color(red: 0.052, green: 0.060, blue: 0.088)

    static let tableHeaderHeight: CGFloat = 42
    static let tableRowHeight: CGFloat = 62
    static let accountTableMinWidth: CGFloat = 1115
    static let accountColumnMinWidth: CGFloat = 270
    // 要放得下最长的套餐名 "Pro 20x" 加图标，不能让徽标折行。
    static let planColumnWidth: CGFloat = 118
    static let dateColumnWidth: CGFloat = 125
    static let quotaColumnWidth: CGFloat = 150
    // 三个按钮：刷新 30 + 10 + 切换 + 10 + 移除 30，外加 12 的左右内边距。
    static let actionColumnWidth: CGFloat = 200
}
