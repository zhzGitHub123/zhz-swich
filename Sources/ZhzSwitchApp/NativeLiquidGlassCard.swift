import SwiftUI

struct NativeLiquidGlassCard<Content: View>: View {
    var tint: Color? = nil
    var cornerRadius: CGFloat = 24
    var fillsAvailableSpace = true
    @ViewBuilder let content: Content

    @ViewBuilder
    var body: some View {
        if #available(macOS 26.0, *) {
            content
                .frame(
                    maxWidth: fillsAvailableSpace ? .infinity : nil,
                    maxHeight: fillsAvailableSpace ? .infinity : nil,
                    alignment: .topLeading
                )
                .glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
                .background(backgroundStyle, in: .rect(cornerRadius: cornerRadius))
                .environment(\.colorScheme, .dark)
        } else {
            GlassCard(
                tint: tint ?? .white,
                cornerRadius: cornerRadius,
                showsBackgroundGradient: tint != nil,
                fillsAvailableSpace: fillsAvailableSpace
            ) {
                content
            }
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        guard let tint else {
            return AnyShapeStyle(Color.black.opacity(0.30))
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [.black.opacity(0.32), tint.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
