import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = SettingsViewModel()

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Kimi API") {
                    SecureField("输入 Kimi API Key", text: Binding(
                        get: { viewModel.apiKey },
                        set: { viewModel.apiKey = $0 }
                    ))

                    Button("保存 API Key") {
                        viewModel.saveAPIKey()
                        appState.refreshAPIKeyStatus()
                    }

                    Button("删除 API Key", role: .destructive) {
                        viewModel.deleteAPIKey()
                        appState.refreshAPIKeyStatus()
                    }

                    if !viewModel.validationMessage.isEmpty {
                        Text(viewModel.validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("偏好设置") {
                    Toggle("静默模式", isOn: Binding(
                        get: { appState.silentModeEnabled },
                        set: { appState.updateSilentMode($0) }
                    ))
                }

                Section("管理") {
                    NavigationLink("标签管理") {
                        TagManagementView()
                    }
                    NavigationLink("文件夹管理") {
                        FolderManagementView()
                    }
                }

                Section("关于") {
                    LabeledContent("版本", value: "\(appVersion) (\(buildNumber))")
                    LabeledContent("AI 模型", value: "kimi-k2.5")
                    LabeledContent("OCR", value: "Apple Vision")
                    LabeledContent("隐私", value: "图片本地处理")

                    Link(destination: URL(string: "https://depthsky2016.github.io/screennote/privacy.html")!) {
                        HStack {
                            Text("隐私政策")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}
