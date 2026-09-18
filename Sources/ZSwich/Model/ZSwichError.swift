import Foundation

enum ZSwichError: LocalizedError {
    case authFileMissing
    case invalidAuthFile(String)
    case chatGPTNotInstalled
    case quitTimeout
    case snapshotMissing(String)
    case unsupportedCredentialsStore(String)
    case usageCredentialsMissing
    case usageUnauthorized
    case usageTimeout
    case usageNetwork(String)
    case usageHTTP(Int)
    case usageInvalidResponse

    var errorDescription: String? {
        switch self {
        case .authFileMissing:
            return "ChatGPT 当前未登录（找不到 auth.json）"
        case .invalidAuthFile(let reason):
            return "auth.json 无法解析：\(reason)"
        case .chatGPTNotInstalled:
            return "没有找到 ChatGPT.app（bundle id com.openai.codex）"
        case .quitTimeout:
            return "ChatGPT 没有在限定时间内退出，请手动退出后重试"
        case .snapshotMissing(let id):
            return "找不到账号快照：\(id)"
        case .unsupportedCredentialsStore(let mode):
            return "当前 cli_auth_credentials_store 为 \(mode)，Z-Swich 暂只支持 file 模式"
        case .usageCredentialsMissing:
            return "当前账号缺少可用的访问凭证"
        case .usageUnauthorized:
            return "额度查询认证已失效，请先让 ChatGPT 刷新登录状态"
        case .usageTimeout:
            return "额度查询超时"
        case .usageNetwork(let reason):
            return "额度查询失败：\(reason)"
        case .usageHTTP(let statusCode):
            return "额度服务返回 HTTP \(statusCode)"
        case .usageInvalidResponse:
            return "额度服务返回了无法识别的数据"
        }
    }
}
