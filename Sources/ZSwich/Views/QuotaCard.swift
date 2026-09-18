import SwiftUI

struct QuotaCard: View {
    let title: String
    let systemImage: String
    let window: UsageWindow

    @State private var isHovered = false
    @State private var hoverLocation = CGPoint(x: 110, y: 55)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: QuotaPalette {
        QuotaPalette(remaining: window.remainingPercent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 8) {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(.secondary)
                    .symbolEffect(.bounce, options: .nonRepeating, value: isHovered)
                Spacer(minLength: 8)
                Text("剩余 \(window.remainingPercent, format: .number.precision(.fractionLength(0)))%")
                    .bold()
                    .foregroundStyle(palette.primary)
                    .contentTransition(.numericText())
            }
            .font(.callout)

            QuotaProgressBar(
                value: window.remainingPercent,
                colors: [palette.primary, palette.secondary],
                isHighlighted: isHovered
            )

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .foregroundStyle(.tertiary)
                Text("重置倒计时")
                    .foregroundStyle(.tertiary)
                Spacer(minLength: 8)
                Text(window.resetAt, style: .relative)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(14)
        .background {
            GeometryReader { geometry in
                let center = UnitPoint(
                    x: min(max(hoverLocation.x / max(geometry.size.width, 1), 0), 1),
                    y: min(max(hoverLocation.y / max(geometry.size.height, 1), 0), 1)
                )
                ZStack {
                    ZSwichTheme.inset
                    RadialGradient(
                        colors: [palette.primary.opacity(isHovered ? 0.16 : 0), .clear],
                        center: center,
                        startRadius: 0,
                        endRadius: 150
                    )
                }
                .clipShape(.rect(cornerRadius: 12))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHovered ? palette.primary.opacity(0.34) : .white.opacity(0.06),
                    lineWidth: 1
                )
        }
        .shadow(color: palette.primary.opacity(isHovered ? 0.15 : 0), radius: 16, y: 7)
        .scaleEffect(isHovered && !reduceMotion ? 1.018 : 1)
        .offset(y: isHovered && !reduceMotion ? -2 : 0)
        .animation(reduceMotion ? nil : .snappy(duration: 0.24), value: isHovered)
        .onContinuousHover { phase in
            switch phase {
            case let .active(location):
                isHovered = true
                // 光晕跟随不需要逐像素精度，移动够 6pt 才更新，减少卡片重绘。
                if hypot(location.x - hoverLocation.x, location.y - hoverLocation.y) >= 6 {
                    hoverLocation = location
                }
            case .ended:
                isHovered = false
            }
        }
    }
}

struct QuotaPalette {
    let primary: Color
    let secondary: Color

    init(remaining: Double) {
        switch remaining {
        case ..<20:
            primary = .red
            secondary = Color(red: 1, green: 0.28, blue: 0.48)
        case ..<50:
            primary = .orange
            secondary = .yellow
        default:
            primary = .green
            secondary = .mint
        }
    }
}
