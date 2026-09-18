import Foundation

/// 从 auth.json 里解出来的身份信息，只读、不含令牌本身。
struct AccountIdentity: Hashable, Sendable {
    var accountID: String
    var email: String
    var name: String?
    var planType: String?
    var subscriptionUntil: Date?
    var accessTokenExpiry: Date?
    var lastRefresh: Date?

    private static let claimNamespace = "https://api.openai.com/auth"

    static func parse(authJSON data: Data) throws -> AccountIdentity {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ZSwichError.invalidAuthFile("不是合法的 JSON 对象")
        }
        guard let tokens = root["tokens"] as? [String: Any] else {
            throw ZSwichError.invalidAuthFile("缺少 tokens 字段（可能是 API Key 登录模式）")
        }
        guard let idToken = tokens["id_token"] as? String, let claims = JWT.payload(idToken) else {
            throw ZSwichError.invalidAuthFile("id_token 缺失或无法解码")
        }
        let auth = claims[claimNamespace] as? [String: Any] ?? [:]
        let accountID = (auth["chatgpt_account_id"] as? String) ?? (tokens["account_id"] as? String)
        guard let accountID, !accountID.isEmpty else {
            throw ZSwichError.invalidAuthFile("缺少 chatgpt_account_id")
        }

        var accessExpiry: Date?
        if let accessToken = tokens["access_token"] as? String,
           let payload = JWT.payload(accessToken),
           let exp = payload["exp"] as? Double {
            accessExpiry = Date(timeIntervalSince1970: exp)
        }

        return AccountIdentity(
            accountID: accountID,
            email: claims["email"] as? String ?? "(未知邮箱)",
            name: claims["name"] as? String,
            planType: auth["chatgpt_plan_type"] as? String,
            subscriptionUntil: parseDate(auth["chatgpt_subscription_active_until"]),
            accessTokenExpiry: accessExpiry,
            lastRefresh: parseDate(root["last_refresh"])
        )
    }

    /// 令牌里的日期字段格式不统一：可能是 ISO8601 字符串，也可能是秒级时间戳。
    private static func parseDate(_ value: Any?) -> Date? {
        switch value {
        case let seconds as Double:
            return Date(timeIntervalSince1970: seconds)
        case let text as String:
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: text) { return date }
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            return plain.date(from: text)
        default:
            return nil
        }
    }
}
