import SwiftUI

struct ActivityLogCard: View {
    let entries: [ActivityLogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("活动日志", systemImage: "bolt.fill")
                    .font(.headline)
                Text("实时审计")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.05), in: .rect(cornerRadius: 5))
                Spacer()
                Text("仅保留本次运行日志")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ActivityLogView(entries: entries)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(18)
        .background(ZSwichTheme.card.opacity(0.86), in: .rect(cornerRadius: ZSwichTheme.largeRadius))
        .overlay {
            RoundedRectangle(cornerRadius: ZSwichTheme.largeRadius)
                .stroke(ZSwichTheme.hairline, lineWidth: 1)
        }
    }
}
