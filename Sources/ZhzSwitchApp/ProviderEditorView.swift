import SwiftUI

struct ProviderEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let provider: ProviderProfile?
    let onSave: (ProviderProfile) throws -> Void

    @State private var name = ""
    @State private var note = ""
    @State private var officialURL = ""
    @State private var apiKey = ""
    @State private var baseURL = ""
    @State private var usesFullURL = false
    @State private var showsAdvancedOptions = false
    @State private var configurationJSON = "{\n  \"env\" : {\n\n  },\n  \"includeCoAuthoredBy\" : false\n}"
    @State private var writesGeneralConfiguration = true
    @State private var usesStandaloneBillingConfiguration = false
    @State private var validationMessage: String?
    @State private var jsonMessage: String?

    init(
        provider: ProviderProfile? = nil,
        onSave: @escaping (ProviderProfile) throws -> Void
    ) {
        self.provider = provider
        self.onSave = onSave
        _name = State(initialValue: provider?.name ?? "")
        _note = State(initialValue: provider?.note ?? "")
        _officialURL = State(initialValue: provider?.officialURL ?? "")
        _apiKey = State(initialValue: provider?.apiKey ?? "")
        _baseURL = State(initialValue: provider?.baseURL ?? "")
        _usesFullURL = State(initialValue: provider?.usesFullURL ?? false)
        _configurationJSON = State(initialValue: provider?.configurationJSON ?? "{\n  \"env\" : {\n\n  },\n  \"includeCoAuthoredBy\" : false\n}")
        _writesGeneralConfiguration = State(initialValue: provider?.writesGeneralConfiguration ?? true)
        _usesStandaloneBillingConfiguration = State(initialValue: provider?.usesStandaloneBillingConfiguration ?? false)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBaseURL: String {
        baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        identitySection
                        endpointSection
                        advancedSection
                        configurationSection
                        billingConfigurationRow
                    }
                    .padding(26)
                }
            }
        }
        .frame(minWidth: 760, idealWidth: 860, minHeight: 620, idealHeight: 740)
        .font(.system(size: 14, design: .rounded))
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.74), .purple.opacity(0.68)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)
            .shadow(color: .purple.opacity(0.24), radius: 10, y: 5)

            VStack(alignment: .leading, spacing: 3) {
                Text("模块 / Providers")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.slate500)
                Text(provider == nil ? "新增提供商" : "编辑提供商")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.slate900)
                Text("配置 API 密钥、请求地址与客户端写入选项")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.slate600)
            }

            Spacer()
            HeaderButton(
                title: "取消",
                icon: "xmark",
                usesLiquidGlass: true,
                action: { dismiss() }
            )
                .keyboardShortcut(.cancelAction)
            HeaderButton(
                title: "保存",
                icon: "checkmark",
                emphasized: true,
                usesLiquidGlass: true,
                action: save
            )
                .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 26)
        .padding(.top, 22)
        .padding(.bottom, 4)
    }

    private var identitySection: some View {
        NativeLiquidGlassCard(tint: .blue, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 16) {
                EditorSectionTitle(icon: "person.text.rectangle", title: "基本信息", subtitle: "用于识别和管理这个提供商")
                HStack(alignment: .top, spacing: 18) {
                    EditorField(title: "供应商名称", placeholder: "例如：Claude 官方", text: $name)
                    EditorField(title: "备注", placeholder: "例如：公司专用账号", text: $note)
                }
                EditorField(title: "官网链接", placeholder: "https://example.com（可选）", text: $officialURL)
                EditorSecureField(title: "API Key", placeholder: "只需要填这里，下方配置会自动填充", text: $apiKey)
            }
            .padding(18)
        }
    }

    private var endpointSection: some View {
        NativeLiquidGlassCard(tint: .purple, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    EditorSectionTitle(icon: "point.3.connected.trianglepath.dotted", title: "请求地址", subtitle: "连接兼容的 API 服务端点")
                    Spacer()
                    Toggle("完整 URL", isOn: $usesFullURL)
                        .toggleStyle(EditorToggleStyle())
                }
                TextField("https://your-api-endpoint.com", text: $baseURL)
                    .textFieldStyle(EditorTextFieldStyle())
                Label("填写兼容 Claude API 的服务端点地址，不要以斜杠结尾", systemImage: "lightbulb.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.adaptive(light: 0xB45309, dark: 0xFCD34D))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(.yellow.opacity(0.36)) }

                if let validationMessage {
                    Label(validationMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.red)
                        .accessibilityLabel("表单错误：\(validationMessage)")
                }
            }
            .padding(18)
        }
    }

    private var advancedSection: some View {
        NativeLiquidGlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 8) {
                NativeLiquidGlassButton(cornerRadius: 12, action: toggleAdvancedOptions) {
                    HStack(spacing: 10) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.purple)
                        Text("高级选项").fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(showsAdvancedOptions ? 90 : 0))
                            .foregroundStyle(Color.slate500)
                    }
                    .foregroundStyle(Color.slate900)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityValue(showsAdvancedOptions ? "已展开" : "已折叠")

                Text("包含 API 格式、认证字段、模型映射等配置。大多数场景下保持默认即可。")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.slate600)

                if showsAdvancedOptions {
                    HStack(spacing: 18) {
                        EditorReadOnlyField(title: "API 格式", value: "Anthropic Messages")
                        EditorReadOnlyField(title: "认证字段", value: "x-api-key / Bearer")
                    }
                    .padding(.top, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
        }
    }

    private var configurationSection: some View {
        NativeLiquidGlassCard(tint: .blue, cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    EditorSectionTitle(icon: "curlybraces.square", title: "配置 JSON", subtitle: "保存时校验格式并写入配置")
                    Spacer()
                    Toggle("写入通用配置", isOn: $writesGeneralConfiguration)
                        .toggleStyle(EditorToggleStyle())
                }

                TextEditor(text: $configurationJSON)
                    .font(.system(size: 13, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: 180)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay { RoundedRectangle(cornerRadius: 13).stroke(Color.themeBorder.opacity(0.66)) }

                HStack {
                    HeaderButton(
                        title: "格式化",
                        icon: "wand.and.stars",
                        usesLiquidGlass: true,
                        action: formatJSON
                    )
                    Spacer()
                    if let jsonMessage {
                        Text(jsonMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(18)
        }
    }

    private var billingConfigurationRow: some View {
        StandaloneConfigurationRow(
            icon: "link",
            title: "计费配置",
            isEnabled: $usesStandaloneBillingConfiguration
        )
    }

    private func toggleAdvancedOptions() {
        withAnimation(.easeOut(duration: 0.2)) {
            showsAdvancedOptions.toggle()
        }
    }

    private func save() {
        validationMessage = nil
        jsonMessage = nil

        guard !trimmedName.isEmpty else {
            validationMessage = "请填写供应商名称。"
            return
        }

        var draft = provider ?? ProviderProfile(
            name: trimmedName,
            baseURL: trimmedBaseURL,
            avatarText: String(trimmedName.prefix(2))
        )
        draft.name = trimmedName
        draft.baseURL = trimmedBaseURL
        draft.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.officialURL = officialURL.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.configurationJSON = configurationJSON
        draft.writesGeneralConfiguration = writesGeneralConfiguration
        draft.usesStandaloneBillingConfiguration = usesStandaloneBillingConfiguration
        draft.avatarText = String(trimmedName.prefix(2))
        draft.usesFullURL = usesFullURL

        guard draft.isValidURL else {
            validationMessage = "请求地址必须是有效的 HTTP 或 HTTPS 地址。"
            return
        }

        guard validOptionalURL(officialURL) else {
            validationMessage = "官网链接必须是有效的 HTTP 或 HTTPS 地址。"
            return
        }

        guard JSONSerialization.isValidJSONObject(jsonObject()) else {
            jsonMessage = "配置 JSON 必须是一个有效对象。"
            return
        }

        do {
            try onSave(draft)
            dismiss()
        } catch {
            validationMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    private func validOptionalURL(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        guard let components = URLComponents(string: trimmed), let scheme = components.scheme?.lowercased(), components.host != nil else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    private func jsonObject() -> Any {
        guard let data = configurationJSON.data(using: .utf8) else { return NSNull() }
        return (try? JSONSerialization.jsonObject(with: data)) ?? NSNull()
    }

    private func formatJSON() {
        jsonMessage = nil
        guard
            let data = configurationJSON.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data),
            JSONSerialization.isValidJSONObject(object),
            let formatted = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
            let string = String(data: formatted, encoding: .utf8)
        else {
            jsonMessage = "JSON 格式不正确。"
            return
        }
        configurationJSON = string
    }
}

private struct EditorField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).fontWeight(.semibold).foregroundStyle(Color.slate900)
            TextField(placeholder, text: $text)
                .textFieldStyle(EditorTextFieldStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EditorSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).fontWeight(.semibold).foregroundStyle(Color.slate900)
            SecureField(placeholder, text: $text)
                .textFieldStyle(EditorTextFieldStyle())
        }
    }
}

private struct EditorReadOnlyField: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.slate700)
            Text(value)
                .foregroundStyle(Color.slate600)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(11)
                .background(Color.themeSurface.opacity(0.30), in: RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StandaloneConfigurationRow: View {
    let icon: String
    let title: String
    @Binding var isEnabled: Bool

    var body: some View {
        NativeLiquidGlassCard(cornerRadius: 16, fillsAvailableSpace: false) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundStyle(Color.slate600)
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.slate900)
                Spacer()
                Toggle("使用单独配置", isOn: $isEnabled)
                    .toggleStyle(EditorToggleStyle())
            }
            .padding(16)
        }
    }
}

private struct EditorTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 13)
            .frame(minHeight: 42)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color.themeBorder.opacity(0.66)) }
            .shadow(color: .indigo.opacity(0.05), radius: 5, y: 2)
    }
}

private struct EditorSectionTitle: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.slate900)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.slate600)
            }
        }
    }
}

private struct EditorToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                configuration.label
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.slate700)
                VisualToggle(enabled: configuration.isOn)
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(configuration.isOn ? "已开启" : "已关闭")
    }
}
