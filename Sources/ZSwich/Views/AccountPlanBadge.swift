import SwiftUI

struct AccountPlanBadge: View {
    let account: AccountRecord

    var body: some View {
        Label(account.planLabel, systemImage: account.planType.planSystemImage)
            .font(.caption)
            .labelStyle(.titleAndIcon)
            .imageScale(.small)
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(foreground.opacity(0.12), in: .rect(cornerRadius: 5))
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(foreground.opacity(0.25), lineWidth: 1)
            }
    }

    private var foreground: Color { account.planType.planTint }
}
