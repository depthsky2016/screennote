import SwiftUI

struct NoteGridView: View {
    let notes: [Note]
    var onArchive: ((Note) -> Void)? = nil
    var onDelete: ((Note) -> Void)? = nil
    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(notes) { note in
                    NavigationLink {
                        NoteDetailView(note: note)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            if let image = note.previewImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            Text(note.aiTitle.isEmpty ? "未命名截图" : note.aiTitle)
                                .font(.headline)
                                .lineLimit(2)
                            Text(note.aiSummary.isEmpty ? note.processingStatus.displayText : note.aiSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        .padding(14)
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            onArchive?(note)
                        } label: {
                            Label("归档", systemImage: "archivebox")
                        }
                        Button(role: .destructive) {
                            onDelete?(note)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}
