import SwiftUI

struct LoadingIndicator: View {
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text(text)
                .font(.callout.weight(.semibold))
        }
        .padding(24)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 10)
    }
}
