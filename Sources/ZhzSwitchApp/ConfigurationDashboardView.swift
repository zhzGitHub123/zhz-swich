import Foundation
import SwiftUI

struct ConfigurationDashboard: View {
    @StateObject private var store = ActiveConfigurationStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ModuleHeader(
                title: "仪表台",
                subtitle: "查看 Codex 与 Claude 当前生效的本地配置",
                eyebrow: "概览 / Dashboard",
                actions: [ModuleAction(title: "刷新", icon: "arrow.clockwise")],
                onAction: { _ in store.reload() }
            )

            HStack(alignment: .top, spacing: 18) {
                ActiveConfigurationCard(snapshot: store.codex, tint: .cyan)
                ActiveConfigurationCard(snapshot: store.claude, tint: Color(hex: 0xD97757))
            }
        }
    }
}

private struct ActiveConfigurationCard: View {
    let snapshot: ActiveConfigurationSnapshot
    let tint: Color

    var body: some View {
        NativeLiquidGlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 13) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(tint.opacity(0.16))
                        Image(systemName: snapshot.icon)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(tint)
                    }
                    .frame(width: 46, height: 46)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(snapshot.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.slate900)
                        Text(snapshot.configurationPath)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.slate500)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer(minLength: 8)

                    Label(snapshot.statusTitle, systemImage: snapshot.isAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(snapshot.isAvailable ? Color.green : Color.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background((snapshot.isAvailable ? Color.green : Color.orange).opacity(0.12), in: Capsule())
                }

                Divider().overlay(Color.themeBorder.opacity(0.55))

                if snapshot.items.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(Color.slate500.opacity(0.75))
                        Text(snapshot.message)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.slate600)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 250)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(snapshot.items.enumerated()), id: \.element.id) { index, item in
                            ConfigurationValueRow(item: item)
                            if index < snapshot.items.count - 1 {
                                Divider().overlay(Color.themeBorder.opacity(0.35))
                            }
                        }
                    }
                }
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity, minHeight: 430, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(snapshot.title) 当前生效配置")
    }
}

private struct ConfigurationValueRow: View {
    let item: ActiveConfigurationItem

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 18) {
            Text(item.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.slate500)
                .frame(width: 92, alignment: .leading)

            Text(item.value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.slate800)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 13)
    }
}

private struct ActiveConfigurationItem: Identifiable {
    let label: String
    let value: String
    var id: String { label }
}

private struct ActiveConfigurationSnapshot {
    let title: String
    let icon: String
    let configurationPath: String
    let items: [ActiveConfigurationItem]
    let message: String
    let isAvailable: Bool

    var statusTitle: String { isAvailable ? "当前生效" : "不可用" }
}

@MainActor
private final class ActiveConfigurationStore: ObservableObject {
    @Published private(set) var codex = ActiveConfigurationStore.emptyCodex
    @Published private(set) var claude = ActiveConfigurationStore.emptyClaude

    init() {
        reload()
    }

    func reload() {
        codex = loadCodexConfiguration()
        claude = loadClaudeConfiguration()
    }

    private func loadCodexConfiguration() -> ActiveConfigurationSnapshot {
        let path = "~/.codex/config.toml"
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/config.toml")

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let values = Self.parseTOML(content)
            let provider = values["model_provider"]
            let baseURL = provider.flatMap { values["model_providers.\($0).base_url"] }

            return ActiveConfigurationSnapshot(
                title: "Codex",
                icon: "chevron.left.forwardslash.chevron.right",
                configurationPath: path,
                items: Self.items([
                    ("模型", values["model"]),
                    ("模型提供商", provider),
                    ("基础地址", baseURL),
                    ("推理强度", values["model_reasoning_effort"]),
                    ("服务层级", values["service_tier"]),
                    ("人格", values["personality"]),
                    ("沙箱模式", values["sandbox_mode"])
                ]),
                message: "配置文件中没有可展示的生效字段",
                isAvailable: true
            )
        } catch {
            return Self.failureSnapshot(
                title: "Codex",
                icon: "chevron.left.forwardslash.chevron.right",
                path: path,
                error: error
            )
        }
    }

    private func loadClaudeConfiguration() -> ActiveConfigurationSnapshot {
        let path = "~/.claude/settings.json"
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")

        do {
            let data = try Data(contentsOf: url)
            guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ConfigurationReadError.invalidRoot
            }

            let environment = root["env"] as? [String: Any] ?? [:]
            return ActiveConfigurationSnapshot(
                title: "Claude",
                icon: "sparkles",
                configurationPath: path,
                items: Self.items([
                    ("模型", Self.string(root["model"]) ?? Self.string(environment["ANTHROPIC_MODEL"])),
                    ("推理模型", Self.string(environment["ANTHROPIC_REASONING_MODEL"])),
                    ("基础地址", Self.string(environment["ANTHROPIC_BASE_URL"])),
                    ("推理强度", Self.string(root["effortLevel"]) ?? Self.string(environment["CLAUDE_CODE_EFFORT_LEVEL"])),
                    ("Opus", Self.string(environment["ANTHROPIC_DEFAULT_OPUS_MODEL"])),
                    ("Sonnet", Self.string(environment["ANTHROPIC_DEFAULT_SONNET_MODEL"])),
                    ("Haiku", Self.string(environment["ANTHROPIC_DEFAULT_HAIKU_MODEL"]))
                ]),
                message: "配置文件中没有可展示的生效字段",
                isAvailable: true
            )
        } catch {
            return Self.failureSnapshot(title: "Claude", icon: "sparkles", path: path, error: error)
        }
    }

    private static func parseTOML(_ content: String) -> [String: String] {
        var section = ""
        var values: [String: String] = [:]

        for rawLine in content.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }

            if line.hasPrefix("["), line.hasSuffix("]") {
                section = String(line.dropFirst().dropLast())
                continue
            }

            guard let separator = line.firstIndex(of: "=") else { continue }
            let key = line[..<separator].trimmingCharacters(in: .whitespaces)
            let rawValue = line[line.index(after: separator)...]
                .trimmingCharacters(in: .whitespaces)
            let value = Self.unquote(rawValue)
            values[section.isEmpty ? key : "\(section).\(key)"] = value
        }

        return values
    }

    private static func unquote(_ value: String) -> String {
        guard value.count >= 2 else { return value }
        if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
            (value.hasPrefix("'") && value.hasSuffix("'")) {
            return String(value.dropFirst().dropLast())
        }
        return value
    }

    private static func string(_ value: Any?) -> String? {
        switch value {
        case let value as String where !value.isEmpty:
            value
        case let value as NSNumber:
            value.stringValue
        default:
            nil
        }
    }

    private static func items(_ candidates: [(String, String?)]) -> [ActiveConfigurationItem] {
        candidates.compactMap { label, value in
            guard let value, !value.isEmpty else { return nil }
            return ActiveConfigurationItem(label: label, value: value)
        }
    }

    private static func failureSnapshot(
        title: String,
        icon: String,
        path: String,
        error: Error
    ) -> ActiveConfigurationSnapshot {
        ActiveConfigurationSnapshot(
            title: title,
            icon: icon,
            configurationPath: path,
            items: [],
            message: "读取失败：\(error.localizedDescription)",
            isAvailable: false
        )
    }

    private static let emptyCodex = ActiveConfigurationSnapshot(
        title: "Codex",
        icon: "chevron.left.forwardslash.chevron.right",
        configurationPath: "~/.codex/config.toml",
        items: [],
        message: "正在读取配置…",
        isAvailable: false
    )

    private static let emptyClaude = ActiveConfigurationSnapshot(
        title: "Claude",
        icon: "sparkles",
        configurationPath: "~/.claude/settings.json",
        items: [],
        message: "正在读取配置…",
        isAvailable: false
    )
}

private enum ConfigurationReadError: LocalizedError {
    case invalidRoot

    var errorDescription: String? {
        switch self {
        case .invalidRoot:
            "配置文件根节点不是对象"
        }
    }
}
