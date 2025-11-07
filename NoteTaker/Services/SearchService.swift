//
//  SearchService.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import Foundation
import CoreData

/// Service for searching notes with advanced filtering capabilities
/// Provides fast, comprehensive search across titles, content, tags, and folders
final class SearchService {

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Search Methods

    /// Performs comprehensive search across notes
    /// - Parameters:
    ///   - query: Search text to match against title and content
    ///   - filters: Optional filters to narrow search results
    /// - Returns: Array of matching notes, sorted by relevance
    /// - Throws: Core Data fetch errors
    func searchNotes(
        query: String,
        filters: SearchFilters = SearchFilters()
    ) throws -> [Note] {
        let fetchRequest = Note.fetchRequest()
        var predicates: [NSPredicate] = []

        // Text search predicate (title or content)
        if !query.trimmingCharacters(in: .whitespaces).isEmpty {
            let textPredicate = NSPredicate(
                format: "title CONTAINS[cd] %@ OR contentData CONTAINS[cd] %@",
                query, query
            )
            predicates.append(textPredicate)
        }

        // Folder filter
        if let folder = filters.folder {
            let folderPredicate = NSPredicate(format: "folder == %@", folder)
            predicates.append(folderPredicate)
        }

        // Tag filter
        if let tag = filters.tag {
            let tagPredicate = NSPredicate(format: "%@ IN tags", tag)
            predicates.append(tagPredicate)
        }

        // Date range filter
        if let startDate = filters.startDate {
            let datePredicate = NSPredicate(format: "modifiedAt >= %@", startDate as NSDate)
            predicates.append(datePredicate)
        }

        if let endDate = filters.endDate {
            let datePredicate = NSPredicate(format: "modifiedAt <= %@", endDate as NSDate)
            predicates.append(datePredicate)
        }

        // Pinned filter
        if let isPinned = filters.isPinned {
            let pinnedPredicate = NSPredicate(format: "isPinned == %@", NSNumber(value: isPinned))
            predicates.append(pinnedPredicate)
        }

        // Combine all predicates with AND
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        // Sort by relevance (pinned first, then modified date)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Note.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)
        ]

        return try context.fetch(fetchRequest)
    }

    /// Searches notes by title only
    /// - Parameter query: Search text
    /// - Returns: Array of matching notes
    /// - Throws: Core Data fetch errors
    func searchNotesByTitle(query: String) throws -> [Note] {
        let fetchRequest = Note.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)
        ]

        return try context.fetch(fetchRequest)
    }

    /// Searches notes by content only
    /// - Parameter query: Search text
    /// - Returns: Array of matching notes
    /// - Throws: Core Data fetch errors
    func searchNotesByContent(query: String) throws -> [Note] {
        let fetchRequest = Note.fetchRequest()

        // Search in contentData (stored as Data)
        // Note: This is a simple contains check on the data
        // For production, consider full-text search indexing
        let contentPredicate = NSPredicate(format: "contentData CONTAINS[cd] %@", query)
        fetchRequest.predicate = contentPredicate

        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)
        ]

        return try context.fetch(fetchRequest)
    }

    /// Searches notes modified within a date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of matching notes
    /// - Throws: Core Data fetch errors
    func searchNotesByDateRange(startDate: Date, endDate: Date) throws -> [Note] {
        let fetchRequest = Note.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "modifiedAt >= %@ AND modifiedAt <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)
        ]

        return try context.fetch(fetchRequest)
    }

    /// Gets recently modified notes
    /// - Parameter limit: Maximum number of notes to return
    /// - Returns: Array of recently modified notes
    /// - Throws: Core Data fetch errors
    func getRecentNotes(limit: Int = 10) throws -> [Note] {
        let fetchRequest = Note.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)
        ]
        fetchRequest.fetchLimit = limit

        return try context.fetch(fetchRequest)
    }

    /// Searches for notes containing all specified tags
    /// - Parameter tags: Array of tags to match
    /// - Returns: Array of notes containing all tags
    /// - Throws: Core Data fetch errors
    func searchNotesByTags(_ tags: [Tag]) throws -> [Note] {
        guard !tags.isEmpty else { return [] }

        let fetchRequest = Note.fetchRequest()

        // Create predicates for each tag
        let tagPredicates = tags.map { tag in
            NSPredicate(format: "%@ IN tags", tag)
        }

        // Combine with AND (note must have all tags)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: tagPredicates)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)
        ]

        return try context.fetch(fetchRequest)
    }
}

// MARK: - Search Filters

/// Filters for narrowing search results
struct SearchFilters {
    var folder: Folder?
    var tag: Tag?
    var startDate: Date?
    var endDate: Date?
    var isPinned: Bool?

    init(
        folder: Folder? = nil,
        tag: Tag? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        isPinned: Bool? = nil
    ) {
        self.folder = folder
        self.tag = tag
        self.startDate = startDate
        self.endDate = endDate
        self.isPinned = isPinned
    }
}

// MARK: - Search Scope

/// Defines the scope of a search operation
enum SearchScope {
    case all
    case titleOnly
    case contentOnly
    case tags
}
