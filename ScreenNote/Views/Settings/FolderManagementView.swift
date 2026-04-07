import SwiftUI

struct FolderManagementView: View {
    @Environment(AppState.self) private var appState
    @State private var folders: [NoteFolder] = []
    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var renamingFolder: NoteFolder?
    @State private var renameText = ""

    var body: some View {
        List {
            ForEach(folders) { folder in
                folderRow(folder)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteFolder(folder)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        Button {
                            renameText = folder.name
                            renamingFolder = folder
                        } label: {
                            Label("重命名", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }
        }
        .overlay {
            if folders.isEmpty {
                ContentUnavailableView("暂无文件夹", systemImage: "folder", description: Text("点击右上角添加文件夹"))
            }
        }
        .navigationTitle("文件夹管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newFolderName = ""
                    showNewFolderAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("新建文件夹", isPresented: $showNewFolderAlert) {
            TextField("文件夹名称", text: $newFolderName)
            Button("取消", role: .cancel) {}
            Button("创建") {
                createFolder()
            }
            .disabled(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .sheet(item: $renamingFolder) { folder in
            NavigationStack {
                Form {
                    TextField("文件夹名称", text: $renameText)
                }
                .navigationTitle("重命名文件夹")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { renamingFolder = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            renameFolder(folder)
                        }
                        .disabled(renameText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .task {
            loadFolders()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func folderRow(_ folder: NoteFolder) -> some View {
        HStack(spacing: 12) {
            Image(systemName: folder.icon)
                .foregroundStyle(.blue)
            Text(folder.name)
            Spacer()
            Text("\(folder.notes.count) 条笔记")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func loadFolders() {
        folders = (try? appState.folderRepository?.fetchAll()) ?? []
    }

    private func createFolder() {
        let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        try? appState.folderRepository?.create(name: trimmed, icon: "folder")
        loadFolders()
    }

    private func deleteFolder(_ folder: NoteFolder) {
        try? appState.folderRepository?.delete(folder)
        loadFolders()
    }

    private func renameFolder(_ folder: NoteFolder) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        try? appState.folderRepository?.rename(folder, to: trimmed)
        renamingFolder = nil
        loadFolders()
    }
}
