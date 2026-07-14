import Foundation

public struct SubscriptionProfile: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var target: TargetApp
    public var urlReference: SecretReference
    public var note: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        target: TargetApp,
        urlReference: SecretReference,
        note: String = "",
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.target = target
        self.urlReference = urlReference
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }
}

public struct SecretReference: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public enum MaskedSubscriptionURL {
    public static func mask(_ rawValue: String) -> String {
        guard
            let components = URLComponents(string: rawValue),
            let scheme = components.scheme,
            let host = components.host,
            !scheme.isEmpty,
            !host.isEmpty
        else {
            return "无效地址"
        }

        let pathTail = components.percentEncodedPath
            .split(separator: "/")
            .last
            .map { String($0.suffix(4)) }

        let tail = pathTail ?? String(host.suffix(4))
        return "\(scheme)://\(host)/...\(tail)"
    }
}
