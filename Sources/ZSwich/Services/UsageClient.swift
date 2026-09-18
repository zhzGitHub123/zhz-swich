import Foundation

struct UsageClient: UsageFetching {
    private static let endpoint = URL(string: "https://chatgpt.com/backend-api/wham/usage")

    /// 不接磁盘响应缓存：系统默认会把带 Authorization 头的请求整条写进 Caches/Cache.db。
    /// Cookie 仍走系统默认存储，只有 Cloudflare 的设备级 Cookie，与账号无关，保留以维持现有行为。
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCredentialStorage = nil
        configuration.timeoutIntervalForRequest = 15
        return URLSession(configuration: configuration)
    }()

    func fetchUsage(credentials: UsageCredentials) async throws -> UsageSnapshot {
        guard let endpoint = Self.endpoint else {
            throw ZSwichError.usageInvalidResponse
        }
        var request = URLRequest(
            url: endpoint,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 15
        )
        request.httpMethod = "GET"
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(credentials.accountID, forHTTPHeaderField: "ChatGPT-Account-Id")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Z-Swich/0.1", forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await Self.session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw ZSwichError.usageTimeout
        } catch {
            throw ZSwichError.usageNetwork(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ZSwichError.usageInvalidResponse
        }
        switch httpResponse.statusCode {
        case 200..<300:
            return try parse(data)
        case 401, 403:
            throw ZSwichError.usageUnauthorized
        default:
            throw ZSwichError.usageHTTP(httpResponse.statusCode)
        }
    }

    private func parse(_ data: Data) throws -> UsageSnapshot {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rateLimit = root["rate_limit"] as? [String: Any] else {
            throw ZSwichError.usageInvalidResponse
        }
        return UsageSnapshot(
            primaryWindow: parseWindow(rateLimit["primary_window"]),
            secondaryWindow: parseWindow(rateLimit["secondary_window"]),
            planType: root["plan_type"] as? String,
            fetchedAt: .now
        )
    }

    private func parseWindow(_ value: Any?) -> UsageWindow? {
        guard let window = value as? [String: Any],
              let usedPercent = (window["used_percent"] as? NSNumber)?.doubleValue,
              let duration = (window["limit_window_seconds"] as? NSNumber)?.doubleValue,
              let resetTimestamp = (window["reset_at"] as? NSNumber)?.doubleValue else {
            return nil
        }
        return UsageWindow(
            usedPercent: usedPercent,
            duration: duration,
            resetAt: Date(timeIntervalSince1970: resetTimestamp)
        )
    }
}
