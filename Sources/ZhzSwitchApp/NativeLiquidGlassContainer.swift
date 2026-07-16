import SwiftUI

struct NativeLiquidGlassContainer<Content: View>: View {
    var spacing: CGFloat = 0
    @ViewBuilder let content: Content

    @ViewBuilder
    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}
