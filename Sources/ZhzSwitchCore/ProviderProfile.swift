import Foundation

public struct ProviderProfile: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var family: String
    public var name: String
    public var baseURL: String
    public var note: String
    public var officialURL: String
    public var apiKey: String
    public var configurationJSON: String
    public var writesGeneralConfiguration: Bool
    public var usesStandaloneBillingConfiguration: Bool
    public var avatarText: String
    public var supportsRouting: Bool
    public var usesFullURL: Bool
    public var isActive: Bool
    public var balance: Double?
    public var currency: String
    public var lastCheckedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case family
        case name
        case baseURL
        case note
        case officialURL
        case apiKey
        case configurationJSON
        case writesGeneralConfiguration
        case usesStandaloneBillingConfiguration
        case avatarText
        case supportsRouting
        case usesFullURL
        case isActive
        case balance
        case currency
        case lastCheckedAt
        case createdAt
        case updatedAt
    }

    public init(
        id: UUID = UUID(),
        family: String = "codex",
        name: String,
        baseURL: String,
        note: String = "",
        officialURL: String = "",
        apiKey: String = "",
        configurationJSON: String = "{\n  \"env\" : {\n\n  },\n  \"includeCoAuthoredBy\" : false\n}",
        writesGeneralConfiguration: Bool = true,
        usesStandaloneBillingConfiguration: Bool = false,
        avatarText: String,
        supportsRouting: Bool = true,
        usesFullURL: Bool = false,
        isActive: Bool = false,
        balance: Double? = nil,
        currency: String = "USD",
        lastCheckedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.family = family
        self.name = name
        self.baseURL = baseURL
        self.note = note
        self.officialURL = officialURL
        self.apiKey = apiKey
        self.configurationJSON = configurationJSON
        self.writesGeneralConfiguration = writesGeneralConfiguration
        self.usesStandaloneBillingConfiguration = usesStandaloneBillingConfiguration
        self.avatarText = avatarText
        self.supportsRouting = supportsRouting
        self.usesFullURL = usesFullURL
        self.isActive = isActive
        self.balance = balance
        self.currency = currency
        self.lastCheckedAt = lastCheckedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        family = try container.decodeIfPresent(String.self, forKey: .family) ?? "codex"
        name = try container.decode(String.self, forKey: .name)
        baseURL = try container.decode(String.self, forKey: .baseURL)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        officialURL = try container.decodeIfPresent(String.self, forKey: .officialURL) ?? ""
        apiKey = try container.decodeIfPresent(String.self, forKey: .apiKey) ?? ""
        configurationJSON = try container.decodeIfPresent(String.self, forKey: .configurationJSON) ?? "{\n  \"env\" : {\n\n  },\n  \"includeCoAuthoredBy\" : false\n}"
        writesGeneralConfiguration = try container.decodeIfPresent(Bool.self, forKey: .writesGeneralConfiguration) ?? true
        usesStandaloneBillingConfiguration = try container.decodeIfPresent(Bool.self, forKey: .usesStandaloneBillingConfiguration) ?? false
        avatarText = try container.decode(String.self, forKey: .avatarText)
        supportsRouting = try container.decode(Bool.self, forKey: .supportsRouting)
        usesFullURL = try container.decodeIfPresent(Bool.self, forKey: .usesFullURL) ?? false
        isActive = try container.decode(Bool.self, forKey: .isActive)
        balance = try container.decodeIfPresent(Double.self, forKey: .balance)
        currency = try container.decode(String.self, forKey: .currency)
        lastCheckedAt = try container.decodeIfPresent(Date.self, forKey: .lastCheckedAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public var normalizedBaseURL: String {
        baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isValidURL: Bool {
        guard
            let components = URLComponents(string: normalizedBaseURL),
            let scheme = components.scheme?.lowercased(),
            let host = components.host,
            !host.isEmpty
        else {
            return false
        }

        return scheme == "https" || scheme == "http"
    }

    public static let seedProviders: [ProviderProfile] = [
        ProviderProfile(
            name: "OpenAI Official",
            baseURL: "https://chatgpt.com/codex",
            avatarText: "AI",
            supportsRouting: false,
            isActive: true
        ),
        ProviderProfile(
            name: "薄荷",
            baseURL: "https://x666.me",
            avatarText: "薄"
        ),
        ProviderProfile(
            name: "冰のCodex",
            baseURL: "https://icoe.pp.ua",
            avatarText: "冰",
            balance: 0,
            lastCheckedAt: Date()
        ),
        ProviderProfile(
            name: "君的",
            baseURL: "https://muyuan.do",
            avatarText: "君"
        ),
        ProviderProfile(
            name: "免费公益站",
            baseURL: "https://free.lyclaude.site/v1",
            avatarText: "免"
        )
    ]
}
