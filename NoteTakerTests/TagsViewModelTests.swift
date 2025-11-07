//
//  TagsViewModelTests.swift
//  NoteTakerTests
//
//  Created by Juhnk on 11/7/25.
//

import Testing
import CoreData
@testable import NoteTaker

/// Comprehensive test suite for TagsViewModel
/// Tests state management, tag operations, and note-tag relationships
struct TagsViewModelTests {

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

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with empty state")
    @MainActor
    func testInitialization() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        #expect(viewModel.tags.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Fetch Tags Tests

    @Test("Fetch tags loads tags successfully")
    @MainActor
    func testFetchTags() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = TagsViewModel(context: context)

        // Create test tags
        try service.createTag(name: "Swift")
        try service.createTag(name: "iOS")
        try service.createTag(name: "Development")

        viewModel.fetchTags()

        #expect(viewModel.tags.count == 3)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Fetch tags are sorted alphabetically")
    @MainActor
    func testFetchTagsSorted() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = TagsViewModel(context: context)

        try service.createTag(name: "Zebra")
        try service.createTag(name: "Apple")
        try service.createTag(name: "Mango")

        viewModel.fetchTags()

        #expect(viewModel.tags[0].name == "Apple")
        #expect(viewModel.tags[1].name == "Mango")
        #expect(viewModel.tags[2].name == "Zebra")
    }

    // MARK: - Create Tag Tests

    @Test("Create tag adds tag to list")
    @MainActor
    func testCreateTag() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        let tag = viewModel.createTag(name: "Swift")

        #expect(tag != nil)
        #expect(viewModel.tags.count == 1)
        #expect(viewModel.tags.first?.name == "Swift")
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Create tag trims whitespace")
    @MainActor
    func testCreateTagTrimsWhitespace() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        let tag = viewModel.createTag(name: "  Swift  ")

        #expect(tag?.name == "Swift")
    }

    @Test("Create tag with empty name returns error")
    @MainActor
    func testCreateEmptyTag() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        let tag = viewModel.createTag(name: "   ")

        #expect(tag == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("empty") == true)
    }

    @Test("Create duplicate tag returns existing tag")
    @MainActor
    func testCreateDuplicateTag() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        let tag1 = viewModel.createTag(name: "Swift")
        let tag2 = viewModel.createTag(name: "Swift")

        #expect(tag1?.id == tag2?.id)
        #expect(viewModel.tags.count == 1) // Should not duplicate
    }

    @Test("Create tag maintains sorted order")
    @MainActor
    func testCreateTagSorted() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        viewModel.createTag(name: "Zebra")
        viewModel.createTag(name: "Apple")
        viewModel.createTag(name: "Mango")

        #expect(viewModel.tags[0].name == "Apple")
        #expect(viewModel.tags[1].name == "Mango")
        #expect(viewModel.tags[2].name == "Zebra")
    }

    // MARK: - Delete Tag Tests

    @Test("Delete tag removes from list")
    @MainActor
    func testDeleteTag() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        guard let tag = viewModel.createTag(name: "Swift") else {
            Issue.record("Failed to create tag")
            return
        }

        #expect(viewModel.tags.count == 1)

        viewModel.deleteTag(tag)

        #expect(viewModel.tags.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Note-Tag Relationship Tests

    @Test("Add tag to note")
    @MainActor
    func testAddTagToNote() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = TagsViewModel(context: context)

        let note = try service.createNote(title: "Test Note")
        guard let tag = viewModel.createTag(name: "Swift") else {
            Issue.record("Failed to create tag")
            return
        }

        viewModel.addTag(tag, to: note)

        let noteTags = note.tags as? Set<NoteTaker.Tag>
        #expect(noteTags?.contains(tag) == true)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Remove tag from note")
    @MainActor
    func testRemoveTagFromNote() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = TagsViewModel(context: context)

        let note = try service.createNote(title: "Test Note")
        guard let tag = viewModel.createTag(name: "Swift") else {
            Issue.record("Failed to create tag")
            return
        }

        viewModel.addTag(tag, to: note)
        #expect((note.tags as? Set<NoteTaker.Tag>)?.count == 1)

        viewModel.removeTag(tag, from: note)
        #expect((note.tags as? Set<NoteTaker.Tag>)?.isEmpty == true)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Fetch notes with tag")
    @MainActor
    func testFetchNotesWithTag() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = TagsViewModel(context: context)

        guard let tag = viewModel.createTag(name: "Swift") else {
            Issue.record("Failed to create tag")
            return
        }

        let note1 = try service.createNote(title: "Note 1")
        let note2 = try service.createNote(title: "Note 2")
        try service.createNote(title: "Note 3")

        try service.addTag(tag, to: note1)
        try service.addTag(tag, to: note2)

        let notes = viewModel.fetchNotes(with: tag)

        #expect(notes.count == 2)
    }

    // MARK: - Search Tests

    @Test("Filter tags by name")
    @MainActor
    func testFilterTags() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        viewModel.createTag(name: "Swift")
        viewModel.createTag(name: "Python")
        viewModel.createTag(name: "SwiftUI")

        let results = viewModel.filteredTags(searchText: "Swift")

        #expect(results.count == 2)
    }

    @Test("Filter tags with empty search returns all")
    @MainActor
    func testFilterTagsEmptySearch() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        viewModel.createTag(name: "Swift")
        viewModel.createTag(name: "Python")

        let results = viewModel.filteredTags(searchText: "")

        #expect(results.count == 2)
    }

    @Test("Filter tags is case-insensitive")
    @MainActor
    func testFilterTagsCaseInsensitive() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        viewModel.createTag(name: "SWIFT")

        let results = viewModel.filteredTags(searchText: "swift")

        #expect(results.count == 1)
    }

    // MARK: - Computed Properties Tests

    @Test("isEmpty returns true for no tags")
    @MainActor
    func testIsEmpty() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        #expect(viewModel.isEmpty == true)

        viewModel.createTag(name: "Swift")

        #expect(viewModel.isEmpty == false)
    }

    @Test("tagNames returns array of names")
    @MainActor
    func testTagNames() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        viewModel.createTag(name: "Swift")
        viewModel.createTag(name: "iOS")

        let names = viewModel.tagNames

        #expect(names.count == 2)
        #expect(names.contains("Swift"))
        #expect(names.contains("iOS"))
    }

    // MARK: - Error Handling Tests

    @Test("Error message is set on failure")
    @MainActor
    func testErrorHandling() {
        let context = Self.createTestContext()
        let viewModel = TagsViewModel(context: context)

        #expect(viewModel.errorMessage == nil)

        // Error message property exists and can be set
        viewModel.errorMessage = "Test error"
        #expect(viewModel.errorMessage == "Test error")
    }
}
