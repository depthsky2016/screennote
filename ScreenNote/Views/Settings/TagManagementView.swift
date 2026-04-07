import SwiftUI

struct TagManagementView: View {
    @Environment(AppState.self) private var appState
    @State private var tags: [Tag] = []
    @State private var showNewTagAlert = false
    @State private var newTagName = ""
    @State private var renamingTag: Tag?
    @State private var renameText = ""
    @State private var showSystemDeleteConfirm = false
    @State private var tagToDelete: Tag?

    var body: some View {
        List {
            ForEach(tags) { tag in
                tagRow(tag)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            if tag.isSystem {
                                tagToDelete = tag
                                showSystemDeleteConfirm = true
                            } else {
                                deleteTag(tag)
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        Button {
                            renameText = tag.name
                            renamingTag = tag
                        } label: {
                            Label("重命名", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }
        }
        .overlay {
            if tags.isEmpty {
                ContentUnavailableView("暂无标签", systemImage: "tag", description: Text("点击右上角添加标签"))
            }
        }
        .navigationTitle("标签管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newTagName = ""
                    showNewTagAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("新建标签", isPresented: $showNewTagAlert) {
            TextField("标签名称", text: $newTagName)
            Button("取消", role: .cancel) {}
            Button("创建") {
                createTag()
            }
            .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .alert("确认删除", isPresented: $showSystemDeleteConfirm) {
            Button("取消", role: .cancel) {
                tagToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let tag = tagToDelete {
                    deleteTag(tag)
                    tagToDelete = nil
                }
            }
        } message: {
            Text("这是系统标签，删除后相关笔记将失去该标签。确定删除吗？")
        }
        .sheet(item: $renamingTag) { tag in
            NavigationStack {
                Form {
                    TextField("标签名称", text: $renameText)
                }
                .navigationTitle("重命名标签")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { renamingTag = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            renameTag(tag)
                        }
                        .disabled(renameText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .task {
            loadTags()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func tagRow(_ tag: Tag) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: tag.color) ?? .gray)
                .frame(width: 12, height: 12)
            Text(tag.name)
            if tag.isSystem {
                Text("系统")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            Spacer()
            Text("\(tag.notes.count) 条笔记")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func loadTags() {
        tags = (try? appState.tagRepository?.fetchAll()) ?? []
    }

    private func createTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        try? appState.tagRepository?.create(name: trimmed, color: "#3498DB", icon: "tag")
        loadTags()
    }

    private func deleteTag(_ tag: Tag) {
        try? appState.tagRepository?.delete(tag)
        loadTags()
    }

    private func renameTag(_ tag: Tag) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        try? appState.tagRepository?.rename(tag, to: trimmed)
        renamingTag = nil
        loadTags()
    }
}
