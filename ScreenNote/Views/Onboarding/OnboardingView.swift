import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            onboardingPage(
                systemImage: "photo.badge.plus",
                title: "截图导入",
                description: "从相册导入截图，AI 自动识别文字并生成摘要"
            )
            .tag(0)

            onboardingPage(
                systemImage: "magnifyingglass",
                title: "智能搜索",
                description: "按标题、摘要、OCR 原文搜索，标签分类管理"
            )
            .tag(1)

            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.accentColor)
                Text("开始使用")
                    .font(.title.bold())
                Text("截图笔记已准备就绪")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Button {
                    hasSeenOnboarding = true
                    dismiss()
                } label: {
                    Text("开始使用")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
                .padding(.top, 8)
                Spacer()
            }
            .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    private func onboardingPage(systemImage: String, title: String, description: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.title.bold())
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}
