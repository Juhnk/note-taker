//
//  CoreDataCRUDTests.swift
//  NoteTakerTests
//
//  Created by Juhnk on 11/5/25.
//

import Testing
import CoreData
@testable import NoteTaker

struct CoreDataCRUDTests {

    // MARK: - Test Helper

    /// Creates a fresh in-memory persistence controller for each test
    private func createTestController() -> PersistenceController {
        return PersistenceController(inMemory: true)
    }

    // MARK: - Note CRUD Tests

    @Test func testCreateNote() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create a note
        let note = Note(context: context)
        note.id = UUID()
        note.title = "Test Note"
        note.contentData = "Test content".data(using: .utf8)
        note.createdAt = Date()
        note.modifiedAt = Date()
        note.isPinned = false

        // Save
        try context.save()

        // Fetch and verify
        let fetchRequest = Note.fetchRequest()
        let notes = try context.fetch(fetchRequest)

        #expect(notes.count == 1)
        #expect(notes.first?.title == "Test Note")
        #expect(notes.first?.id != nil)
        #expect(notes.first?.isPinned == false)
    }

    @Test func testReadNote() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create and save a note
        let noteId = UUID()
        let note = Note(context: context)
        note.id = noteId
        note.title = "Read Test"
        note.createdAt = Date()
        note.modifiedAt = Date()
        try context.save()

        // Fetch by ID
        let fetchRequest = Note.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteId as CVarArg)
        let notes = try context.fetch(fetchRequest)

        #expect(notes.count == 1)
        #expect(notes.first?.id == noteId)
        #expect(notes.first?.title == "Read Test")
    }

    @Test func testUpdateNote() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create a note
        let note = Note(context: context)
        note.id = UUID()
        note.title = "Original Title"
        note.createdAt = Date()
        note.modifiedAt = Date()
        try context.save()

        // Update the note
        note.title = "Updated Title"
        note.modifiedAt = Date()
        try context.save()

        // Fetch and verify
        let fetchRequest = Note.fetchRequest()
        let notes = try context.fetch(fetchRequest)

        #expect(notes.count == 1)
        #expect(notes.first?.title == "Updated Title")
    }

    @Test func testDeleteNote() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create a note
        let note = Note(context: context)
        note.id = UUID()
        note.title = "To Delete"
        note.createdAt = Date()
        note.modifiedAt = Date()
        try context.save()

        // Verify it exists
        var fetchRequest = Note.fetchRequest()
        var notes = try context.fetch(fetchRequest)
        #expect(notes.count == 1)

        // Delete the note
        context.delete(note)
        try context.save()

        // Verify it's deleted
        fetchRequest = Note.fetchRequest()
        notes = try context.fetch(fetchRequest)
        #expect(notes.count == 0)
    }

    @Test func testNotePinning() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create a pinned note
        let note = Note(context: context)
        note.id = UUID()
        note.title = "Pinned Note"
        note.createdAt = Date()
        note.modifiedAt = Date()
        note.isPinned = true
        try context.save()

        // Fetch and verify
        let fetchRequest = Note.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isPinned == YES")
        let pinnedNotes = try context.fetch(fetchRequest)

        #expect(pinnedNotes.count == 1)
        #expect(pinnedNotes.first?.isPinned == true)
    }

    // MARK: - Folder CRUD Tests

    @Test func testCreateFolder() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create a folder
        let folder = Folder(context: context)
        folder.id = UUID()
        folder.name = "Test Folder"
        folder.createdAt = Date()
        folder.sortOrder = 1
        try context.save()

        // Fetch and verify
        let fetchRequest = Folder.fetchRequest()
        let folders = try context.fetch(fetchRequest)

        #expect(folders.count == 1)
        #expect(folders.first?.name == "Test Folder")
        #expect(folders.first?.sortOrder == 1)
    }

    @Test func testFolderHierarchy() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create parent folder
        let parentFolder = Folder(context: context)
        parentFolder.id = UUID()
        parentFolder.name = "Parent Folder"
        parentFolder.createdAt = Date()

        // Create child folder
        let childFolder = Folder(context: context)
        childFolder.id = UUID()
        childFolder.name = "Child Folder"
        childFolder.createdAt = Date()
        childFolder.parentFolder = parentFolder

        try context.save()

        // Verify relationship
        #expect(childFolder.parentFolder == parentFolder)
        #expect(parentFolder.subfolders?.contains(childFolder) == true)
    }

    @Test func testNoteInFolder() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create folder
        let folder = Folder(context: context)
        folder.id = UUID()
        folder.name = "Work"
        folder.createdAt = Date()

        // Create note in folder
        let note = Note(context: context)
        note.id = UUID()
        note.title = "Work Note"
        note.createdAt = Date()
        note.modifiedAt = Date()
        note.folder = folder

        try context.save()

        // Verify relationship
        #expect(note.folder == folder)
        #expect(folder.notes?.contains(note) == true)
    }

    // MARK: - Tag CRUD Tests

    @Test func testCreateTag() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create a tag
        let tag = Tag(context: context)
        tag.id = UUID()
        tag.name = "Important"
        try context.save()

        // Fetch and verify
        let fetchRequest = Tag.fetchRequest()
        let tags = try context.fetch(fetchRequest)

        #expect(tags.count == 1)
        #expect(tags.first?.name == "Important")
    }

    @Test func testTagUniqueConstraint() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create first tag
        let tag1 = Tag(context: context)
        tag1.id = UUID()
        tag1.name = "Duplicate"
        try context.save()

        // Try to create duplicate tag
        let tag2 = Tag(context: context)
        tag2.id = UUID()
        tag2.name = "Duplicate"

        // This should fail due to unique constraint
        do {
            try context.save()
            // If save succeeds, the test should fail
            Issue.record("Expected unique constraint violation but save succeeded")
        } catch {
            // Expected to fail - unique constraint violation
            #expect(error is NSError)
        }
    }

    @Test func testNoteWithMultipleTags() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create tags
        let tag1 = Tag(context: context)
        tag1.id = UUID()
        tag1.name = "Work"

        let tag2 = Tag(context: context)
        tag2.id = UUID()
        tag2.name = "Urgent"

        // Create note with tags
        let note = Note(context: context)
        note.id = UUID()
        note.title = "Tagged Note"
        note.createdAt = Date()
        note.modifiedAt = Date()
        note.addToTags(tag1)
        note.addToTags(tag2)

        try context.save()

        // Verify relationships
        #expect(note.tags?.count == 2)
        #expect(tag1.notes?.contains(note) == true)
        #expect(tag2.notes?.contains(note) == true)
    }

    // MARK: - Attachment CRUD Tests

    @Test func testCreateAttachment() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create note
        let note = Note(context: context)
        note.id = UUID()
        note.title = "Note with Attachment"
        note.createdAt = Date()
        note.modifiedAt = Date()

        // Create attachment
        let attachment = Attachment(context: context)
        attachment.id = UUID()
        attachment.fileName = "test.jpg"
        attachment.type = "image/jpeg"
        attachment.fileSize = 1024
        attachment.localURL = "/path/to/test.jpg"
        attachment.note = note

        try context.save()

        // Fetch and verify
        let fetchRequest = Attachment.fetchRequest()
        let attachments = try context.fetch(fetchRequest)

        #expect(attachments.count == 1)
        #expect(attachments.first?.fileName == "test.jpg")
        #expect(attachments.first?.type == "image/jpeg")
        #expect(attachments.first?.fileSize == 1024)
        #expect(attachments.first?.note == note)
    }

    @Test func testAttachmentCascadeDelete() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create note with attachment
        let note = Note(context: context)
        note.id = UUID()
        note.title = "Note to Delete"
        note.createdAt = Date()
        note.modifiedAt = Date()

        let attachment = Attachment(context: context)
        attachment.id = UUID()
        attachment.fileName = "cascade.jpg"
        attachment.type = "image/jpeg"
        attachment.note = note

        try context.save()

        // Verify attachment exists
        var fetchRequest = Attachment.fetchRequest()
        var attachments = try context.fetch(fetchRequest)
        #expect(attachments.count == 1)

        // Delete note
        context.delete(note)
        try context.save()

        // Verify attachment was cascade deleted
        fetchRequest = Attachment.fetchRequest()
        attachments = try context.fetch(fetchRequest)
        #expect(attachments.count == 0)
    }

    // MARK: - Complex Relationship Tests

    @Test func testCompleteNoteWithAllRelationships() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create folder
        let folder = Folder(context: context)
        folder.id = UUID()
        folder.name = "Projects"
        folder.createdAt = Date()

        // Create tags
        let tag1 = Tag(context: context)
        tag1.id = UUID()
        tag1.name = "Important"

        let tag2 = Tag(context: context)
        tag2.id = UUID()
        tag2.name = "Review"

        // Create note
        let note = Note(context: context)
        note.id = UUID()
        note.title = "Complete Note"
        note.contentData = "Full content".data(using: .utf8)
        note.createdAt = Date()
        note.modifiedAt = Date()
        note.isPinned = true
        note.folder = folder
        note.addToTags(tag1)
        note.addToTags(tag2)

        // Create attachments
        let attachment1 = Attachment(context: context)
        attachment1.id = UUID()
        attachment1.fileName = "image.jpg"
        attachment1.type = "image/jpeg"
        attachment1.note = note

        let attachment2 = Attachment(context: context)
        attachment2.id = UUID()
        attachment2.fileName = "video.mp4"
        attachment2.type = "video/mp4"
        attachment2.note = note

        try context.save()

        // Verify all relationships
        #expect(note.folder == folder)
        #expect(note.tags?.count == 2)
        #expect(note.attachments?.count == 2)
        #expect(folder.notes?.contains(note) == true)
        #expect(tag1.notes?.contains(note) == true)
        #expect(tag2.notes?.contains(note) == true)
    }

    @Test func testFetchNotesInFolder() async throws {
        let controller = createTestController()
        let context = controller.container.viewContext

        // Create folder
        let folder = Folder(context: context)
        folder.id = UUID()
        folder.name = "Test Folder"
        folder.createdAt = Date()

        // Create notes in folder
        for i in 1...5 {
            let note = Note(context: context)
            note.id = UUID()
            note.title = "Note \(i)"
            note.createdAt = Date()
            note.modifiedAt = Date()
            note.folder = folder
        }

        try context.save()

        // Fetch notes in specific folder
        let fetchRequest = Note.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "folder == %@", folder)
        let notes = try context.fetch(fetchRequest)

        #expect(notes.count == 5)
        #expect(notes.allSatisfy { $0.folder == folder })
    }
}
