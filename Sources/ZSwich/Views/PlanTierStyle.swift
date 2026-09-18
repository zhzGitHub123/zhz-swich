import SwiftUI

/// 套餐等级的统一视觉语言：徽标、头像、表格行都从这里取色，禁止在单个视图里另写一套。
extension PlanTier {
    /// 扁平底色（表格徽标、描边）。
    var tint: Color {
        switch self {
        case .free: Color(red: 0.62, green: 0.67, blue: 0.76)
        case .go: Color(red: 0.25, green: 0.82, blue: 0.72)
        case .plus: Color(red: 0.66, green: 0.48, blue: 0.98)
        case .proLite: Color(red: 1.00, green: 0.72, blue: 0.27)
        case .pro: Color(red: 1.00, green: 0.45, blue: 0.62)
        case .business, .team, .enterprise, .edu: Color(red: 0.34, green: 0.76, blue: 0.96)
        }
    }

    /// 渐变（Hero 徽标、头像底），从左到右。
    var gradientColors: [Color] {
        switch self {
        case .free:
            [Color(red: 0.55, green: 0.60, blue: 0.70), Color(red: 0.31, green: 0.36, blue: 0.45)]
        case .go:
            [Color(red: 0.31, green: 0.86, blue: 0.74), Color(red: 0.16, green: 0.62, blue: 0.72)]
        case .plus:
            [.purple, ZSwichTheme.accent]
        case .proLite:
            [Color(red: 1.00, green: 0.78, blue: 0.33), Color(red: 0.98, green: 0.53, blue: 0.20)]
        case .pro:
            [Color(red: 1.00, green: 0.83, blue: 0.42), Color(red: 0.98, green: 0.33, blue: 0.55)]
        case .business, .team, .enterprise, .edu:
            [.cyan, .blue]
        }
    }

    var systemImage: String {
        switch self {
        case .free: "person.fill"
        case .go: "bolt.fill"
        case .plus: "star.fill"
        case .proLite: "sparkles"
        case .pro: "crown.fill"
        case .business, .team, .enterprise: "building.2.fill"
        case .edu: "graduationcap.fill"
        }
    }
}

/// 从 planType 原始字符串取视觉信息，未知套餐回落到中性灰。
extension String {
    var planTier: PlanTier? { PlanTier(rawPlan: self) }
    var planTint: Color { planTier?.tint ?? .secondary }
    var planGradientColors: [Color] {
        planTier?.gradientColors ?? [.gray, Color(red: 0.25, green: 0.31, blue: 0.40)]
    }
    var planSystemImage: String { planTier?.systemImage ?? "person.fill" }
}

extension Optional where Wrapped == String {
    var planTier: PlanTier? { self?.planTier }
    var planTint: Color { self?.planTint ?? .secondary }
    var planGradientColors: [Color] {
        self?.planGradientColors ?? [.gray, Color(red: 0.25, green: 0.31, blue: 0.40)]
    }
    var planSystemImage: String { self?.planSystemImage ?? "person.fill" }
}
