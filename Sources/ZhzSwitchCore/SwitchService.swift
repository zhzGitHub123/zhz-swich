import Foundation

public struct SwitchService {
    private let adapter: any TargetAdapter

    public init(adapter: any TargetAdapter) {
        self.adapter = adapter
    }

    public func apply(profile: SubscriptionProfile, subscriptionURL: String) throws -> SwitchResult {
        guard profile.target == adapter.target else {
            throw SwitchError.targetMismatch(expected: profile.target, actual: adapter.target)
        }

        guard Self.isValidSubscriptionURL(subscriptionURL) else {
            throw SwitchError.invalidSubscriptionURL(subscriptionURL)
        }

        let current: CurrentSubscription
        do {
            current = try adapter.readCurrentSubscription()
        } catch {
            throw SwitchError.readFailed(Self.message(from: error))
        }

        if current.value == subscriptionURL {
            return SwitchResult(
                status: .unchanged,
                target: adapter.target,
                profileID: profile.id,
                backup: nil
            )
        }

        let backup: BackupRecord
        do {
            backup = try adapter.backupCurrentConfiguration()
        } catch {
            throw SwitchError.backupFailed(Self.message(from: error))
        }

        do {
            try adapter.write(subscriptionURL: subscriptionURL)
        } catch {
            throw SwitchError.writeFailed(Self.message(from: error))
        }

        let verification: VerificationResult
        do {
            verification = try adapter.verify(subscriptionURL: subscriptionURL)
        } catch {
            throw SwitchError.verificationFailed(expected: subscriptionURL, actual: nil)
        }

        switch verification {
        case .matched:
            return SwitchResult(
                status: .switched,
                target: adapter.target,
                profileID: profile.id,
                backup: backup
            )
        case let .mismatched(actual):
            throw SwitchError.verificationFailed(expected: subscriptionURL, actual: actual)
        }
    }

    private static func isValidSubscriptionURL(_ rawValue: String) -> Bool {
        guard
            let components = URLComponents(string: rawValue),
            let scheme = components.scheme,
            let host = components.host
        else {
            return false
        }

        return ["http", "https"].contains(scheme.lowercased()) && !host.isEmpty
    }

    private static func message(from error: Error) -> String {
        String(describing: error)
    }
}
