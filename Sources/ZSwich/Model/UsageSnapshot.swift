import Foundation

struct UsageSnapshot: Hashable, Sendable {
    let primaryWindow: UsageWindow?
    let secondaryWindow: UsageWindow?
    /// 服务器认定的套餐，比 id_token 里的 chatgpt_plan_type 更实时（升降级后无需等令牌轮转）。
    let planType: String?
    let fetchedAt: Date

    var windows: [UsageWindow] {
        [primaryWindow, secondaryWindow].compactMap(\.self)
    }
}
