import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    private(set) var results: [Note] = []
    private var repository: NoteRepository?

    func configure(appState: AppState) {
        guard repository == nil else { return }
        repository = appState.noteRepository
        performSearch()
    }

    private var searchTask: Task<Void, Never>?

    func performSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let repository else { return }
            results = (try? repository.searchNotes(query: query)) ?? []
        }
    }
}
