//
//  TagsViewModel.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import Foundation
import SwiftUI
import CoreData

/// ViewModel for managing tags and note-tag relationships
/// Handles creating, fetching, and deleting tags
/// Uses @Observable for SwiftUI state management
@Observable
final class TagsViewModel {

    // MARK: - Published State

    var tags: [Tag] = []
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

    // MARK: - Tag Operations

    /// Fetches all tags sorted alphabetically
    @MainActor
    func fetchTags() {
        isLoading = true
        errorMessage = nil

        do {
            tags = try service.fetchTags()
            isLoading = false
        } catch {
            errorMessage = "Failed to load tags: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Creates a new tag or returns existing tag with the same name
    /// - Parameter name: The tag's name
    /// - Returns: The created or existing Tag entity
    @MainActor
    func createTag(name: String) -> Tag? {
        errorMessage = nil

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Tag name cannot be empty"
            return nil
        }

        do {
            let tag = try service.createTag(name: name.trimmingCharacters(in: .whitespaces))

            // Add to list if it's a new tag
            if !tags.contains(where: { $0.id == tag.id }) {
                tags.append(tag)
                tags.sort { ($0.name ?? "") < ($1.name ?? "") }
            }

            return tag
        } catch {
            errorMessage = "Failed to create tag: \(error.localizedDescription)"
            return nil
        }
    }

    /// Deletes a tag (removes it from all notes)
    /// - Parameter tag: The tag to delete
    @MainActor
    func deleteTag(_ tag: Tag) {
        errorMessage = nil

        do {
            try service.deleteTag(tag)
            tags.removeAll { $0.id == tag.id }
        } catch {
            errorMessage = "Failed to delete tag: \(error.localizedDescription)"
        }
    }

    // MARK: - Note-Tag Relationships

    /// Adds a tag to a note
    /// - Parameters:
    ///   - tag: The tag to add
    ///   - note: The note to add the tag to
    @MainActor
    func addTag(_ tag: Tag, to note: Note) {
        errorMessage = nil

        do {
            try service.addTag(tag, to: note)
        } catch {
            errorMessage = "Failed to add tag to note: \(error.localizedDescription)"
        }
    }

    /// Removes a tag from a note
    /// - Parameters:
    ///   - tag: The tag to remove
    ///   - note: The note to remove the tag from
    @MainActor
    func removeTag(_ tag: Tag, from note: Note) {
        errorMessage = nil

        do {
            try service.removeTag(tag, from: note)
        } catch {
            errorMessage = "Failed to remove tag from note: \(error.localizedDescription)"
        }
    }

    /// Returns notes that have a specific tag
    /// - Parameter tag: The tag to filter by
    /// - Returns: Array of notes with the tag
    func fetchNotes(with tag: Tag) -> [Note] {
        do {
            return try service.fetchNotes(with: tag)
        } catch {
            errorMessage = "Failed to fetch notes with tag: \(error.localizedDescription)"
            return []
        }
    }

    // MARK: - Search

    /// Filters tags by search text
    /// - Parameter searchText: The text to search for
    /// - Returns: Filtered array of tags
    func filteredTags(searchText: String) -> [Tag] {
        guard !searchText.isEmpty else { return tags }

        return tags.filter { tag in
            guard let name = tag.name else { return false }
            return name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Computed Properties

    /// Returns true if there are no tags
    var isEmpty: Bool {
        tags.isEmpty
    }

    /// Returns tags as an array of names
    var tagNames: [String] {
        tags.compactMap { $0.name }
    }
}
