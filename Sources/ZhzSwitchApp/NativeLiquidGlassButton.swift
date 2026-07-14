import SwiftUI

struct NativeLiquidGlassButton<Label: View>: View {
    var tint: Color? = nil
    var cornerRadius: CGFloat = 13
    let action: () -> Void
    @ViewBuilder let label: Label

    @ViewBuilder
    var body: some View {
        if #available(macOS 26.0, *) {
            Button(action: action) {
                label
            }
            .buttonStyle(.plain)
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: cornerRadius))
            .background(backgroundStyle, in: .rect(cornerRadius: cornerRadius))
            .environment(\.colorScheme, .dark)
            .interactivePointerStyle()
        } else {
            Button(action: action) {
                GlassCard(
                    tint: tint ?? .white,
                    cornerRadius: cornerRadius,
                    showsBackgroundGradient: tint != nil,
                    isHoverEffectEnabled: true,
                    fillsAvailableSpace: false
                ) {
                    label
                }
            }
            .buttonStyle(.plain)
            .interactivePointerStyle()
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        guard let tint else {
            return AnyShapeStyle(Color.black.opacity(0.24))
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [.black.opacity(0.26), tint.opacity(0.30)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
