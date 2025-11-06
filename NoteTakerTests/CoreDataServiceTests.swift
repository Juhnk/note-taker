//
//  CoreDataServiceTests.swift
//  NoteTakerTests
//
//  Created by Juhnk on 11/6/25.
//

import Testing
import CoreData
@testable import NoteTaker

struct CoreDataServiceTests {

    // MARK: - Test Helper

    /// Creates a fresh in-memory persistence controller and service for each test
    private func createTestService() -> (CoreDataService, NSManagedObjectContext) {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let service = CoreDataService(context: context)
        return (service, context)
    }

    // MARK: - Note Creation Tests

    @Test func testCreateNote() async throws {
        let (service, _) = createTestService()

        let note = try service.createNote(title: "Test Note", content: "Test content")

        #expect(note.id != nil)
        #expect(note.title == "Test Note")
        #expect(String(data: note.contentData ?? Data(), encoding: .utf8) == "Test content")
        #expect(note.createdAt != nil)
        #expect(note.modifiedAt != nil)
        #expect(note.isPinned == false)
        #expect(note.folder == nil)
    }

    @Test func testCreateNoteWithFolder() async throws {
        let (service, _) = createTestService()

        let folder = try service.createFolder(name: "Test Folder")
        let note = try service.createNote(title: "Note in Folder", in: folder)

        #expect(note.folder == folder)
        #expect(folder.notes?.contains(note) == true)
    }

    @Test func testCreatePinnedNote() async throws {
        let (service, _) = createTestService()

        let note = try service.createNote(title: "Pinned Note", isPinned: true)

        #expect(note.isPinned == true)
    }

    // MARK: - Note Fetch Tests

    @Test func testFetchAllNotes() async throws {
        let (service, _) = createTestService()

        try service.createNote(title: "Note 1")
        try service.createNote(title: "Note 2")
        try service.createNote(title: "Note 3")

        let notes = try service.fetchNotes()

        #expect(notes.count == 3)
    }

    @Test func testFetchNotesInFolder() async throws {
        let (service, _) = createTestService()

        let folder = try service.createFolder(name: "Work")
        try service.createNote(title: "Work Note 1", in: folder)
        try service.createNote(title: "Work Note 2", in: folder)
        try service.createNote(title: "Personal Note")

        let notesInFolder = try service.fetchNotes(in: folder)

        #expect(notesInFolder.count == 2)
        #expect(notesInFolder.allSatisfy { $0.folder == folder })
    }

    @Test func testFetchNotesSortedByPinnedAndModified() async throws {
        let (service, _) = createTestService()

        let note1 = try service.createNote(title: "Normal Note")
        Thread.sleep(forTimeInterval: 0.01) // Ensure different timestamps
        let note2 = try service.createNote(title: "Pinned Note", isPinned: true)

        let notes = try service.fetchNotes()

        #expect(notes.first == note2) // Pinned note should be first
        #expect(notes.last == note1)
    }

    @Test func testFetchNoteById() async throws {
        let (service, _) = createTestService()

        let created = try service.createNote(title: "Find Me")
        let createdId = try #require(created.id)
        let fetched = try service.fetchNote(by: createdId)

        #expect(fetched != nil)
        #expect(fetched?.id == created.id)
        #expect(fetched?.title == "Find Me")
    }

    @Test func testFetchNonExistentNote() async throws {
        let (service, _) = createTestService()

        let randomUUID = UUID()
        let fetched = try service.fetchNote(by: randomUUID)

        #expect(fetched == nil)
    }

    // MARK: - Note Update Tests

    @Test func testUpdateNoteTitle() async throws {
        let (service, _) = createTestService()

        let note = try service.createNote(title: "Original Title")
        try service.updateNote(note, title: "Updated Title")

        #expect(note.title == "Updated Title")
    }

    @Test func testUpdateNoteContent() async throws {
        let (service, _) = createTestService()

        let note = try service.createNote(title: "Note", content: "Original content")
        try service.updateNote(note, content: "Updated content")

        let content = String(data: note.contentData ?? Data(), encoding: .utf8)
        #expect(content == "Updated content")
    }

    @Test func testUpdateNoteFolder() async throws {
        let (service, _) = createTestService()

        let folder1 = try service.createFolder(name: "Folder 1")
        let folder2 = try service.createFolder(name: "Folder 2")
        let note = try service.createNote(title: "Note", in: folder1)

        try service.updateNote(note, folder: folder2)

        #expect(note.folder == folder2)
        #expect(folder2.notes?.contains(note) == true)
    }

    @Test func testUpdateNotePinned() async throws {
        let (service, _) = createTestService()

        let note = try service.createNote(title: "Note", isPinned: false)
        try service.updateNote(note, isPinned: true)

        #expect(note.isPinned == true)
    }

    @Test func testUpdateNoteUpdatesModifiedDate() async throws {
        let (service, _) = createTestService()

        let note = try service.createNote(title: "Note")
        let originalModifiedDate = try #require(note.modifiedAt)

        Thread.sleep(forTimeInterval: 0.01) // Ensure different timestamp
        try service.updateNote(note, title: "Updated")

        let newModifiedDate = try #require(note.modifiedAt)
        #expect(note.modifiedAt != originalModifiedDate)
        #expect(newModifiedDate > originalModifiedDate)
    }

    // MARK: - Note Delete Tests

    @Test func testDeleteNote() async throws {
        let (service, context) = createTestService()

        let note = try service.createNote(title: "To Delete")
        let noteId = try #require(note.id)

        try service.deleteNote(note)

        let fetchRequest = Note.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", noteId as CVarArg)
        let results = try context.fetch(fetchRequest)

        #expect(results.isEmpty)
    }

    // MARK: - Folder Creation Tests

    @Test func testCreateFolder() async throws {
        let (service, _) = createTestService()

        let folder = try service.createFolder(name: "Test Folder")

        #expect(folder.id != nil)
        #expect(folder.name == "Test Folder")
        #expect(folder.createdAt != nil)
        #expect(folder.parentFolder == nil)
        #expect(folder.sortOrder == 0)
    }

    @Test func testCreateNestedFolder() async throws {
        let (service, _) = createTestService()

        let parent = try service.createFolder(name: "Parent")
        let child = try service.createFolder(name: "Child", parent: parent)

        #expect(child.parentFolder == parent)
        #expect(parent.subfolders?.contains(child) == true)
    }

    @Test func testCreateFolderWithIcon() async throws {
        let (service, _) = createTestService()

        let folder = try service.createFolder(name: "Folder", icon: "folder.fill")

        #expect(folder.icon == "folder.fill")
    }

    // MARK: - Folder Fetch Tests

    @Test func testFetchAllRootFolders() async throws {
        let (service, _) = createTestService()

        try service.createFolder(name: "Folder 1")
        try service.createFolder(name: "Folder 2")
        let parent = try service.createFolder(name: "Parent")
        try service.createFolder(name: "Child", parent: parent)

        let rootFolders = try service.fetchFolders()

        #expect(rootFolders.count == 3) // Only root-level folders
        #expect(rootFolders.allSatisfy { $0.parentFolder == nil })
    }

    @Test func testFetchSubfolders() async throws {
        let (service, _) = createTestService()

        let parent = try service.createFolder(name: "Parent")
        try service.createFolder(name: "Child 1", parent: parent)
        try service.createFolder(name: "Child 2", parent: parent)

        let subfolders = try service.fetchFolders(under: parent)

        #expect(subfolders.count == 2)
        #expect(subfolders.allSatisfy { $0.parentFolder == parent })
    }

    @Test func testFetchFolderById() async throws {
        let (service, _) = createTestService()

        let created = try service.createFolder(name: "Find Me")
        let createdId = try #require(created.id)
        let fetched = try service.fetchFolder(by: createdId)

        #expect(fetched != nil)
        #expect(fetched?.id == created.id)
        #expect(fetched?.name == "Find Me")
    }

    // MARK: - Folder Update Tests

    @Test func testUpdateFolderName() async throws {
        let (service, _) = createTestService()

        let folder = try service.createFolder(name: "Original Name")
        try service.updateFolder(folder, name: "Updated Name")

        #expect(folder.name == "Updated Name")
    }

    @Test func testUpdateFolderParent() async throws {
        let (service, _) = createTestService()

        let parent1 = try service.createFolder(name: "Parent 1")
        let parent2 = try service.createFolder(name: "Parent 2")
        let folder = try service.createFolder(name: "Child", parent: parent1)

        try service.updateFolder(folder, parent: parent2)

        #expect(folder.parentFolder == parent2)
        #expect(parent2.subfolders?.contains(folder) == true)
    }

    @Test func testUpdateFolderIcon() async throws {
        let (service, _) = createTestService()

        let folder = try service.createFolder(name: "Folder")
        try service.updateFolder(folder, icon: "star.fill")

        #expect(folder.icon == "star.fill")
    }

    // MARK: - Folder Delete Tests

    @Test func testDeleteFolder() async throws {
        let (service, context) = createTestService()

        let folder = try service.createFolder(name: "To Delete")
        let folderId = try #require(folder.id)

        try service.deleteFolder(folder)

        let fetchRequest = Folder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", folderId as CVarArg)
        let results = try context.fetch(fetchRequest)

        #expect(results.isEmpty)
    }

    @Test func testDeleteFolderNullifiesNoteRelationship() async throws {
        let (service, _) = createTestService()

        let folder = try service.createFolder(name: "Folder")
        let note = try service.createNote(title: "Note", in: folder)

        try service.deleteFolder(folder)

        #expect(note.folder == nil)
    }

    // MARK: - Integration Tests

    @Test func testCompleteNoteLifecycle() async throws {
        let (service, _) = createTestService()

        // Create
        let note = try service.createNote(title: "Lifecycle Test", content: "Initial content")
        #expect(note.title == "Lifecycle Test")

        // Read
        let noteId = try #require(note.id)
        let fetched = try service.fetchNote(by: noteId)
        #expect(fetched != nil)

        // Update
        try service.updateNote(note, title: "Updated Title", content: "Updated content")
        #expect(note.title == "Updated Title")

        // Delete
        try service.deleteNote(note)
        let deletedNote = try service.fetchNote(by: noteId)
        #expect(deletedNote == nil)
    }

    @Test func testCompleteFolderLifecycle() async throws {
        let (service, _) = createTestService()

        // Create
        let folder = try service.createFolder(name: "Lifecycle Test")
        #expect(folder.name == "Lifecycle Test")

        // Read
        let folderId = try #require(folder.id)
        let fetched = try service.fetchFolder(by: folderId)
        #expect(fetched != nil)

        // Update
        try service.updateFolder(folder, name: "Updated Name")
        #expect(folder.name == "Updated Name")

        // Delete
        try service.deleteFolder(folder)
        let deletedFolder = try service.fetchFolder(by: folderId)
        #expect(deletedFolder == nil)
    }

    @Test func testMovingNoteBetweenFolders() async throws {
        let (service, _) = createTestService()

        let folder1 = try service.createFolder(name: "Folder 1")
        let folder2 = try service.createFolder(name: "Folder 2")
        let note = try service.createNote(title: "Note", in: folder1)

        #expect(folder1.notes?.contains(note) == true)
        #expect(folder2.notes?.contains(note) == false)

        try service.updateNote(note, folder: folder2)

        #expect(folder2.notes?.contains(note) == true)
    }

    @Test func testCascadeFolderHierarchy() async throws {
        let (service, _) = createTestService()

        let grandparent = try service.createFolder(name: "Grandparent")
        let parent = try service.createFolder(name: "Parent", parent: grandparent)
        let child = try service.createFolder(name: "Child", parent: parent)

        #expect(child.parentFolder == parent)
        #expect(parent.parentFolder == grandparent)
        #expect(grandparent.subfolders?.contains(parent) == true)
        #expect(parent.subfolders?.contains(child) == true)
    }
}
