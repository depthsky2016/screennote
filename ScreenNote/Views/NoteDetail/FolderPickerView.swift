import SwiftUI

struct FolderPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let note: Note
    @State private var folders: [NoteFolder] = []
    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""

    var body: some View {
        NavigationStack {
            List {
                // 无文件夹选项
                Button {
                    try? appState.folderRepository?.moveNote(note, to: nil)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "tray")
                            .foregroundStyle(.secondary)
                        Text("无文件夹")
                            .foregroundStyle(.primary)
                        Spacer()
                        if note.folder == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                // 文件夹列表
                ForEach(folders) { folder in
                    Button {
                        try? appState.folderRepository?.moveNote(note, to: folder)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: folder.icon)
                                .foregroundStyle(.blue)
                            Text(folder.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if note.folder?.id == folder.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择文件夹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    newFolderName = ""
                    showNewFolderAlert = true
                } label: {
                    Label("新建文件夹", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding()
            }
            .alert("新建文件夹", isPresented: $showNewFolderAlert) {
                TextField("文件夹名称", text: $newFolderName)
                Button("取消", role: .cancel) {}
                Button("创建") {
                    createFolder()
                }
                .disabled(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .task {
                loadFolders()
            }
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
}
