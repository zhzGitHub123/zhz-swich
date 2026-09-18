import SwiftUI

struct StatusPulseDot: View {
    var color: Color = .green
    var haloColor: Color? = nil
    var size: CGFloat = 8
    var emphasized = false

    @State private var breathes = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if emphasized {
                Circle()
                    .fill(haloColor ?? color)
                    .frame(width: size, height: size)
                    .scaleEffect(breathes && !reduceMotion ? 1.15 : 1)
                    .opacity(breathes && !reduceMotion ? 1 : 0.90)
                    .shadow(
                        color: (haloColor ?? color).opacity(breathes ? 0.90 : 0.50),
                        radius: breathes ? 5 : 2
                    )
            } else {
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .scaleEffect(breathes && !reduceMotion ? 1.15 : 1)
                    .opacity(breathes && !reduceMotion ? 1 : 0.90)
                    .shadow(
                        color: color.opacity(breathes ? 0.90 : 0.50),
                        radius: breathes ? 5 : 2
                    )
            }

            if emphasized {
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .overlay {
                        Circle().stroke(ZSwichTheme.canvas, lineWidth: 1.5)
                    }
            }
        }
        .frame(
            width: size,
            height: size
        )
        .loopingAnimation(
            isEnabled: !reduceMotion,
            start: {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    breathes = true
                }
            },
            stop: {
                withoutAnimation { breathes = false }
            }
        )
        .accessibilityHidden(true)
    }
}
