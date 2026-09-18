import AppKit

@main
enum ZSwichApp {
    @MainActor
    static func main() {
        // 带 -- 参数时走命令行模式并直接退出，不创建菜单栏或窗口。
        CLI.runIfNeeded()

        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}
