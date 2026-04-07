import SwiftUI

struct NoteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let note: Note
    @State private var viewModel: NoteDetailViewModel?
    @State private var isOCRExpanded = false
    @State private var showFolderPicker = false

    var body: some View {
        Group {
            if let viewModel {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let image = note.previewImage {
                            ZoomableImageView(image: image)
                        }

                        TextField("标题", text: Binding(
                            get: { viewModel.title },
                            set: { viewModel.title = $0 }
                        ))
                        .font(.title2.bold())

                        // 状态和重试
                        if note.processingStatus.canRetry {
                            HStack {
                                Label(note.processingStatus.displayText, systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                                    .font(.callout)
                                Spacer()
                                Button {
                                    Task { await viewModel.retryProcessing() }
                                } label: {
                                    Label("重试", systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(.bordered)
                                .tint(.blue)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(note.tags) { tag in
                                    TagChipView(tag: tag)
                                }
                            }
                        }

                        Button {
                            showFolderPicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "folder")
                                Text(note.folder?.name ?? "选择文件夹")
                            }
                            .font(.callout)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showFolderPicker) {
                            FolderPickerView(note: note)
                        }

                        TextEditor(text: Binding(
                            get: { viewModel.summary },
                            set: { viewModel.summary = $0 }
                        ))
                        .frame(minHeight: 120)
                        .padding(10)
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))

                        // Entities 展示
                        if viewModel.hasEntities, let entities = viewModel.decodedEntities {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("识别信息")
                                    .font(.headline)
                                if !entities.people.isEmpty {
                                    Label(entities.people.joined(separator: "、"), systemImage: "person")
                                        .font(.callout)
                                }
                                if !entities.dates.isEmpty {
                                    Label(entities.dates.joined(separator: "、"), systemImage: "calendar")
                                        .font(.callout)
                                }
                                if !entities.amounts.isEmpty {
                                    Label(entities.amounts.joined(separator: "、"), systemImage: "yensign.circle")
                                        .font(.callout)
                                }
                                if !entities.links.isEmpty {
                                    Label(entities.links.joined(separator: "\n"), systemImage: "link")
                                        .font(.callout)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
                        }

                        Divider()

                        DisclosureGroup("OCR 原文", isExpanded: $isOCRExpanded) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(note.ocrRawText.isEmpty ? "暂无 OCR 内容" : note.ocrRawText)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if !note.ocrRawText.isEmpty {
                                    Button {
                                        viewModel.copyOCRText()
                                    } label: {
                                        Label("复制原文", systemImage: "doc.on.doc")
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .padding(.top, 8)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("我的批注")
                                .font(.headline)
                            TextEditor(text: Binding(
                                get: { viewModel.userNote },
                                set: { viewModel.userNote = $0 }
                            ))
                            .frame(minHeight: 120)
                            .padding(10)
                            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                }
                .navigationTitle("笔记详情")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        ShareLink(item: note.shareText) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Button(role: .destructive) {
                            viewModel.showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
                .confirmationDialog("确认删除这条笔记？删除后无法恢复。", isPresented: Binding(
                    get: { viewModel.showDeleteConfirmation },
                    set: { viewModel.showDeleteConfirmation = $0 }
                ), titleVisibility: .visible) {
                    Button("删除", role: .destructive) {
                        viewModel.delete()
                        dismiss()
                    }
                    Button("取消", role: .cancel) {}
                }
                .onDisappear {
                    viewModel.save()
                }
            } else {
                ProgressView()
                    .task {
                        guard let repository = appState.noteRepository else { return }
                        viewModel = NoteDetailViewModel(
                            note: note,
                            repository: repository,
                            pipeline: appState.processingPipeline
                        )
                    }
            }
        }
    }
}
