import SwiftUI

struct QuotaProgressBar: View {
    let value: Double
    let colors: [Color]
    var isHighlighted = false

    @State private var shimmers = false
    @State private var displayedValue = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let width = max(0, geometry.size.width * min(max(displayedValue / 100, 0), 1))

            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.10))
                Capsule()
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .frame(width: width)
                    .shadow(color: colors.first?.opacity(isHighlighted ? 0.65 : 0.30) ?? .clear, radius: isHighlighted ? 7 : 3)
                    .overlay {
                        if !reduceMotion, width > 1 {
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.55), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: max(28, width * 0.42))
                            .offset(x: shimmers ? width : -width)
                            .mask(Capsule().frame(width: width))
                        }
                    }
                    .clipped()
            }
        }
        .frame(height: 8)
        .onAppear {
            if reduceMotion {
                displayedValue = value
            } else {
                withAnimation(.smooth(duration: 0.7)) {
                    displayedValue = value
                }
            }
        }
        .loopingAnimation(
            isEnabled: !reduceMotion,
            start: {
                withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) {
                    shimmers = true
                }
            },
            stop: {
                withoutAnimation { shimmers = false }
            }
        )
        .onChange(of: value) { _, newValue in
            if reduceMotion {
                displayedValue = newValue
            } else {
                withAnimation(.smooth(duration: 0.7)) {
                    displayedValue = newValue
                }
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isHighlighted)
    }
}
