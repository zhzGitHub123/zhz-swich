import SwiftUI
import Foundation

/// 账号窗口是否真的在屏幕上（未被遮挡、未最小化）。由 AppDelegate 根据 NSWindow 遮挡状态更新，
/// 循环动画只在可见时运行，避免窗口开着但看不见时持续重绘。
@MainActor
@Observable
final class WindowVisibility {
    var isVisible = true
}

private struct WindowIsVisibleKey: EnvironmentKey {
    static let defaultValue: WindowVisibility? = nil
}

extension EnvironmentValues {
    var windowIsVisible: WindowVisibility? {
        get { self[WindowIsVisibleKey.self] }
        set { self[WindowIsVisibleKey.self] = newValue }
    }
}

extension View {
    /// 循环动画的开关：可见且未开启"减弱动态效果"时才运行。
    func loopingAnimation(
        isEnabled: Bool,
        start: @escaping () -> Void,
        stop: @escaping () -> Void
    ) -> some View {
        modifier(LoopingAnimationModifier(isEnabled: isEnabled, start: start, stop: stop))
    }
}

private struct LoopingAnimationModifier: ViewModifier {
    let isEnabled: Bool
    let start: () -> Void
    let stop: () -> Void
    @Environment(\.windowIsVisible) private var visibility

    private var shouldRun: Bool {
        isEnabled && (visibility?.isVisible ?? true)
    }

    func body(content: Content) -> some View {
        // 单靠"无动画事务"改状态打不断 repeatForever；换 id 让子树重建，正在跑的动画随旧节点一起销毁。
        content
            .id(shouldRun)
            .onAppear { if shouldRun { start() } }
            .onChange(of: shouldRun) { _, run in
                run ? start() : stop()
            }
    }
}

/// 立即停在给定状态，不带任何动画；用于打断 repeatForever。
func withoutAnimation(_ body: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, body)
}
