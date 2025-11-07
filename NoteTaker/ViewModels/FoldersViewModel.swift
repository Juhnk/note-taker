//
//  FoldersViewModel.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import Foundation
import SwiftUI
import CoreData

/// ViewModel for managing folders and folder hierarchy
/// Handles creating, fetching, and deleting folders with nested support
/// Uses @Observable for SwiftUI state management
@Observable
final class FoldersViewModel {

    // MARK: - Published State

    var folders: [Folder] = []
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

    // MARK: - Folder Operations

    /// Fetches all folders, optionally filtered by parent
    /// - Parameter parent: Optional parent folder to filter by (nil for root folders)
    @MainActor
    func fetchFolders(under parent: Folder? = nil) {
        isLoading = true
        errorMessage = nil

        do {
            folders = try service.fetchFolders(under: parent)
            isLoading = false
        } catch {
            errorMessage = "Failed to load folders: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Fetches all root-level folders (no parent)
    @MainActor
    func fetchRootFolders() {
        fetchFolders(under: nil)
    }

    /// Creates a new folder
    /// - Parameters:
    ///   - name: The folder's name
    ///   - parent: Optional parent folder for nesting
    ///   - icon: Optional SF Symbol name for folder icon
    /// - Returns: The created Folder entity
    @MainActor
    func createFolder(name: String, parent: Folder? = nil, icon: String? = nil) -> Folder? {
        errorMessage = nil

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Folder name cannot be empty"
            return nil
        }

        do {
            let folder = try service.createFolder(
                name: name.trimmingCharacters(in: .whitespaces),
                parent: parent,
                icon: icon
            )

            // Add to list if it's a root folder or matches current filter
            if parent == nil {
                folders.append(folder)
                folders.sort { ($0.name ?? "") < ($1.name ?? "") }
            }

            return folder
        } catch {
            errorMessage = "Failed to create folder: \(error.localizedDescription)"
            return nil
        }
    }

    /// Updates an existing folder
    /// - Parameters:
    ///   - folder: The folder to update
    ///   - name: New name (optional)
    ///   - parent: New parent folder (optional)
    ///   - icon: New icon (optional)
    @MainActor
    func updateFolder(
        _ folder: Folder,
        name: String? = nil,
        parent: Folder? = nil,
        icon: String? = nil
    ) {
        errorMessage = nil

        do {
            try service.updateFolder(folder, name: name, parent: parent, icon: icon)
        } catch {
            errorMessage = "Failed to update folder: \(error.localizedDescription)"
        }
    }

    /// Deletes a folder (notes are not deleted, just unlinked)
    /// - Parameter folder: The folder to delete
    @MainActor
    func deleteFolder(_ folder: Folder) {
        errorMessage = nil

        do {
            try service.deleteFolder(folder)
            folders.removeAll { $0.id == folder.id }
        } catch {
            errorMessage = "Failed to delete folder: \(error.localizedDescription)"
        }
    }

    /// Returns notes that belong to a specific folder
    /// - Parameter folder: The folder to fetch notes from
    /// - Returns: Array of notes in the folder
    func fetchNotes(in folder: Folder) -> [Note] {
        do {
            return try service.fetchNotes(in: folder)
        } catch {
            errorMessage = "Failed to fetch notes in folder: \(error.localizedDescription)"
            return []
        }
    }

    /// Returns all subfolders of a folder
    /// - Parameter folder: The parent folder
    /// - Returns: Array of child folders
    func fetchSubfolders(of folder: Folder) -> [Folder] {
        do {
            return try service.fetchFolders(under: folder)
        } catch {
            errorMessage = "Failed to fetch subfolders: \(error.localizedDescription)"
            return []
        }
    }

    // MARK: - Search

    /// Filters folders by search text
    /// - Parameter searchText: The text to search for
    /// - Returns: Filtered array of folders
    func filteredFolders(searchText: String) -> [Folder] {
        guard !searchText.isEmpty else { return folders }

        return folders.filter { folder in
            guard let name = folder.name else { return false }
            return name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Hierarchy Helpers

    /// Returns the full path of a folder (e.g., "Work/Projects/iOS")
    /// - Parameter folder: The folder to get the path for
    /// - Returns: Hierarchical path string
    func folderPath(_ folder: Folder) -> String {
        var components: [String] = []
        var current: Folder? = folder

        while let currentFolder = current {
            if let name = currentFolder.name {
                components.insert(name, at: 0)
            }
            current = currentFolder.parentFolder
        }

        return components.joined(separator: " / ")
    }

    /// Returns the depth level of a folder in the hierarchy (0 for root)
    /// - Parameter folder: The folder to check
    /// - Returns: Depth level (0 = root, 1 = first level nested, etc.)
    func folderDepth(_ folder: Folder) -> Int {
        var depth = 0
        var current = folder.parentFolder

        while current != nil {
            depth += 1
            current = current?.parentFolder
        }

        return depth
    }

    // MARK: - Computed Properties

    /// Returns true if there are no folders
    var isEmpty: Bool {
        folders.isEmpty
    }

    /// Returns folders as an array of names
    var folderNames: [String] {
        folders.compactMap { $0.name }
    }

    /// Returns root-level folders only
    var rootFolders: [Folder] {
        folders.filter { $0.parentFolder == nil }
    }
}
