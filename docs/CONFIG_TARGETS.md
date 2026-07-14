# 切换目标与配置模型

## 基本假设

应用管理的是“订阅地址”，不是账号、令牌系统或代理规则。订阅地址可能包含敏感参数，因此展示、日志和持久化都要按敏感数据处理。

Codex 与 Claude 的真实配置位置需要在实现前逐项验证，不能凭猜测硬编码。所有目标写入都必须封装在适配器中。

## 数据模型

```swift
struct SubscriptionProfile: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var target: TargetApp
    var urlReference: SecretReference
    var note: String
    var createdAt: Date
    var updatedAt: Date
}

enum TargetApp: String, Codable, CaseIterable {
    case codex
    case claude
}
```

## 敏感字段

`urlReference` 不直接保存明文地址。初始实现建议：

- 非敏感元数据进入 Application Support 下的 JSON 文件。
- 明文 URL 进入 Keychain。
- UI 展示时默认只显示协议、域名和尾部少量字符。
- 日志中只记录脱敏 URL。

## 目标适配器协议

```swift
protocol TargetAdapter {
    var target: TargetApp { get }

    func readCurrentSubscription() throws -> CurrentSubscription
    func apply(profile: SubscriptionProfile) throws
    func verify(profile: SubscriptionProfile) throws -> VerificationResult
}
```

## 写入策略

1. 定位目标配置。
2. 读取当前内容。
3. 创建备份。
4. 写入新地址。
5. 重新读取并验证。
6. 成功后记录切换事件。

任一步失败都停止流程，并保留错误上下文。

## 配置路径策略

初始版本不应在未验证前假定固定路径。建议按顺序处理：

1. 使用目标应用官方或本地实际配置路径。
2. 若路径不存在，提示用户打开目标应用完成初始化。
3. 若仍无法发现，允许用户在高级设置中手动选择配置文件。
4. 手动路径必须保存为目标级配置，并在每次写入前验证可读写。

## 事件记录

每次切换记录：

- 时间。
- 目标应用。
- 档案名称。
- 结果状态。
- 失败原因。
- 备份路径。

事件记录只保留最近少量条目，避免无意义增长。
