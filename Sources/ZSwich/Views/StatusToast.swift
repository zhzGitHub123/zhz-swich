import SwiftUI

struct StatusToast: View {
    let status: String?
    @State private var displayedStatus: String?

    var body: some View {
        VStack {
            if let displayedStatus {
                Label(displayedStatus, systemImage: "checkmark.circle.fill")
                    .font(.callout)
                    .lineLimit(2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(.ultraThickMaterial, in: .rect(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ZSwichTheme.accent.opacity(0.36), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 76)
        .padding(.trailing, 22)
        .allowsHitTesting(false)
        .task(id: status) {
            guard let status else { return }
            withAnimation(.snappy) {
                displayedStatus = status
            }
            try? await Task.sleep(for: .seconds(3.2))
            guard !Task.isCancelled else { return }
            withAnimation(.smooth) {
                displayedStatus = nil
            }
        }
    }
}
