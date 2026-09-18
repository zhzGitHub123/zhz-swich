import SwiftUI

struct ActiveAccountIdentity: View {
    let store: AccountStore

    @State private var avatarHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [ZSwichTheme.accent, .purple, .pink],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
                .frame(width: 66, height: 66)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ZSwichTheme.canvas)
                        .padding(2)
                        .overlay {
                            Image(systemName: "person.3.fill")
                                .font(.title)
                                .foregroundStyle(ZSwichTheme.accent)
                                .scaleEffect(avatarHovered && !reduceMotion ? 1.12 : 1)
                                .symbolEffect(.bounce, options: .nonRepeating, value: avatarHovered)
                        }
                }
                .shadow(
                    color: ZSwichTheme.accent.opacity(avatarHovered ? 0.48 : 0.28),
                    radius: avatarHovered ? 22 : 16
                )
                .scaleEffect(avatarHovered && !reduceMotion ? 1.06 : 1)
                .rotation3DEffect(
                    .degrees(avatarHovered && !reduceMotion ? 5 : 0),
                    axis: (x: 0.25, y: 1, z: 0)
                )
                .background {
                    RoundedRectangle(cornerRadius: 23)
                        .fill(ZSwichTheme.accent.opacity(avatarHovered ? 0.20 : 0))
                        .frame(width: 78, height: 78)
                        .blur(radius: 8)
                }
                .overlay(alignment: .bottomTrailing) {
                    StatusPulseDot(
                        color: store.chatGPTRunning
                            ? Color(red: 0.063, green: 0.725, blue: 0.506)
                            : .secondary,
                        haloColor: store.chatGPTRunning
                            ? Color(red: 0.204, green: 0.827, blue: 0.600)
                            : .secondary,
                        size: 12,
                        emphasized: true
                    )
                    .offset(x: 0, y: 0)
                }
                .contentShape(.rect)
                .onHover { avatarHovered = $0 }
                .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: avatarHovered)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text("当前已挂载账号")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(ZSwichTheme.accent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(ZSwichTheme.accent.opacity(0.14), in: .rect(cornerRadius: 6))

                    if let plan = store.currentPlanType {
                        Label(plan.planLabel, systemImage: plan.planSystemImage)
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: plan.planGradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: .rect(cornerRadius: 6)
                            )
                            .symbolEffect(.bounce, options: .nonRepeating, value: avatarHovered)
                    }
                }

                HStack(spacing: 8) {
                    Text(store.current?.email ?? store.currentProblem ?? "当前账号未知")
                        .font(.title3)
                        .bold()
                        .lineLimit(1)
                        .textSelection(.enabled)
                    if let name = store.current?.name, !name.isEmpty {
                        Text("别名：\(name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.07), in: .capsule)
                    }
                }

                HStack(spacing: 8) {
                    StatusPulseDot(color: store.chatGPTRunning ? .green : .secondary, size: 4)
                    Text(store.chatGPTRunning ? "ChatGPT 官方客户端运行正常" : "ChatGPT 官方客户端未运行")
                    if let date = store.current?.subscriptionUntil {
                        Text("•")
                        Text("订阅至 \(date, format: .dateTime.year().month().day())")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}
