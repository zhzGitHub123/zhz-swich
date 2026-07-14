import Foundation
import SwiftData

/// 仅用于把旧版 JSON 数据一次性迁移到 SwiftData。
struct JSONArrayFileStore<Value: Codable> {
    let fileURL: URL
    let fileManager: FileManager

    func load() throws -> [Value] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else {
            return []
        }

        return try JSONDecoder().decode([Value].self, from: data)
    }

    func save(_ values: [Value]) throws {
        let parentURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: parentURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(values)
        let temporaryURL = parentURL.appendingPathComponent(
            ".\(fileURL.lastPathComponent).\(UUID().uuidString).tmp",
            isDirectory: false
        )

        try data.write(to: temporaryURL, options: .atomic)

        if fileManager.fileExists(atPath: fileURL.path) {
            _ = try fileManager.replaceItemAt(fileURL, withItemAt: temporaryURL)
        } else {
            try fileManager.moveItem(at: temporaryURL, to: fileURL)
        }
    }
}

@Model
public final class ProviderRecord {
    @Attribute(.unique) public var id: UUID
    public var family: String?
    public var sortOrder: Int
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

    public init(profile: ProviderProfile, sortOrder: Int) {
        id = profile.id
        family = profile.family
        self.sortOrder = sortOrder
        name = profile.name
        baseURL = profile.baseURL
        note = profile.note
        officialURL = profile.officialURL
        apiKey = profile.apiKey
        configurationJSON = profile.configurationJSON
        writesGeneralConfiguration = profile.writesGeneralConfiguration
        usesStandaloneBillingConfiguration = profile.usesStandaloneBillingConfiguration
        avatarText = profile.avatarText
        supportsRouting = profile.supportsRouting
        usesFullURL = profile.usesFullURL
        isActive = profile.isActive
        balance = profile.balance
        currency = profile.currency
        lastCheckedAt = profile.lastCheckedAt
        createdAt = profile.createdAt
        updatedAt = profile.updatedAt
    }

    func update(from profile: ProviderProfile, sortOrder: Int) {
        self.sortOrder = sortOrder
        family = profile.family
        name = profile.name
        baseURL = profile.baseURL
        note = profile.note
        officialURL = profile.officialURL
        apiKey = profile.apiKey
        configurationJSON = profile.configurationJSON
        writesGeneralConfiguration = profile.writesGeneralConfiguration
        usesStandaloneBillingConfiguration = profile.usesStandaloneBillingConfiguration
        avatarText = profile.avatarText
        supportsRouting = profile.supportsRouting
        usesFullURL = profile.usesFullURL
        isActive = profile.isActive
        balance = profile.balance
        currency = profile.currency
        lastCheckedAt = profile.lastCheckedAt
        createdAt = profile.createdAt
        updatedAt = profile.updatedAt
    }

    var profile: ProviderProfile {
        ProviderProfile(
            id: id,
            family: family ?? "codex",
            name: name,
            baseURL: baseURL,
            note: note,
            officialURL: officialURL,
            apiKey: apiKey,
            configurationJSON: configurationJSON,
            writesGeneralConfiguration: writesGeneralConfiguration,
            usesStandaloneBillingConfiguration: usesStandaloneBillingConfiguration,
            avatarText: avatarText,
            supportsRouting: supportsRouting,
            usesFullURL: usesFullURL,
            isActive: isActive,
            balance: balance,
            currency: currency,
            lastCheckedAt: lastCheckedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@MainActor
public final class ProviderRepository {
    private static let migrationKey = "storage.provider.swiftDataMigration.completed"

    public private(set) var warningMessage: String?

    private let modelContext: ModelContext
    private let legacyStore: JSONArrayFileStore<ProviderProfile>?
    private let migrationDefaults: UserDefaults

    public init(
        modelContainer: ModelContainer,
        legacyFileURL: URL? = nil,
        fileManager: FileManager = .default,
        migrationDefaults: UserDefaults = .standard
    ) {
        modelContext = ModelContext(modelContainer)
        modelContext.autosaveEnabled = false
        legacyStore = legacyFileURL.map {
            JSONArrayFileStore(fileURL: $0, fileManager: fileManager)
        }
        self.migrationDefaults = migrationDefaults
    }

    public static func applicationSupport(
        fileManager: FileManager = .default
    ) throws -> ProviderRepository {
        let directory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("zhz-swich", isDirectory: true)

        let container = try ModelContainer(for: ProviderRecord.self)
        return ProviderRepository(
            modelContainer: container,
            legacyFileURL: directory.appendingPathComponent("providers.json"),
            fileManager: fileManager
        )
    }

    public func load() throws -> [ProviderProfile] {
        let descriptor = FetchDescriptor<ProviderRecord>(
            sortBy: [SortDescriptor(\ProviderRecord.sortOrder)]
        )
        let records = try modelContext.fetch(descriptor)

        if !records.isEmpty {
            migrationDefaults.set(true, forKey: Self.migrationKey)
            removeLegacyFileIfNeeded()
            return records.map(\.profile)
        }

        guard !migrationDefaults.bool(forKey: Self.migrationKey) else {
            removeLegacyFileIfNeeded()
            return []
        }

        let legacyProviders = try legacyStore?.load() ?? []
        if !legacyProviders.isEmpty {
            try save(legacyProviders)
        }
        migrationDefaults.set(true, forKey: Self.migrationKey)
        removeLegacyFileIfNeeded()
        return legacyProviders
    }

    public func save(_ providers: [ProviderProfile]) throws {
        do {
            let storedRecords = try modelContext.fetch(FetchDescriptor<ProviderRecord>())
            var recordsByID = Dictionary(uniqueKeysWithValues: storedRecords.map { ($0.id, $0) })
            let providerIDs = Set(providers.map(\.id))

            for (sortOrder, provider) in providers.enumerated() {
                if let record = recordsByID.removeValue(forKey: provider.id) {
                    record.update(from: provider, sortOrder: sortOrder)
                } else {
                    modelContext.insert(ProviderRecord(profile: provider, sortOrder: sortOrder))
                }
            }

            for record in storedRecords where !providerIDs.contains(record.id) {
                modelContext.delete(record)
            }

            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func removeLegacyFileIfNeeded() {
        guard
            let legacyStore,
            legacyStore.fileManager.fileExists(atPath: legacyStore.fileURL.path)
        else {
            warningMessage = nil
            return
        }

        do {
            try legacyStore.fileManager.removeItem(at: legacyStore.fileURL)
            warningMessage = nil
        } catch {
            warningMessage = "删除旧供应商 JSON 失败：\(error.localizedDescription)"
        }
    }
}
