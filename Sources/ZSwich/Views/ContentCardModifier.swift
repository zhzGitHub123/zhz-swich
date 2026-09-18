import SwiftUI

struct ContentCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Color(nsColor: .controlBackgroundColor).opacity(0.78),
                in: .rect(cornerRadius: ZSwichTheme.cardRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: ZSwichTheme.cardRadius)
                    .stroke(.primary.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }
}

extension View {
    func contentCard() -> some View {
        modifier(ContentCardModifier())
    }
}
