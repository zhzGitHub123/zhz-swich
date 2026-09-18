import SwiftUI

struct AccountAvatar: View {
    let account: AccountRecord
    let isCurrent: Bool

    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: avatarColors,
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
                .frame(width: 34, height: 34)
                .overlay {
                    Text(initials)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.white)
                }
                .shadow(color: avatarColors.first?.opacity(isHovered ? 0.48 : 0) ?? .clear, radius: 9)
                .scaleEffect(isHovered && !reduceMotion ? 1.10 : 1)
                .rotationEffect(.degrees(isHovered && !reduceMotion ? -3 : 0))

            Circle()
                .fill(isCurrent ? Color.green : Color.secondary)
                .frame(width: 9, height: 9)
                .overlay { Circle().stroke(ZSwichTheme.card, lineWidth: 2) }
                .scaleEffect(isHovered && !reduceMotion ? 1.16 : 1)
        }
        .frame(width: 38, height: 38)
        .contentShape(.circle)
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .snappy(duration: 0.24), value: isHovered)
        .accessibilityHidden(true)
    }

    private var initials: String {
        let source = account.name?.isEmpty == false ? account.name! : account.email
        let parts = source.split(whereSeparator: { $0 == " " || $0 == "@" || $0 == "." })
        let letters = parts.prefix(2).compactMap(\.first)
        return String(letters).uppercased()
    }

    private var avatarColors: [Color] { account.planType.planGradientColors }
}
