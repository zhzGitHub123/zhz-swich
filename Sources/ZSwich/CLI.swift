import Foundation

/// 命令行模式：方便脚本、快捷指令和自测。带 `--` 参数启动时不进入菜单栏界面。
@MainActor
enum CLI {
    static func runIfNeeded() {
        let args = Array(CommandLine.arguments.dropFirst())
        guard let command = args.first, command.hasPrefix("--") else { return }

        switch command {
        case "--list":
            let store = loadedStore()
            printList(store)
            exit(0)
        case "--switch":
            guard let query = args.dropFirst().first else {
                fputs("用法：--switch <邮箱或账号ID>\n", stderr)
                exit(2)
            }
            let store = loadedStore()
            guard let record = store.accounts.first(where: { $0.email == query || $0.id == query }) else {
                fputs("没有找到账号：\(query)\n", stderr)
                exit(1)
            }
            runBlocking { await store.switchTo(accountID: record.id) }
            print(store.status ?? "")
            exit(store.status?.hasPrefix("已切换") == true ? 0 : 1)
        case "--new-login":
            let store = loadedStore()
            runBlocking { await store.startNewLogin() }
            print(store.status ?? "")
            exit(0)
        case "--help", "-h":
            printUsage()
            exit(0)
        default:
            fputs("未知参数：\(command)\n", stderr)
            printUsage()
            exit(2)
        }
    }

    private static func loadedStore() -> AccountStore {
        let store = AccountStore()
        store.syncCurrent()
        return store
    }

    private static func printList(_ store: AccountStore) {
        if let current = store.current {
            print("当前：\(current.email)  [\(current.planType?.planLabel ?? "?")]  \(current.accountID)")
        } else {
            print("当前：\(store.currentProblem ?? "未知")")
        }
        print("ChatGPT：\(store.chatGPTRunning ? "运行中" : "未运行")")
        print("已保存账号：\(store.accounts.count)")
        for account in store.accounts {
            let marker = account.id == store.current?.accountID ? "*" : " "
            print("\(marker) \(account.email)  [\(account.planLabel)]  \(account.id)")
        }
    }

    private static func printUsage() {
        print("""
        Z-Swich 命令行用法：
          --list                 列出当前账号与已保存账号
          --switch <邮箱或ID>    切换到指定账号（会重启 ChatGPT）
          --new-login            保存当前账号并让 ChatGPT 进入登录页
        """)
    }

    private final class Flag { var done = false }

    /// 在主线程把一个 async 操作跑完，期间泵 RunLoop 让主队列任务得以执行。
    private static func runBlocking(_ operation: @escaping @MainActor () async -> Void) {
        let flag = Flag()
        Task { @MainActor in
            await operation()
            flag.done = true
        }
        while !flag.done {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
        }
    }
}
