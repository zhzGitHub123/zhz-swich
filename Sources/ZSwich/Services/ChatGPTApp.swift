import AppKit
import Foundation

/// 控制 ChatGPT.app 的启停。只做优雅退出，绝不强杀，避免损坏本地会话数据库。
@MainActor
enum ChatGPTApp {
    static let bundleID = "com.openai.codex"

    static var running: NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first
    }

    static var isRunning: Bool { running != nil }

    static var appURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    /// 发送标准 Quit 事件，然后等待进程真正结束。
    /// 等待期间不轮询：通过 KVO 监听 isTerminated，进程退出时系统主动通知；另起一个超时闹钟兜底。
    static func quit(timeout: Duration = .seconds(20)) async throws {
        guard let app = running else { return }
        app.terminate()
        let exited = await TerminationWaiter().wait(for: app, timeout: timeout)
        guard exited else { throw ZSwichError.quitTimeout }
        // 进程退出后再留一点时间让文件句柄释放。
        try? await Task.sleep(for: .milliseconds(300))
    }

    static func launch() async throws {
        guard let url = appURL else { throw ZSwichError.chatGPTNotInstalled }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

/// 把"进程退出"的 KVO 通知和超时闹钟收敛成一次 await；两边谁先到都只恢复一次。
@MainActor
private final class TerminationWaiter {
    private var continuation: CheckedContinuation<Bool, Never>?
    private var observation: NSKeyValueObservation?
    private var timeoutTask: Task<Void, Never>?

    func wait(for app: NSRunningApplication, timeout: Duration) async -> Bool {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            // .initial 覆盖"注册前已经退出"的情况；NSRunningApplication 的 KVO 在主线程投递。
            observation = app.observe(\.isTerminated, options: [.initial, .new]) { [weak self] app, _ in
                guard app.isTerminated else { return }
                Task { @MainActor [weak self] in self?.finish(exited: true) }
            }
            timeoutTask = Task { [weak self] in
                try? await Task.sleep(for: timeout)
                self?.finish(exited: false)
            }
        }
    }

    private func finish(exited: Bool) {
        guard let continuation else { return }
        self.continuation = nil
        observation?.invalidate()
        observation = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        continuation.resume(returning: exited)
    }
}
