import SwiftUI

struct LiquidGlassPanelModifier: ViewModifier {
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial, in: .rect(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
        }
    }
}

extension View {
    func liquidGlassPanel(cornerRadius: CGFloat = ZSwichTheme.largeRadius) -> some View {
        modifier(LiquidGlassPanelModifier(cornerRadius: cornerRadius))
    }
}
