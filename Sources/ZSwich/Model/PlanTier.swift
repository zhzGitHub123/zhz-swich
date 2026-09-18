import Foundation

/// ChatGPT 套餐等级。
///
/// 取值来自两处且拼写一致：auth.json 里 id_token 的 `chatgpt_plan_type`，以及 /wham/usage 响应的 `plan_type`。
/// 等级顺序与展示名称对照自 ChatGPT.app 内部的套餐文案（app.asar）：
/// free(0) < go(1) < plus(2) < prolite(3) < pro(4)，其中 `prolite` 展示为 "Pro 5x"、`pro` 展示为 "Pro 20x"。
enum PlanTier: String, Sendable, CaseIterable {
    case free
    case go
    case plus
    /// Pro 5x：官方文案 "5x more usage than Plus"。
    case proLite = "prolite"
    /// Pro 20x：官方文案 "20x usage compared to Plus"。
    case pro
    case business
    case team
    case enterprise
    case edu

    /// 容错解析：大小写、下划线连字符、`chatgptproliteplan` 这类带前后缀的写法都能落到同一个等级。
    init?(rawPlan: String?) {
        guard let rawPlan, !rawPlan.isEmpty else { return nil }
        var key = rawPlan.lowercased().filter { $0.isLetter || $0.isNumber }
        if key.hasPrefix("chatgpt") { key.removeFirst("chatgpt".count) }
        if key.hasSuffix("plan") { key.removeLast("plan".count) }
        if let exact = PlanTier(rawValue: key) {
            self = exact
            return
        }
        // 机构类套餐会带 self_serve_business_* 之类的后缀，先于个人档匹配。
        if key.contains("enterprise") { self = .enterprise; return }
        if key.contains("business") { self = .business; return }
        if key.contains("team") { self = .team; return }
        if key.contains("edu") { self = .edu; return }
        // prolite 必须排在 pro 前面，否则会被 pro 吃掉。
        if key.contains("prolite") { self = .proLite; return }
        if key.contains("pro") { self = .pro; return }
        if key.contains("plus") { self = .plus; return }
        if key.contains("free") { self = .free; return }
        return nil
    }

    var label: String {
        switch self {
        case .free: "Free"
        case .go: "Go"
        case .plus: "Plus"
        case .proLite: "Pro 5x"
        case .pro: "Pro 20x"
        case .business: "Business"
        case .team: "Team"
        case .enterprise: "Enterprise"
        case .edu: "Edu"
        }
    }

    /// 个人档的高低顺序，机构档不参与排序。
    var rank: Int {
        switch self {
        case .free: 0
        case .go: 1
        case .plus: 2
        case .proLite: 3
        case .pro: 4
        case .business, .team, .enterprise, .edu: 5
        }
    }
}

extension String {
    /// "plus" → "Plus"，"prolite" → "Pro 5x"，未知取值原样首字母大写。
    var planLabel: String {
        if let tier = PlanTier(rawPlan: self) { return tier.label }
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}
