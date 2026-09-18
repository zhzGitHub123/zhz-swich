import SwiftUI

struct AccountWindowBackground: View {
    @State private var glowCenter = UnitPoint(x: 0.34, y: 0)
    @State private var lastLocation = CGPoint.zero
    /// 鼠标移动不足这个距离不重绘整块渐变。
    private let moveThreshold: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZSwichTheme.canvas
                RadialGradient(
                    colors: [Color.indigo.opacity(0.24), .clear],
                    center: glowCenter,
                    startRadius: 12,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.72
                )
                RadialGradient(
                    colors: [Color.purple.opacity(0.12), .clear],
                    center: .bottomTrailing,
                    startRadius: 20,
                    endRadius: geometry.size.width * 0.62
                )
            }
            .onContinuousHover { phase in
                guard case let .active(location) = phase else { return }
                guard hypot(location.x - lastLocation.x, location.y - lastLocation.y) >= moveThreshold else {
                    return
                }
                lastLocation = location
                glowCenter = UnitPoint(
                    x: location.x / max(geometry.size.width, 1),
                    y: min(location.y / max(geometry.size.height, 1), 0.38)
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
