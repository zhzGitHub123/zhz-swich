import SwiftUI

struct ChatGPTRunningBadge: View {
    let isRunning: Bool
    @Environment(\.windowIsVisible) private var visibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 7) {
            StatusPulseDot(color: isRunning ? .green : .secondary, size: 5)
            Image(systemName: isRunning ? "checkmark.circle.fill" : "pause.circle.fill")
                // pulse 是无限期动画，会一直驱动重绘；窗口看不见或减弱动效时停掉。
                .symbolEffect(.pulse, isActive: isRunning && !reduceMotion && (visibility?.isVisible ?? true))
            Text(isRunning ? "ChatGPT 运行中" : "ChatGPT 未运行")
        }
        .font(.callout)
        .foregroundStyle(isRunning ? Color.green : Color.secondary)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(
            isRunning ? Color.green.opacity(0.12) : Color.secondary.opacity(0.10),
            in: .capsule
        )
        .overlay {
            Capsule()
                .stroke(isRunning ? Color.green.opacity(0.12) : Color.white.opacity(0.05), lineWidth: 1)
        }
    }
}
