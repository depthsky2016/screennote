import PhotosUI
import SwiftData
import SwiftUI

struct NoteListView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = NoteListViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var navigationPath = NavigationPath()
    @State private var isEditing = false
    @State private var selectedNoteIDs: Set<UUID> = []
    @State private var showBatchDeleteConfirm = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.notes.isEmpty {
                    EmptyStateView(
                        title: "截一张图试试",
                        systemImage: "photo.on.rectangle.angled",
                        actionTitle: "导入截图"
                    )
                } else if viewModel.isGridMode {
                    NoteGridView(notes: viewModel.notes)
                } else {
                    List(selection: isEditing ? $selectedNoteIDs : nil) {
                        ForEach(viewModel.notes) { note in
                            NavigationLink(value: note.id) {
                                NoteCardView(note: note)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("归档") {
                                    viewModel.archive(note)
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .leading) {
                                if note.processingStatus.canRetry {
                                    Button("重试") {
                                        viewModel.retryProcessing(note)
                                    }
                                    .tint(.blue)
                                }
                            }
                            .tag(note.id)
                        }
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                }
            }
            .navigationDestination(for: UUID.self) { noteID in
                if let note = viewModel.notes.first(where: { $0.id == noteID }) {
                    NoteDetailView(note: note)
                }
            }
            .navigationTitle("截图笔记")
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    if !viewModel.notes.isEmpty {
                        Button(isEditing ? "完成" : "选择") {
                            isEditing.toggle()
                            if !isEditing { selectedNoteIDs.removeAll() }
                        }
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if isEditing {
                        Menu {
                            Button {
                                viewModel.batchArchive(selectedNoteIDs)
                                selectedNoteIDs.removeAll()
                                isEditing = false
                            } label: {
                                Label("归档所选 (\(selectedNoteIDs.count))", systemImage: "archivebox")
                            }
                            .disabled(selectedNoteIDs.isEmpty)

                            Button {
                                viewModel.batchRetry(selectedNoteIDs)
                                selectedNoteIDs.removeAll()
                                isEditing = false
                            } label: {
                                Label("重试所选", systemImage: "arrow.clockwise")
                            }
                            .disabled(selectedNoteIDs.isEmpty)

                            Divider()

                            Button(role: .destructive) {
                                showBatchDeleteConfirm = true
                            } label: {
                                Label("删除所选 (\(selectedNoteIDs.count))", systemImage: "trash")
                            }
                            .disabled(selectedNoteIDs.isEmpty)
                        } label: {
                            Text("操作")
                        }
                    } else {
                        Button {
                            viewModel.isGridMode.toggle()
                        } label: {
                            Image(systemName: viewModel.isGridMode ? "list.bullet" : "square.grid.2x2")
                        }

                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 50, matching: .images) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .confirmationDialog("确认删除 \(selectedNoteIDs.count) 条笔记？", isPresented: $showBatchDeleteConfirm, titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    viewModel.batchDelete(selectedNoteIDs)
                    selectedNoteIDs.removeAll()
                    isEditing = false
                }
                Button("取消", role: .cancel) {}
            }
            .overlay(alignment: .bottom) {
                if appState.pendingScreenshotEvent {
                    CaptureOverlayView(
                        title: "检测到截图",
                        subtitle: "从相册导入最新截图到截图笔记",
                        confirmTitle: "打开导入",
                        cancelTitle: "取消",
                        onConfirm: {
                            appState.pendingScreenshotEvent = false
                        },
                        onCancel: {
                            appState.pendingScreenshotEvent = false
                        }
                    )
                    .padding()
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingIndicator(text: viewModel.importProgressText.isEmpty ? "正在导入..." : viewModel.importProgressText)
                }
            }
            .task {
                viewModel.configure(appState: appState)
                viewModel.reload()
            }
            .onChange(of: appState.notesRefreshToken) { _, _ in
                viewModel.reload()
            }
            .onChange(of: appState.processingPipeline?.completionToken) { _, _ in
                viewModel.reload()
            }
            .onChange(of: appState.deepLinkNoteID) { _, newID in
                guard let id = newID else { return }
                navigationPath.append(id)
                appState.deepLinkNoteID = nil
            }
            .onChange(of: selectedItems) { _, newValue in
                guard !newValue.isEmpty else { return }
                Task {
                    var importedData: [Data] = []
                    for item in newValue {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            importedData.append(data)
                        }
                    }
                    await viewModel.importImages(importedData, appState: appState)
                    selectedItems = []
                }
            }
        }
    }
}

#Preview {
    NoteListView()
        .environment(AppState())
        .modelContainer(PreviewContainer.shared.container)
}
