import SwiftUI

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let actionTitle: String
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 54))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.title3.bold())
            if let action {
                Button(actionTitle, action: action)
                    .font(.body)
            } else {
                Text(actionTitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
