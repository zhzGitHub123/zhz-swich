import Foundation

protocol UsageFetching: Sendable {
    func fetchUsage(credentials: UsageCredentials) async throws -> UsageSnapshot
}
