import Foundation

public struct ProfileRepository {
    private let store: JSONArrayFileStore<SubscriptionProfile>

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.store = JSONArrayFileStore(fileURL: fileURL, fileManager: fileManager)
    }

    public func load() throws -> [SubscriptionProfile] {
        try store.load()
    }

    public func save(_ profiles: [SubscriptionProfile]) throws {
        try store.save(profiles)
    }
}
