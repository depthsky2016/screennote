import SwiftUI

struct CaptureOverlayView: View {
    let title: String
    let subtitle: String
    let confirmTitle: String
    let cancelTitle: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            HStack {
                Button(cancelTitle, role: .cancel, action: onCancel)
                    .buttonStyle(.bordered)
                Button(confirmTitle, action: onConfirm)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 12)
    }
}
