import Foundation

/// 账号索引里的一条记录，令牌本体在 snapshots 目录，这里只有可展示的元数据。
struct AccountRecord: Codable, Identifiable, Hashable, Sendable {
    /// 即 chatgpt_account_id。
    var id: String
    var email: String
    var name: String?
    var planType: String?
    var subscriptionUntil: Date?
    var accessTokenExpiry: Date?
    var lastRefresh: Date?
    var addedAt: Date
    var lastSavedAt: Date
    var lastUsedAt: Date?

    init(identity: AccountIdentity, now: Date = .now) {
        id = identity.accountID
        email = identity.email
        name = identity.name
        planType = identity.planType
        subscriptionUntil = identity.subscriptionUntil
        accessTokenExpiry = identity.accessTokenExpiry
        lastRefresh = identity.lastRefresh
        addedAt = now
        lastSavedAt = now
        lastUsedAt = now
    }

    mutating func update(from identity: AccountIdentity, now: Date = .now) {
        refreshMetadata(from: identity)
        lastSavedAt = now
    }

    mutating func refreshMetadata(from identity: AccountIdentity) {
        email = identity.email
        name = identity.name
        planType = identity.planType
        subscriptionUntil = identity.subscriptionUntil
        accessTokenExpiry = identity.accessTokenExpiry
        lastRefresh = identity.lastRefresh
    }

    var planLabel: String { planType?.planLabel ?? "未知套餐" }
}
