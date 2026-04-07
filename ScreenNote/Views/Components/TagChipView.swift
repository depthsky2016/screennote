import SwiftUI

struct TagChipView: View {
    let tag: Tag

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tag.icon)
            Text(tag.name)
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(hex: tag.color).opacity(0.14), in: Capsule())
        .foregroundStyle(Color(hex: tag.color))
    }
}
