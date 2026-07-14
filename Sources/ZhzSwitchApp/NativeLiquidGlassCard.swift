import SwiftUI

struct NativeLiquidGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    @ViewBuilder let content: Content

    @ViewBuilder
    var body: some View {
        if #available(macOS 26.0, *) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
                .background(.black.opacity(0.30), in: .rect(cornerRadius: cornerRadius))
        } else {
            GlassCard(cornerRadius: cornerRadius, showsBackgroundGradient: false) {
                content
            }
        }
    }
}
