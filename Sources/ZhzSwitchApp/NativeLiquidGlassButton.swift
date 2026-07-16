import SwiftUI

struct NativeLiquidGlassButton<Label: View>: View {
    var tint: Color? = nil
    var cornerRadius: CGFloat = 13
    var isSelected = false
    var usesBackgroundScrim = true
    let action: () -> Void
    @ViewBuilder let label: Label

    @ViewBuilder
    var body: some View {
        if #available(macOS 26.0, *) {
            Button(action: action) {
                label
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .glassEffect(liquidGlassStyle, in: .rect(cornerRadius: cornerRadius))
            .background {
                if usesBackgroundScrim {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(backgroundStyle)
                }
            }
            .interactivePointerStyle()
        } else {
            Button(action: action) {
                GlassCard(
                    tint: tint ?? .white,
                    cornerRadius: cornerRadius,
                    showsBackgroundGradient: usesBackgroundScrim && tint != nil,
                    isHoverEffectEnabled: true,
                    fillsAvailableSpace: false
                ) {
                    label
                        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            }
            .buttonStyle(.plain)
            .interactivePointerStyle()
        }
    }

    @available(macOS 26.0, *)
    private var liquidGlassStyle: Glass {
        guard isSelected, let tint else {
            return .clear.interactive()
        }

        return .clear.tint(tint.opacity(0.16)).interactive()
    }

    private var backgroundStyle: AnyShapeStyle {
        guard let tint else {
            return AnyShapeStyle(Color.glassScrim.opacity(0.24))
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [Color.glassScrim.opacity(0.26), tint.opacity(0.30)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
