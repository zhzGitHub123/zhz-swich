import Foundation
#if canImport(ZhzSwitchCore)
import ZhzSwitchCore
#endif

@MainActor
final class SkillListStore: ObservableObject {
    @Published private(set) var skills: [SkillRecord] = []
    @Published var searchText = ""
    @Published var errorMessage: String?

    private let repository: SkillRepository
    private(set) var target: TargetApp = .codex

    init(repository: SkillRepository = SkillRepository()) {
        self.repository = repository
    }

    var filteredSkills: [SkillRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return skills }
        return skills.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.directoryName.localizedCaseInsensitiveContains(query)
                || $0.summary.localizedCaseInsensitiveContains(query)
        }
    }

    var enabledCount: Int {
        skills.count(where: \.isEnabled)
    }

    var disabledCount: Int {
        skills.count - enabledCount
    }

    var systemCount: Int {
        skills.count(where: \.isReadOnly)
    }

    func load(target: TargetApp) {
        self.target = target
        refresh()
    }

    func refresh() {
        do {
            let snapshot = try repository.load(target: target)
            skills = snapshot.skills
            errorMessage = snapshot.warnings.isEmpty
                ? nil
                : snapshot.warnings.prefix(3).joined(separator: "\n")
        } catch {
            skills = []
            errorMessage = "读取技能失败：\(error.localizedDescription)"
        }
    }

    func toggle(_ skill: SkillRecord) {
        do {
            try repository.setEnabled(!skill.isEnabled, for: skill)
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func install(from directory: URL) {
        do {
            try repository.install(from: directory, target: target)
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func activeDirectory() -> URL {
        repository.activeDirectory(for: target)
    }
}
