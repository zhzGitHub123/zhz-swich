import SwiftUI

/// 横向滚动时钉在右边缘的列所用的背景。
/// 必须是不透明底色：下面的列会从它身下滑过去，半透明会穿帮。
struct PinnedColumnBackground: View {
    let isPinned: Bool
    var tint: Color = .clear

    var body: some View {
        if isPinned {
            ZStack {
                ZSwichTheme.pinnedColumn
                tint
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(.white.opacity(0.07))
                    .frame(width: 1)
            }
            .shadow(color: .black.opacity(0.45), radius: 8, x: -5)
        }
    }
}
