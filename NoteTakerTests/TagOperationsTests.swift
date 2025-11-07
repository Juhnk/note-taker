//
//  TagOperationsTests.swift
//  NoteTakerTests
//
//  Created by Juhnk on 11/7/25.
//

import Testing
import CoreData
@testable import NoteTaker

/// Comprehensive test suite for tag operations
/// Tests CRUD operations, tag assignment to notes, and filtering
struct TagOperationsTests {

    // MARK: - Test Helpers

    /// Creates an in-memory Core Data stack for testing
    @MainActor
    static func createTestContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "NoteTaker")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }

        return container.viewContext
    }

    // MARK: - Tag Creation Tests

    @Test("Create new tag")
    @MainActor
    func testCreateTag() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        let tag = try service.createTag(name: "Swift")

        #expect(tag.id != nil)
        #expect(tag.name == "Swift")
    }

    @Test("Create tag with existing name returns existing tag")
    @MainActor
    func testCreateDuplicateTag() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        let tag1 = try service.createTag(name: "Swift")
        let tag2 = try service.createTag(name: "Swift")

        #expect(tag1.id == tag2.id)
        #expect(tag1 === tag2) // Same object
    }

    @Test("Create tag is case-insensitive")
    @MainActor
    func testCreateTagCaseInsensitive() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        let tag1 = try service.createTag(name: "Swift")
        let tag2 = try service.createTag(name: "SWIFT")
        let tag3 = try service.createTag(name: "swift")

        #expect(tag1.id == tag2.id)
        #expect(tag2.id == tag3.id)
    }

    // MARK: - Tag Fetch Tests

    @Test("Fetch all tags sorted alphabetically")
    @MainActor
    func testFetchTags() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        try service.createTag(name: "Zebra")
        try service.createTag(name: "Apple")
        try service.createTag(name: "Mango")

        let tags = try service.fetchTags()

        #expect(tags.count == 3)
        #expect(tags[0].name == "Apple")
        #expect(tags[1].name == "Mango")
        #expect(tags[2].name == "Zebra")
    }

    @Test("Fetch tag by ID")
    @MainActor
    func testFetchTagById() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        let createdTag = try service.createTag(name: "Swift")
        guard let tagId = createdTag.id else {
            throw TestError.missingId
        }

        let fetchedTag = try service.fetchTag(by: tagId)

        #expect(fetchedTag != nil)
        #expect(fetchedTag?.id == tagId)
        #expect(fetchedTag?.name == "Swift")
    }

    @Test("Fetch non-existent tag returns nil")
    @MainActor
    func testFetchNonExistentTag() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        let result = try service.fetchTag(by: UUID())

        #expect(result == nil)
    }

    // MARK: - Tag Assignment Tests

    @Test("Add tag to note")
    @MainActor
    func testAddTagToNote() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        let note = try service.createNote(title: "Test Note")
        let tag = try service.createTag(name: "Swift")

        try service.addTag(tag, to: note)

        let noteTags = note.tags as? Set<NoteTaker.Tag>
        #expect(noteTags?.count == 1)
        #expect(noteTags?.contains(tag) == true)
    }

    @Test("Add multiple tags to note")
    @MainActor
    func testAddMultipleTagsToNote() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        let note = try service.createNote(title: "Test Note")
        let tag1 = try service.createTag(name: "Swift")
        let tag2 = try service.createTag(name: "iOS")
        let tag3 = try service.createTag(name: "Development")

        try service.addTag(tag1, to: note)
        try service.addTag(tag2, to: note)
        try service.addTag(tag3, to: note)

        let noteTags = note.tags as? Set<NoteTaker.Tag>
        #expect(noteTags?.count == 3)
        #expect(noteTags?.contains(tag1) == true)
        #expect(noteTags?.contains(tag2) == true)
        #expect(noteTags?.contains(tag3) == true)
    }

    @Test("Remove tag from note")
    @MainActor
    func testRemoveTagFromNote() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        let note = try service.createNote(title: "Test Note")
        let tag = try service.createTag(name: "Swift")

        try service.addTag(tag, to: note)
        #expect((note.tags as? Set<NoteTaker.Tag>)?.count == 1)

        try service.removeTag(tag, from: note)
        #expect((note.tags as? Set<NoteTaker.Tag>)?.isEmpty == true)
    }

    @Test("Adding tag updates note modified date")
    @MainActor
    func testAddingTagUpdatesModifiedDate() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        let note = try service.createNote(title: "Test Note")
        let originalModifiedAt = note.modifiedAt

        // Wait a brief moment to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        let tag = try service.createTag(name: "Swift")
        try service.addTag(tag, to: note)

        guard let noteModifiedAt = note.modifiedAt,
              let originalDate = originalModifiedAt else {
            throw TestError.missingTimestamp
        }
        #expect(noteModifiedAt > originalDate)
    }

    // MARK: - Tag Deletion Tests

    @Test("Delete tag removes it from all notes")
    @MainActor
    func testDeleteTagRemovesFromNotes() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        let note1 = try service.createNote(title: "Note 1")
        let note2 = try service.createNote(title: "Note 2")
        let tag = try service.createTag(name: "Swift")

        try service.addTag(tag, to: note1)
        try service.addTag(tag, to: note2)

        #expect((note1.tags as? Set<NoteTaker.Tag>)?.count == 1)
        #expect((note2.tags as? Set<NoteTaker.Tag>)?.count == 1)

        try service.deleteTag(tag)

        #expect((note1.tags as? Set<NoteTaker.Tag>)?.isEmpty == true)
        #expect((note2.tags as? Set<NoteTaker.Tag>)?.isEmpty == true)
    }

    // MARK: - Tag Filtering Tests

    @Test("Fetch notes with specific tag")
    @MainActor
    func testFetchNotesWithTag() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        let swiftTag = try service.createTag(name: "Swift")
        let iosTag = try service.createTag(name: "iOS")

        let note1 = try service.createNote(title: "Swift Basics")
        let note2 = try service.createNote(title: "iOS Development")
        let note3 = try service.createNote(title: "Swift & iOS")

        try service.addTag(swiftTag, to: note1)
        try service.addTag(iosTag, to: note2)
        try service.addTag(swiftTag, to: note3)
        try service.addTag(iosTag, to: note3)

        let swiftNotes = try service.fetchNotes(with: swiftTag)
        #expect(swiftNotes.count == 2)
        #expect(swiftNotes.contains(note1))
        #expect(swiftNotes.contains(note3))

        let iosNotes = try service.fetchNotes(with: iosTag)
        #expect(iosNotes.count == 2)
        #expect(iosNotes.contains(note2))
        #expect(iosNotes.contains(note3))
    }

    @Test("Fetch notes with tag respects sort order")
    @MainActor
    func testFetchNotesWithTagSorted() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)

        let tag = try service.createTag(name: "Swift")

        let note1 = try service.createNote(title: "Note 1", isPinned: false)
        let note2 = try service.createNote(title: "Note 2", isPinned: true)
        let note3 = try service.createNote(title: "Note 3", isPinned: false)

        try service.addTag(tag, to: note1)
        try service.addTag(tag, to: note2)
        try service.addTag(tag, to: note3)

        let notes = try service.fetchNotes(with: tag)

        // Pinned notes should come first
        #expect(notes.count == 3)
        #expect(notes[0].isPinned == true)
        #expect(notes[1].isPinned == false)
        #expect(notes[2].isPinned == false)
    }

    // MARK: - Error enum

    enum TestError: Error {
        case missingId
        case missingTimestamp
    }
}
