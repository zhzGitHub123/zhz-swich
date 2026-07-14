import Foundation

@MainActor
final class ProviderListStore: ObservableObject {
    @Published private(set) var providers: [ProviderProfile] = []
    @Published var errorMessage: String?

    private var repository: ProviderRepository?

    init(repository: ProviderRepository? = nil) {
        do {
            self.repository = try repository ?? ProviderRepository.applicationSupport()
            load()
        } catch {
            self.repository = nil
            self.providers = ProviderProfile.seedProviders
            self.errorMessage = "无法打开 SwiftData 数据库：\(error.localizedDescription)"
        }
    }

    func add(_ provider: ProviderProfile) throws {
        var next = provider
        if !providers.contains(where: { $0.family == next.family }) {
            next.isActive = true
        }
        next.updatedAt = Date()
        try persist(providers + [next], failurePrefix: "保存供应商失败")
    }

    func clearError() {
        errorMessage = nil
    }

    func update(_ provider: ProviderProfile) throws {
        guard let index = providers.firstIndex(where: { $0.id == provider.id }) else {
            let error = ProviderStoreError.providerNotFound
            errorMessage = error.localizedDescription
            throw error
        }

        var next = provider
        next.updatedAt = Date()
        var nextProviders = providers
        nextProviders[index] = next
        try persist(nextProviders, failurePrefix: "更新供应商失败")
    }

    func duplicate(_ provider: ProviderProfile) throws {
        var copy = provider
        copy.id = UUID()
        copy.name = "\(provider.name) 副本"
        copy.isActive = false
        copy.createdAt = Date()
        copy.updatedAt = copy.createdAt

        // 先在副本数组上插入，persist 成功后才更新内存，失败时内存保持原状
        var nextProviders = providers
        let sourceIndex = providers.firstIndex(where: { $0.id == provider.id })
        let insertionIndex = sourceIndex.map { $0 + 1 } ?? providers.endIndex
        nextProviders.insert(copy, at: insertionIndex)
        try persist(nextProviders, failurePrefix: "复制供应商失败")
    }

    func delete(_ provider: ProviderProfile) throws {
        var nextProviders = providers.filter { $0.id != provider.id }

        let familyHasActiveProvider = nextProviders.contains {
            $0.family == provider.family && $0.isActive
        }
        if provider.isActive,
           !familyHasActiveProvider,
           let replacementIndex = nextProviders.firstIndex(where: { $0.family == provider.family }) {
            nextProviders[replacementIndex].isActive = true
            nextProviders[replacementIndex].updatedAt = Date()
        }

        try persist(nextProviders, failurePrefix: "删除供应商失败")
    }

    func setActive(_ provider: ProviderProfile) throws {
        guard providers.contains(where: { $0.id == provider.id }) else {
            let error = ProviderStoreError.providerNotFound
            errorMessage = error.localizedDescription
            throw error
        }
        guard !provider.isActive else { return }

        var nextProviders = providers
        let now = Date()
        for index in nextProviders.indices where nextProviders[index].family == provider.family {
            let shouldBeActive = nextProviders[index].id == provider.id
            guard nextProviders[index].isActive != shouldBeActive else { continue }
            nextProviders[index].isActive = shouldBeActive
            nextProviders[index].updatedAt = now
        }

        try persist(nextProviders, failurePrefix: "切换供应商失败")
    }

    func markChecked(_ provider: ProviderProfile) throws {
        // 供应商可能已被删除，此时保持原有"无操作"语义，不视为错误
        guard let index = providers.firstIndex(where: { $0.id == provider.id }) else {
            return
        }

        // 先在副本数组上修改，persist 成功后才更新内存，失败时内存保持原状
        var nextProviders = providers
        let now = Date()
        nextProviders[index].lastCheckedAt = now
        nextProviders[index].updatedAt = now
        try persist(nextProviders, failurePrefix: "更新检查时间失败")
    }

    private func load() {
        guard let repository else {
            return
        }

        do {
            let stored = try repository.load()
            let usingSeed = stored.isEmpty
            providers = usingSeed ? ProviderProfile.seedProviders : stored
            let normalized = normalizeActiveProvider()
            if usingSeed || normalized {
                save()
            }
            if let warningMessage = repository.warningMessage {
                errorMessage = warningMessage
            }
        } catch {
            providers = ProviderProfile.seedProviders
            errorMessage = "读取供应商列表失败：\(error.localizedDescription)"
        }
    }

    @discardableResult
    private func normalizeActiveProvider() -> Bool {
        guard !providers.isEmpty else { return false }

        // 按 family 分组归一化：每个 family 各保留一个 active，
        // 与 add/delete/setActive 按 family 各管一个 active 的规则保持一致。
        // 组内优先保留已 active 的第一个；该组没有 active 时回退到组内第一个。
        var targetIDByFamily: [String: UUID] = [:]
        for provider in providers where provider.isActive {
            if targetIDByFamily[provider.family] == nil {
                targetIDByFamily[provider.family] = provider.id
            }
        }
        for provider in providers where targetIDByFamily[provider.family] == nil {
            targetIDByFamily[provider.family] = provider.id
        }

        var changed = false
        for index in providers.indices {
            let shouldBeActive = providers[index].id == targetIDByFamily[providers[index].family]
            guard providers[index].isActive != shouldBeActive else { continue }
            providers[index].isActive = shouldBeActive
            changed = true
        }
        return changed
    }

    private func save() {
        guard let repository else {
            errorMessage = "SwiftData 数据库不可用，当前修改尚未保存。"
            return
        }

        do {
            try repository.save(providers)
        } catch {
            errorMessage = "保存供应商列表失败：\(error.localizedDescription)"
        }
    }

    private func persist(
        _ nextProviders: [ProviderProfile],
        failurePrefix: String
    ) throws {
        guard let repository else {
            let error = ProviderStoreError.databaseUnavailable
            errorMessage = error.localizedDescription
            throw error
        }

        do {
            try repository.save(nextProviders)
            providers = nextProviders
            errorMessage = repository.warningMessage
        } catch {
            errorMessage = "\(failurePrefix)：\(error.localizedDescription)"
            throw error
        }
    }
}

private enum ProviderStoreError: LocalizedError {
    case databaseUnavailable
    case providerNotFound

    var errorDescription: String? {
        switch self {
        case .databaseUnavailable:
            "SwiftData 数据库不可用，操作未完成。"
        case .providerNotFound:
            "找不到需要更新的供应商，数据可能已被删除。"
        }
    }
}
