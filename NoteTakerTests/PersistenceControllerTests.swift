//
//  PersistenceControllerTests.swift
//  NoteTakerTests
//
//  Created by Juhnk on 11/5/25.
//

import Testing
import CoreData
@testable import NoteTaker

struct PersistenceControllerTests {

    // MARK: - Initialization Tests

    @Test func testSharedInstanceExists() async throws {
        // Verify shared instance is accessible
        let controller = PersistenceController.shared
        #expect(controller.container != nil)
    }

    @Test func testInMemoryStoreCreation() async throws {
        // Create in-memory store for testing
        let controller = PersistenceController(inMemory: true)

        // Verify container exists and is configured
        #expect(controller.container != nil)
        #expect(controller.container.viewContext != nil)

        // Verify store is in-memory by checking URL
        if let storeDescription = controller.container.persistentStoreDescriptions.first {
            #expect(storeDescription.url?.path == "/dev/null")
        }
    }

    @Test func testContainerUsesCloudKit() async throws {
        // Verify container is NSPersistentCloudKitContainer type
        let controller = PersistenceController(inMemory: true)
        #expect(controller.container is NSPersistentCloudKitContainer)
    }

    @Test func testViewContextConfiguration() async throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Verify automatic merge is enabled
        #expect(context.automaticallyMergesChangesFromParent == true)

        // Verify merge policy is set (check it's not nil)
        #expect(context.mergePolicy != nil)
    }

    // MARK: - Preview Tests

    @MainActor
    @Test func testPreviewControllerCreatesData() async throws {
        let controller = PersistenceController.preview
        let context = controller.container.viewContext

        // Fetch all notes
        let fetchRequest = Note.fetchRequest()
        let notes = try context.fetch(fetchRequest)

        // Verify preview data was created
        #expect(notes.count == 10)

        // Verify first note properties
        if let firstNote = notes.first {
            #expect(firstNote.title?.contains("Sample Note") == true)
            #expect(firstNote.id != nil)
            #expect(firstNote.createdAt != nil)
            #expect(firstNote.modifiedAt != nil)
            #expect(firstNote.isPinned == false)
        }
    }
}
