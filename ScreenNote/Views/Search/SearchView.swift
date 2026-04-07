import SwiftUI

struct SearchView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.results) { note in
                NavigationLink {
                    NoteDetailView(note: note)
                } label: {
                    NoteCardView(note: note, highlightQuery: viewModel.query)
                }
            }
            .listStyle(.plain)
            .navigationTitle("搜索")
            .searchable(text: Binding(
                get: { viewModel.query },
                set: { viewModel.query = $0 }
            ), prompt: "搜索标题、摘要、OCR 或标签")
            .onChange(of: viewModel.query) { _, _ in
                viewModel.performSearch()
            }
            .task {
                viewModel.configure(appState: appState)
            }
        }
    }
}
