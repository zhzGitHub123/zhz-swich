import Foundation

struct UsageWindow: Hashable, Sendable {
    let usedPercent: Double
    /// 服务器返回的 limit_window_seconds：不同套餐窗口长度不同，标题只能由它推出来。
    /// 实测 Plus 是 5 小时（18000）+ 每周（604800）两个窗口，Pro 只有每周（604800）一个窗口。
    let duration: TimeInterval
    let resetAt: Date

    var remainingPercent: Double {
        min(max(100 - usedPercent, 0), 100)
    }

    /// 窗口标题。禁止在视图里写死"5 小时"，否则 Pro 的周窗口会被标成 5 小时。
    var title: String {
        switch Int(duration.rounded()) {
        case 604_800: "每周限制额度"
        case 2_592_000: "每月限制额度"
        case 86_400: "每日限制额度"
        default: "\(durationText)限制额度"
        }
    }

    var systemImage: String {
        duration >= 86_400 ? "chart.bar.fill" : "clock"
    }

    /// 表格窄列用的短标签："5h" / "7d" / "30d"。
    var shortLabel: String {
        let seconds = Int(duration.rounded())
        if seconds >= 86_400 { return "\(seconds / 86_400)d" }
        if seconds >= 3_600 { return "\(seconds / 3_600)h" }
        return "\(max(seconds / 60, 1))m"
    }

    private var durationText: String {
        let seconds = Int(duration.rounded())
        if seconds >= 86_400, seconds % 86_400 == 0 { return "\(seconds / 86_400) 天" }
        if seconds >= 3_600, seconds % 3_600 == 0 { return "\(seconds / 3_600) 小时" }
        if seconds >= 60 { return "\(seconds / 60) 分钟" }
        return "\(seconds) 秒"
    }
}
