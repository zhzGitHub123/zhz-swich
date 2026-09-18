import SwiftUI

struct ActivityLogView: View {
    let entries: [ActivityLogEntry]

    var body: some View {
        if entries.isEmpty {
            VStack(spacing: 5) {
                Label("暂无活动", systemImage: "checkmark.circle")
                    .font(.headline)
                Text("切换、收录和失败事件会显示在这里。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 92, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(entries) { entry in
                        ActivityLogRow(entry: entry)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .frame(minHeight: 104, maxHeight: .infinity)
            .animation(.smooth, value: entries.map(\.id))
        }
    }

}

private struct ActivityLogRow: View {
    let entry: ActivityLogEntry

    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 10) {
            StatusPulseDot(color: color, size: 4)
            Text(entry.message)
                .textSelection(.enabled)
            Spacer(minLength: 0)
            Text(tag)
                .font(.caption)
                .foregroundStyle(color)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(color.opacity(isHovered ? 0.16 : 0.10), in: .rect(cornerRadius: 4))
            Text(entry.date, format: .dateTime.hour().minute().second())
                .monospacedDigit()
                .foregroundStyle(.tertiary)
        }
        .font(.callout)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isHovered ? Color.white.opacity(0.045) : ZSwichTheme.inset,
            in: .rect(cornerRadius: 8)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? color.opacity(0.20) : .white.opacity(0.05), lineWidth: 1)
        }
        .offset(x: isHovered && !reduceMotion ? 2 : 0)
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .snappy(duration: 0.20), value: isHovered)
    }

    private var tag: String {
        switch kind {
        case .info: "信息"
        case .success: "已完成"
        case .error: "失败"
        }
    }

    private var color: Color {
        switch entry.kind {
        case .info: .secondary
        case .success: .green
        case .error: .red
        }
    }

    private var kind: ActivityLogEntry.Kind { entry.kind }
}
