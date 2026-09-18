import Foundation

enum AuthCredentialsStore {
    /// Codex 默认使用 file。显式配置为 keyring/auto 时不操作，避免切换错误的凭证来源。
    static func requireFileMode() throws {
        guard let contents = try? String(contentsOf: Paths.codexConfigFile, encoding: .utf8) else {
            return
        }

        for rawLine in contents.split(whereSeparator: \.isNewline) {
            let withoutComment = rawLine.split(separator: "#", maxSplits: 1).first ?? rawLine[...]
            let parts = withoutComment.split(separator: "=", maxSplits: 1)
            guard parts.count == 2,
                  parts[0].trimmingCharacters(in: .whitespaces) == "cli_auth_credentials_store" else {
                continue
            }
            let mode = parts[1]
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            guard mode == "file" else {
                throw ZSwichError.unsupportedCredentialsStore(mode)
            }
            return
        }
    }

    /// 当前挂载账号的凭证（读 auth.json）。
    static func loadUsageCredentials() throws -> UsageCredentials {
        try requireFileMode()
        guard let data = try? Data(contentsOf: Paths.authFile) else {
            throw ZSwichError.usageCredentialsMissing
        }
        return try usageCredentials(inAuthJSON: data)
    }

    /// 已保存快照的凭证。额度接口只认 access_token + account id，与本机挂载的是谁无关，
    /// 所以不切换账号也能查别的账号额度。快照是本 App 自己写的，不需要再查 config 的存储模式。
    static func usageCredentials(snapshotAt url: URL) throws -> UsageCredentials {
        guard let data = try? Data(contentsOf: url) else {
            throw ZSwichError.usageCredentialsMissing
        }
        return try usageCredentials(inAuthJSON: data)
    }

    private static func usageCredentials(inAuthJSON data: Data) throws -> UsageCredentials {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = root["tokens"] as? [String: Any],
              let accessToken = tokens["access_token"] as? String,
              !accessToken.isEmpty else {
            throw ZSwichError.usageCredentialsMissing
        }
        // account id 以 id_token 里的 chatgpt_account_id 为准，tokens.account_id 只作兜底。
        let accountID = (try? AccountIdentity.parse(authJSON: data))?.accountID
            ?? (tokens["account_id"] as? String)
        guard let accountID, !accountID.isEmpty else {
            throw ZSwichError.usageCredentialsMissing
        }
        return UsageCredentials(accessToken: accessToken, accountID: accountID)
    }
}
