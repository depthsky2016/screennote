import SwiftUI

struct NoteCardView: View {
    let note: Note
    var highlightQuery: String = ""

    var body: some View {
        HStack(spacing: 14) {
            if let image = note.previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .overlay(Image(systemName: "photo"))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(highlighted(note.aiTitle.isEmpty ? "未命名截图" : note.aiTitle))
                        .font(.headline)
                        .lineLimit(1)

                    if note.processingStatus.canRetry {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if note.processingStatus != .completed {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }

                Text(highlighted(note.aiSummary.isEmpty ? note.processingStatus.displayText : note.aiSummary))
                    .font(.caption)
                    .foregroundStyle(note.processingStatus.canRetry ? .red : .secondary)
                    .lineLimit(2)

                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(note.tags.prefix(3)) { tag in
                                TagChipView(tag: tag)
                            }
                        }
                    }
                    Spacer()
                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func highlighted(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        let query = highlightQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return attributed }

        var searchStart = attributed.startIndex
        while searchStart < attributed.endIndex {
            let remaining = attributed[searchStart...]
            let lowered = String(remaining.characters).lowercased()
            guard let range = lowered.range(of: query) else { break }

            let offset = lowered.distance(from: lowered.startIndex, to: range.lowerBound)
            let length = query.count
            let attrStart = attributed.index(searchStart, offsetByCharacters: offset)
            let attrEnd = attributed.index(attrStart, offsetByCharacters: length)
            attributed[attrStart..<attrEnd].backgroundColor = .yellow.opacity(0.3)
            searchStart = attrEnd
        }
        return attributed
    }
}

#Preview {
    NoteCardView(note: .mockCompleted)
        .padding()
}
