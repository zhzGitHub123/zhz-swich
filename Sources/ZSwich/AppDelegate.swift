import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    private let store = AccountStore()
    private let menu = NSMenu()
    private var statusItem: NSStatusItem?
    private var accountWindow: NSWindow?
    /// 窗口被遮挡或最小化时通知 SwiftUI 暂停循环动画。
    private let windowVisibility = WindowVisibility()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = makeStatusBarIcon()
            button.toolTip = "Z-Swich"
        }
        menu.delegate = self
        item.menu = menu
        statusItem = item
    }

    private func makeStatusBarIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            let path = NSBezierPath()
            path.lineWidth = 2.15
            path.lineCapStyle = .round
            path.lineJoinStyle = .round

            // A monochrome small-size rendering of the selected opposing-arrow Z.
            path.move(to: NSPoint(x: 3.2, y: 13.4))
            path.line(to: NSPoint(x: 14.2, y: 13.4))
            path.move(to: NSPoint(x: 11.7, y: 15.8))
            path.line(to: NSPoint(x: 14.5, y: 13.4))
            path.line(to: NSPoint(x: 11.7, y: 11.0))
            path.move(to: NSPoint(x: 13.9, y: 12.8))
            path.line(to: NSPoint(x: 4.1, y: 5.2))
            path.move(to: NSPoint(x: 14.8, y: 4.6))
            path.line(to: NSPoint(x: 3.8, y: 4.6))
            path.move(to: NSPoint(x: 6.3, y: 7.0))
            path.line(to: NSPoint(x: 3.5, y: 4.6))
            path.line(to: NSPoint(x: 6.3, y: 2.2))

            NSColor.black.setStroke()
            path.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Z-Swich 账号切换"
        return image
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        store.syncCurrent()
        rebuildMenu()
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === accountWindow else { return }
        store.wantsUsage = false
        accountWindow?.contentViewController = nil
        accountWindow = nil
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    func windowDidChangeOcclusionState(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === accountWindow else { return }
        windowVisibility.isVisible = window.occlusionState.contains(.visible)
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        showAccountWindow()
        return true
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let currentTitle = store.current.map { "当前：\($0.email)" } ?? "当前：未登录"
        menu.addItem(disabledItem(currentTitle))
        menu.addItem(disabledItem("ChatGPT：\(store.chatGPTRunning ? "运行中" : "未运行")"))
        menu.addItem(.separator())

        if store.accounts.isEmpty {
            menu.addItem(disabledItem("暂无已保存账号"))
        } else {
            for account in store.accounts {
                let item = NSMenuItem(
                    title: accountMenuTitle(account),
                    action: #selector(switchAccount(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = account.id
                item.state = account.id == store.current?.accountID ? .on : .off
                item.isEnabled = item.state != .on && !store.isBusy
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        menu.addItem(actionItem("添加新账号…", action: #selector(startNewLogin), keyEquivalent: "n"))
        menu.addItem(actionItem("打开账号窗口…", action: #selector(showAccountWindow), keyEquivalent: ","))
        if !store.chatGPTRunning {
            menu.addItem(actionItem("打开 ChatGPT", action: #selector(launchChatGPT), keyEquivalent: ""))
        }
        if let status = store.status {
            menu.addItem(.separator())
            menu.addItem(disabledItem(status))
        }
        menu.addItem(.separator())
        menu.addItem(actionItem("退出 Z-Swich", action: #selector(terminate), keyEquivalent: "q"))
    }

    private func accountMenuTitle(_ account: AccountRecord) -> String {
        let refreshWarning = account.accessTokenExpiry.map { $0 <= .now ? " · 需要刷新" : "" } ?? ""
        return "\(account.email) · \(account.planLabel)\(refreshWarning)"
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func actionItem(_ title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        item.isEnabled = !store.isBusy
        return item
    }

    @objc private func switchAccount(_ sender: NSMenuItem) {
        guard let accountID = sender.representedObject as? String else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            await store.switchTo(accountID: accountID)
        }
    }

    @objc private func startNewLogin() {
        Task { @MainActor [weak self] in
            await self?.store.startNewLogin()
        }
    }

    @objc private func launchChatGPT() {
        Task { @MainActor [weak self] in
            await self?.store.launchChatGPT()
        }
    }

    @objc private func showAccountWindow() {
        NSApplication.shared.setActivationPolicy(.regular)
        store.syncCurrent()
        store.wantsUsage = true
        Task { @MainActor [weak self] in
            await self?.store.refreshUsage()
        }
        if let accountWindow {
            NSApplication.shared.activate()
            accountWindow.makeKeyAndOrderFront(nil)
            accountWindow.orderFrontRegardless()
            return
        }

        windowVisibility.isVisible = true
        let hostingController = NSHostingController(
            rootView: AccountWindowView(store: store)
                .environment(\.windowIsVisible, windowVisibility)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 780),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Z-Swich 账号管理"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.toolbar = NSToolbar(identifier: "ZSwichAccountWindowToolbar")
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.minSize = NSSize(
            width: ZSwichTheme.windowMinWidth,
            height: ZSwichTheme.windowMinHeight
        )
        window.contentViewController = hostingController
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.center()
        accountWindow = window
        NSApplication.shared.activate()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    @objc private func terminate() {
        NSApplication.shared.terminate(nil)
    }
}
