//
//  CoreDataService.swift
//  NoteTaker
//
//  Created by Juhnk on 11/6/25.
//

import Foundation
import CoreData

/// Service layer for Core Data CRUD operations
/// Provides a clean API for managing Notes and Folders
@Observable
final class CoreDataService {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Convenience initializer using shared persistence controller
    convenience init() {
        self.init(context: PersistenceController.shared.container.viewContext)
    }

    // MARK: - Note Operations

    /// Creates a new note with the given title and content
    /// - Parameters:
    ///   - title: The note's title
    ///   - content: The note's content (plain text)
    ///   - folder: Optional folder to place the note in
    ///   - isPinned: Whether the note should be pinned
    /// - Returns: The created Note entity
    /// - Throws: Core Data save errors
    func createNote(
        title: String,
        content: String = "",
        in folder: Folder? = nil,
        isPinned: Bool = false
    ) throws -> Note {
        let note = Note(context: context)
        note.id = UUID()
        note.title = title
        note.contentData = Data(content.utf8)
        note.folder = folder
        note.isPinned = isPinned
        note.createdAt = Date()
        note.modifiedAt = Date()

        try context.save()
        return note
    }

    /// Fetches all notes, optionally filtered by folder
    /// - Parameter folder: Optional folder to filter by
    /// - Returns: Array of Note entities
    /// - Throws: Core Data fetch errors
    func fetchNotes(in folder: Folder? = nil) throws -> [Note] {
        let fetchRequest = Note.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Note.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)
        ]

        if let folder = folder {
            fetchRequest.predicate = NSPredicate(format: "folder == %@", folder)
        }

        return try context.fetch(fetchRequest)
    }

    /// Fetches a single note by ID
    /// - Parameter id: The note's UUID
    /// - Returns: The Note entity if found, nil otherwise
    /// - Throws: Core Data fetch errors
    func fetchNote(by id: UUID) throws -> Note? {
        let fetchRequest = Note.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1

        let results = try context.fetch(fetchRequest)
        return results.first
    }

    /// Updates an existing note
    /// - Parameters:
    ///   - note: The note to update
    ///   - title: New title (optional)
    ///   - content: New content (optional)
    ///   - folder: New folder (optional)
    ///   - isPinned: New pinned status (optional)
    /// - Throws: Core Data save errors
    func updateNote(
        _ note: Note,
        title: String? = nil,
        content: String? = nil,
        folder: Folder? = nil,
        isPinned: Bool? = nil
    ) throws {
        if let title = title {
            note.title = title
        }
        if let content = content {
            note.contentData = Data(content.utf8)
        }
        if let folder = folder {
            note.folder = folder
        }
        if let isPinned = isPinned {
            note.isPinned = isPinned
        }

        note.modifiedAt = Date()
        try context.save()
    }

    /// Deletes a note
    /// - Parameter note: The note to delete
    /// - Throws: Core Data save errors
    func deleteNote(_ note: Note) throws {
        context.delete(note)
        try context.save()
    }

    // MARK: - Folder Operations

    /// Creates a new folder
    /// - Parameters:
    ///   - name: The folder's name
    ///   - parent: Optional parent folder for nested hierarchy
    ///   - icon: Optional icon name
    /// - Returns: The created Folder entity
    /// - Throws: Core Data save errors
    func createFolder(
        name: String,
        parent: Folder? = nil,
        icon: String? = nil
    ) throws -> Folder {
        let folder = Folder(context: context)
        folder.id = UUID()
        folder.name = name
        folder.parentFolder = parent
        folder.icon = icon
        folder.createdAt = Date()
        folder.sortOrder = 0 // Default sort order

        try context.save()
        return folder
    }

    /// Fetches all folders, optionally filtered by parent
    /// - Parameter parent: Optional parent folder to filter by
    /// - Returns: Array of Folder entities
    /// - Throws: Core Data fetch errors
    func fetchFolders(under parent: Folder? = nil) throws -> [Folder] {
        let fetchRequest = Folder.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Folder.sortOrder, ascending: true)]

        if let parent = parent {
            fetchRequest.predicate = NSPredicate(format: "parentFolder == %@", parent)
        } else {
            // Fetch only root-level folders (no parent)
            fetchRequest.predicate = NSPredicate(format: "parentFolder == nil")
        }

        return try context.fetch(fetchRequest)
    }

    /// Fetches a single folder by ID
    /// - Parameter id: The folder's UUID
    /// - Returns: The Folder entity if found, nil otherwise
    /// - Throws: Core Data fetch errors
    func fetchFolder(by id: UUID) throws -> Folder? {
        let fetchRequest = Folder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1

        let results = try context.fetch(fetchRequest)
        return results.first
    }

    /// Updates an existing folder
    /// - Parameters:
    ///   - folder: The folder to update
    ///   - name: New name (optional)
    ///   - parent: New parent folder (optional)
    ///   - icon: New icon (optional)
    /// - Throws: Core Data save errors
    func updateFolder(
        _ folder: Folder,
        name: String? = nil,
        parent: Folder? = nil,
        icon: String? = nil
    ) throws {
        if let name = name {
            folder.name = name
        }
        if let parent = parent {
            folder.parentFolder = parent
        }
        if let icon = icon {
            folder.icon = icon
        }

        try context.save()
    }

    /// Deletes a folder
    /// Note: This will nullify the folder relationship for any notes in the folder
    /// - Parameter folder: The folder to delete
    /// - Throws: Core Data save errors
    func deleteFolder(_ folder: Folder) throws {
        context.delete(folder)
        try context.save()
    }

    // MARK: - Tag Operations

    /// Creates a new tag or returns existing tag with the same name
    /// - Parameter name: The tag's name
    /// - Returns: The created or existing Tag entity
    /// - Throws: Core Data save errors
    func createTag(name: String) throws -> Tag {
        // Check if tag with this name already exists (unique constraint)
        let fetchRequest = Tag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", name)
        fetchRequest.fetchLimit = 1

        if let existingTag = try context.fetch(fetchRequest).first {
            return existingTag
        }

        // Create new tag
        let tag = Tag(context: context)
        tag.id = UUID()
        tag.name = name

        try context.save()
        return tag
    }

    /// Fetches all tags sorted alphabetically
    /// - Returns: Array of Tag entities
    /// - Throws: Core Data fetch errors
    func fetchTags() throws -> [Tag] {
        let fetchRequest = Tag.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
        return try context.fetch(fetchRequest)
    }

    /// Fetches a single tag by ID
    /// - Parameter id: The tag's UUID
    /// - Returns: The Tag entity if found, nil otherwise
    /// - Throws: Core Data fetch errors
    func fetchTag(by id: UUID) throws -> Tag? {
        let fetchRequest = Tag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1

        let results = try context.fetch(fetchRequest)
        return results.first
    }

    /// Deletes a tag (removes it from all notes)
    /// - Parameter tag: The tag to delete
    /// - Throws: Core Data save errors
    func deleteTag(_ tag: Tag) throws {
        context.delete(tag)
        try context.save()
    }

    /// Adds a tag to a note
    /// - Parameters:
    ///   - tag: The tag to add
    ///   - note: The note to add the tag to
    /// - Throws: Core Data save errors
    func addTag(_ tag: Tag, to note: Note) throws {
        note.addToTags(tag)
        note.modifiedAt = Date()
        try context.save()
    }

    /// Removes a tag from a note
    /// - Parameters:
    ///   - tag: The tag to remove
    ///   - note: The note to remove the tag from
    /// - Throws: Core Data save errors
    func removeTag(_ tag: Tag, from note: Note) throws {
        note.removeFromTags(tag)
        note.modifiedAt = Date()
        try context.save()
    }

    /// Fetches notes that have a specific tag
    /// - Parameter tag: The tag to filter by
    /// - Returns: Array of Note entities
    /// - Throws: Core Data fetch errors
    func fetchNotes(with tag: Tag) throws -> [Note] {
        let fetchRequest = Note.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%@ IN tags", tag)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Note.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)
        ]

        return try context.fetch(fetchRequest)
    }

    // MARK: - Helper Methods

    /// Saves the context if there are unsaved changes
    /// - Throws: Core Data save errors
    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
