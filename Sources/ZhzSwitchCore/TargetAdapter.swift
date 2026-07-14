import Foundation

public protocol TargetAdapter {
    var target: TargetApp { get }

    func readCurrentSubscription() throws -> CurrentSubscription
    func backupCurrentConfiguration() throws -> BackupRecord
    func write(subscriptionURL: String) throws
    func verify(subscriptionURL: String) throws -> VerificationResult
}

public struct CurrentSubscription: Equatable, Sendable {
    public var value: String?

    public init(value: String?) {
        self.value = value
    }
}

public struct BackupRecord: Equatable, Sendable {
    public var location: URL
    public var createdAt: Date

    public init(location: URL, createdAt: Date = Date()) {
        self.location = location
        self.createdAt = createdAt
    }
}

public enum VerificationResult: Equatable, Sendable {
    case matched
    case mismatched(actual: String?)
}

public enum SwitchStatus: Equatable, Sendable {
    case switched
    case unchanged
}

public struct SwitchResult: Equatable, Sendable {
    public var status: SwitchStatus
    public var target: TargetApp
    public var profileID: UUID
    public var backup: BackupRecord?

    public init(
        status: SwitchStatus,
        target: TargetApp,
        profileID: UUID,
        backup: BackupRecord?
    ) {
        self.status = status
        self.target = target
        self.profileID = profileID
        self.backup = backup
    }
}
