import Foundation

public enum SwitchError: Error, Equatable {
    case targetMismatch(expected: TargetApp, actual: TargetApp)
    case invalidSubscriptionURL(String)
    case readFailed(String)
    case backupFailed(String)
    case writeFailed(String)
    case verificationFailed(expected: String, actual: String?)
}

extension SwitchError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .targetMismatch(expected, actual):
            "目标不匹配：档案属于 \(expected.displayName)，适配器属于 \(actual.displayName)"
        case let .invalidSubscriptionURL(value):
            "订阅地址无效：\(value)"
        case let .readFailed(reason):
            "读取当前配置失败：\(reason)"
        case let .backupFailed(reason):
            "备份当前配置失败：\(reason)"
        case let .writeFailed(reason):
            "写入新配置失败：\(reason)"
        case let .verificationFailed(expected, actual):
            "写入后验证失败：期望 \(expected)，实际 \(actual ?? "空")"
        }
    }
}
