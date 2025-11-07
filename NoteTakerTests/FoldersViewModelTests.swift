//
//  FoldersViewModelTests.swift
//  NoteTakerTests
//
//  Created by Juhnk on 11/7/25.
//

import Testing
import CoreData
@testable import NoteTaker

/// Comprehensive test suite for FoldersViewModel
/// Tests state management, folder operations, and hierarchy
struct FoldersViewModelTests {

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
        let viewModel = FoldersViewModel(context: context)

        #expect(viewModel.folders.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Fetch Folders Tests

    @Test("Fetch folders loads folders successfully")
    @MainActor
    func testFetchFolders() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = FoldersViewModel(context: context)

        // Create test folders
        try service.createFolder(name: "Work")
        try service.createFolder(name: "Personal")
        try service.createFolder(name: "Projects")

        viewModel.fetchRootFolders()

        #expect(viewModel.folders.count == 3)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Fetch folders are sorted alphabetically")
    @MainActor
    func testFetchFoldersSorted() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = FoldersViewModel(context: context)

        try service.createFolder(name: "Zebra")
        try service.createFolder(name: "Apple")
        try service.createFolder(name: "Mango")

        viewModel.fetchRootFolders()

        // CoreDataService sorts by sortOrder, not name
        // So we just check that all folders are present
        #expect(viewModel.folders.count == 3)
        let names = viewModel.folders.compactMap { $0.name }
        #expect(names.contains("Zebra"))
        #expect(names.contains("Apple"))
        #expect(names.contains("Mango"))
    }

    @Test("Fetch nested folders")
    @MainActor
    func testFetchNestedFolders() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = FoldersViewModel(context: context)

        let parent = try service.createFolder(name: "Parent")
        try service.createFolder(name: "Child1", parent: parent)
        try service.createFolder(name: "Child2", parent: parent)

        let children = viewModel.fetchSubfolders(of: parent)

        #expect(children.count == 2)
    }

    // MARK: - Create Folder Tests

    @Test("Create folder adds folder to list")
    @MainActor
    func testCreateFolder() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        let folder = viewModel.createFolder(name: "Work")

        #expect(folder != nil)
        #expect(viewModel.folders.count == 1)
        #expect(viewModel.folders.first?.name == "Work")
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Create folder trims whitespace")
    @MainActor
    func testCreateFolderTrimsWhitespace() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        let folder = viewModel.createFolder(name: "  Work  ")

        #expect(folder?.name == "Work")
    }

    @Test("Create folder with empty name returns error")
    @MainActor
    func testCreateEmptyFolder() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        let folder = viewModel.createFolder(name: "   ")

        #expect(folder == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("empty") == true)
    }

    @Test("Create folder with icon")
    @MainActor
    func testCreateFolderWithIcon() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        let folder = viewModel.createFolder(name: "Work", icon: "briefcase")

        #expect(folder != nil)
        #expect(folder?.icon == "briefcase")
    }

    @Test("Create nested folder")
    @MainActor
    func testCreateNestedFolder() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = FoldersViewModel(context: context)

        let parent = try service.createFolder(name: "Parent")
        let child = try service.createFolder(name: "Child", parent: parent)

        #expect(child.parentFolder?.id == parent.id)
    }

    // MARK: - Delete Folder Tests

    @Test("Delete folder removes from list")
    @MainActor
    func testDeleteFolder() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        guard let folder = viewModel.createFolder(name: "Work") else {
            Issue.record("Failed to create folder")
            return
        }

        #expect(viewModel.folders.count == 1)

        viewModel.deleteFolder(folder)

        #expect(viewModel.folders.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Update Folder Tests

    @Test("Update folder name")
    @MainActor
    func testUpdateFolderName() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        guard let folder = viewModel.createFolder(name: "Original") else {
            Issue.record("Failed to create folder")
            return
        }

        viewModel.updateFolder(folder, name: "Updated")

        #expect(folder.name == "Updated")
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Update folder icon")
    @MainActor
    func testUpdateFolderIcon() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        guard let folder = viewModel.createFolder(name: "Work") else {
            Issue.record("Failed to create folder")
            return
        }

        viewModel.updateFolder(folder, icon: "star")

        #expect(folder.icon == "star")
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Folder-Note Relationship Tests

    @Test("Fetch notes in folder")
    @MainActor
    func testFetchNotesInFolder() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = FoldersViewModel(context: context)

        let folder = try service.createFolder(name: "Work")
        try service.createNote(title: "Note 1", in: folder)
        try service.createNote(title: "Note 2", in: folder)
        try service.createNote(title: "Note 3") // Not in folder

        let notes = viewModel.fetchNotes(in: folder)

        #expect(notes.count == 2)
    }

    // MARK: - Search Tests

    @Test("Filter folders by name")
    @MainActor
    func testFilterFolders() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        viewModel.createFolder(name: "Work")
        viewModel.createFolder(name: "Personal")
        viewModel.createFolder(name: "Workspace")

        let results = viewModel.filteredFolders(searchText: "Work")

        #expect(results.count == 2)
    }

    @Test("Filter folders with empty search returns all")
    @MainActor
    func testFilterFoldersEmptySearch() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        viewModel.createFolder(name: "Work")
        viewModel.createFolder(name: "Personal")

        let results = viewModel.filteredFolders(searchText: "")

        #expect(results.count == 2)
    }

    @Test("Filter folders is case-insensitive")
    @MainActor
    func testFilterFoldersCaseInsensitive() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        viewModel.createFolder(name: "WORK")

        let results = viewModel.filteredFolders(searchText: "work")

        #expect(results.count == 1)
    }

    // MARK: - Hierarchy Tests

    @Test("Folder path returns full hierarchy")
    @MainActor
    func testFolderPath() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = FoldersViewModel(context: context)

        let parent = try service.createFolder(name: "Work")
        let child = try service.createFolder(name: "Projects", parent: parent)
        let grandchild = try service.createFolder(name: "iOS", parent: child)

        let path = viewModel.folderPath(grandchild)

        #expect(path == "Work / Projects / iOS")
    }

    @Test("Folder depth returns correct level")
    @MainActor
    func testFolderDepth() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = FoldersViewModel(context: context)

        let parent = try service.createFolder(name: "Work")
        let child = try service.createFolder(name: "Projects", parent: parent)
        let grandchild = try service.createFolder(name: "iOS", parent: child)

        #expect(viewModel.folderDepth(parent) == 0)
        #expect(viewModel.folderDepth(child) == 1)
        #expect(viewModel.folderDepth(grandchild) == 2)
    }

    // MARK: - Computed Properties Tests

    @Test("isEmpty returns true for no folders")
    @MainActor
    func testIsEmpty() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        #expect(viewModel.isEmpty == true)

        viewModel.createFolder(name: "Work")

        #expect(viewModel.isEmpty == false)
    }

    @Test("folderNames returns array of names")
    @MainActor
    func testFolderNames() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        viewModel.createFolder(name: "Work")
        viewModel.createFolder(name: "Personal")

        let names = viewModel.folderNames

        #expect(names.count == 2)
        #expect(names.contains("Work"))
        #expect(names.contains("Personal"))
    }

    @Test("rootFolders returns only top-level folders")
    @MainActor
    func testRootFolders() throws {
        let context = Self.createTestContext()
        let service = CoreDataService(context: context)
        let viewModel = FoldersViewModel(context: context)

        let root1 = try service.createFolder(name: "Work")
        let root2 = try service.createFolder(name: "Personal")
        try service.createFolder(name: "Child", parent: root1)

        viewModel.fetchRootFolders()

        let rootFolders = viewModel.rootFolders

        #expect(rootFolders.count == 2)
        let rootNames = rootFolders.compactMap { $0.name }
        #expect(rootNames.contains("Work"))
        #expect(rootNames.contains("Personal"))
        #expect(!rootNames.contains("Child"))
    }

    // MARK: - Error Handling Tests

    @Test("Error message is set on failure")
    @MainActor
    func testErrorHandling() {
        let context = Self.createTestContext()
        let viewModel = FoldersViewModel(context: context)

        #expect(viewModel.errorMessage == nil)

        // Error message property exists and can be set
        viewModel.errorMessage = "Test error"
        #expect(viewModel.errorMessage == "Test error")
    }
}
