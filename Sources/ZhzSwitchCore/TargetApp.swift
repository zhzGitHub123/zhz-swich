public enum TargetApp: String, Codable, CaseIterable, Equatable, Sendable {
    case codex
    case claude

    public var displayName: String {
        switch self {
        case .codex:
            "Codex"
        case .claude:
            "Claude"
        }
    }
}
