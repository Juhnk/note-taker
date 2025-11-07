//
//  NotesViewModel.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import Foundation
import SwiftUI
import CoreData

/// ViewModel for managing notes list and operations
/// Handles fetching, creating, updating, and deleting notes
/// Uses @Observable for SwiftUI state management
@Observable
final class NotesViewModel {

    // MARK: - Published State

    var notes: [Note] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Private Properties

    private let service: CoreDataService
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
        self.service = CoreDataService(context: context)
    }

    /// Convenience initializer using shared persistence controller
    convenience init() {
        self.init(context: PersistenceController.shared.container.viewContext)
    }

    // MARK: - Note Operations

    /// Fetches all notes, optionally filtered by folder or tag
    /// - Parameters:
    ///   - folder: Optional folder to filter by
    ///   - tag: Optional tag to filter by
    @MainActor
    func fetchNotes(in folder: Folder? = nil, with tag: Tag? = nil) {
        isLoading = true
        errorMessage = nil

        do {
            if let tag = tag {
                notes = try service.fetchNotes(with: tag)
            } else {
                notes = try service.fetchNotes(in: folder)
            }
            isLoading = false
        } catch {
            errorMessage = "Failed to load notes: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Creates a new note
    /// - Parameters:
    ///   - title: The note's title
    ///   - content: The note's content
    ///   - folder: Optional folder to place the note in
    ///   - isPinned: Whether the note should be pinned
    /// - Returns: The created Note entity
    @MainActor
    func createNote(
        title: String,
        content: String = "",
        in folder: Folder? = nil,
        isPinned: Bool = false
    ) -> Note? {
        errorMessage = nil

        do {
            let note = try service.createNote(
                title: title,
                content: content,
                in: folder,
                isPinned: isPinned
            )
            notes.insert(note, at: 0) // Add to beginning
            return note
        } catch {
            errorMessage = "Failed to create note: \(error.localizedDescription)"
            return nil
        }
    }

    /// Updates an existing note
    /// - Parameters:
    ///   - note: The note to update
    ///   - title: New title (optional)
    ///   - content: New content (optional)
    ///   - folder: New folder (optional)
    ///   - isPinned: New pinned status (optional)
    @MainActor
    func updateNote(
        _ note: Note,
        title: String? = nil,
        content: String? = nil,
        folder: Folder? = nil,
        isPinned: Bool? = nil
    ) {
        errorMessage = nil

        do {
            try service.updateNote(note, title: title, content: content, folder: folder, isPinned: isPinned)

            // Re-sort notes if pinned status changed
            if isPinned != nil {
                sortNotes()
            }
        } catch {
            errorMessage = "Failed to update note: \(error.localizedDescription)"
        }
    }

    /// Deletes a note
    /// - Parameter note: The note to delete
    @MainActor
    func deleteNote(_ note: Note) {
        errorMessage = nil

        do {
            try service.deleteNote(note)
            notes.removeAll { $0.id == note.id }
        } catch {
            errorMessage = "Failed to delete note: \(error.localizedDescription)"
        }
    }

    /// Toggles the pinned status of a note
    /// - Parameter note: The note to toggle
    @MainActor
    func togglePin(_ note: Note) {
        updateNote(note, isPinned: !note.isPinned)
    }

    // MARK: - Search

    /// Filters notes by search text (title or content)
    /// - Parameter searchText: The text to search for
    /// - Returns: Filtered array of notes
    func filteredNotes(searchText: String) -> [Note] {
        guard !searchText.isEmpty else { return notes }

        return notes.filter { note in
            let titleMatch = note.title?.localizedCaseInsensitiveContains(searchText) ?? false
            let contentMatch = note.contentData
                .flatMap { String(data: $0, encoding: .utf8) }?
                .localizedCaseInsensitiveContains(searchText) ?? false
            return titleMatch || contentMatch
        }
    }

    // MARK: - Private Helpers

    /// Sorts notes by pinned status (descending) then modified date (descending)
    private func sortNotes() {
        notes.sort { note1, note2 in
            if note1.isPinned != note2.isPinned {
                return note1.isPinned && !note2.isPinned
            }
            guard let date1 = note1.modifiedAt, let date2 = note2.modifiedAt else {
                return false
            }
            return date1 > date2
        }
    }

    // MARK: - Computed Properties

    /// Returns only pinned notes
    var pinnedNotes: [Note] {
        notes.filter { $0.isPinned }
    }

    /// Returns only unpinned notes
    var unpinnedNotes: [Note] {
        notes.filter { !$0.isPinned }
    }

    /// Returns true if there are no notes
    var isEmpty: Bool {
        notes.isEmpty
    }
}
