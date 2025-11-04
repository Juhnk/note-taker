# Testing Guidelines - NoteTaker

## Testing Philosophy

**No code is complete without tests.**

Every feature must have appropriate test coverage before it's considered done. Tests are not optional; they are part of the definition of "complete."

**Minimum Coverage Targets**:
- Overall: 70%
- Core Data Models & Services: 80%
- ViewModels: 85%
- Views: 60%
- Utilities: 75%

---

## Test Types

### 1. Unit Tests

**Purpose**: Test individual components in isolation

**What to Test**:
- ViewModels logic
- Service methods
- Data transformations
- Utility functions
- Business logic

**Example**:
```swift
import XCTest
@testable import NoteTaker

final class NotesViewModelTests: XCTestCase {
    var sut: NotesViewModel!
    var mockCoreDataService: MockCoreDataService!

    override func setUp() {
        super.setUp()
        mockCoreDataService = MockCoreDataService()
        sut = NotesViewModel(coreDataService: mockCoreDataService)
    }

    override func tearDown() {
        sut = nil
        mockCoreDataService = nil
        super.tearDown()
    }

    func testCreateNote_AddsNoteToList() async {
        // Given
        XCTAssertEqual(sut.notes.count, 0)

        // When
        await sut.createNote(title: "Test Note", in: nil)

        // Then
        XCTAssertEqual(sut.notes.count, 1)
        XCTAssertEqual(sut.notes.first?.title, "Test Note")
    }

    func testDeleteNote_RemovesNoteFromList() async {
        // Given
        await sut.createNote(title: "Test Note", in: nil)
        let note = sut.notes.first!

        // When
        await sut.deleteNote(note)

        // Then
        XCTAssertEqual(sut.notes.count, 0)
    }
}
```

### 2. Integration Tests

**Purpose**: Test how components work together

**What to Test**:
- Core Data + CloudKit sync
- ViewModel + Service interaction
- Multiple services working together
- Offline to online transitions

**Example**:
```swift
import XCTest
@testable import NoteTaker

final class CoreDataCloudKitIntegrationTests: XCTestCase {
    var persistenceController: PersistenceController!

    override func setUp() {
        super.setUp()
        // Use in-memory store for testing
        persistenceController = PersistenceController(inMemory: true)
    }

    func testNoteCreation_SyncsToCloudKit() async throws {
        // Given
        let context = persistenceController.container.viewContext
        let note = Note(context: context)
        note.id = UUID()
        note.title = "Test Note"
        note.createdAt = Date()
        note.modifiedAt = Date()

        // When
        try context.save()

        // Then
        // Verify note exists in Core Data
        let fetchRequest = Note.fetchRequest()
        let notes = try context.fetch(fetchRequest)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.title, "Test Note")

        // Note: CloudKit sync happens automatically
        // In production, this would sync to CloudKit
    }
}
```

### 3. UI Tests

**Purpose**: Test user interactions and workflows

**What to Test**:
- Critical user flows (create note, edit, delete)
- Navigation between screens
- Search functionality
- Accessibility

**Example**:
```swift
import XCTest

final class NoteTakerUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testCreateNote_CreatesNewNote() {
        // Given
        let createButton = app.buttons["Create new note"]

        // When
        createButton.tap()

        // Type note title
        let titleField = app.textFields["Note title"]
        titleField.tap()
        titleField.typeText("My Test Note")

        // Then
        // Verify note appears in list
        XCTAssertTrue(app.staticTexts["My Test Note"].exists)
    }

    func testSearch_FindsNotes() {
        // Given - create a note first
        createNote(title: "Searchable Note")

        // When
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("Searchable")

        // Then
        XCTAssertTrue(app.staticTexts["Searchable Note"].exists)
    }

    // Helper method
    private func createNote(title: String) {
        app.buttons["Create new note"].tap()
        app.textFields["Note title"].tap()
        app.textFields["Note title"].typeText(title)
    }
}
```

---

## Testing Core Data

### Use In-Memory Store

**Always** use in-memory persistent store for tests:

```swift
class PersistenceController {
    static let shared = PersistenceController()

    // For testing
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Create sample data
        return controller
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "NoteTaker")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error)")
            }
        }
    }
}
```

### Testing CRUD Operations

```swift
func testCoreDataCRUD() throws {
    let controller = PersistenceController(inMemory: true)
    let context = controller.container.viewContext

    // Create
    let note = Note(context: context)
    note.id = UUID()
    note.title = "Test"
    note.createdAt = Date()
    note.modifiedAt = Date()
    try context.save()

    // Read
    let fetchRequest = Note.fetchRequest()
    let notes = try context.fetch(fetchRequest)
    XCTAssertEqual(notes.count, 1)

    // Update
    notes.first?.title = "Updated"
    try context.save()
    XCTAssertEqual(notes.first?.title, "Updated")

    // Delete
    context.delete(notes.first!)
    try context.save()
    let afterDelete = try context.fetch(fetchRequest)
    XCTAssertEqual(afterDelete.count, 0)
}
```

---

## Mocking

### Create Mock Services

```swift
class MockCoreDataService: CoreDataService {
    var notes: [Note] = []
    var createNoteCallCount = 0

    override func createNote(title: String, folder: Folder?) async throws -> Note {
        createNoteCallCount += 1
        let note = Note(context: viewContext)
        note.title = title
        notes.append(note)
        return note
    }

    override func fetchNotes(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) -> [Note] {
        return notes
    }
}
```

### Use Protocols for Testability

```swift
protocol CoreDataServiceProtocol {
    func createNote(title: String, folder: Folder?) async throws -> Note
    func fetchNotes(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) -> [Note]
    func deleteNote(_ note: Note) async throws
}

class CoreDataService: CoreDataServiceProtocol {
    // Implementation
}

// ViewModel uses protocol
class NotesViewModel {
    private let dataService: CoreDataServiceProtocol

    init(dataService: CoreDataServiceProtocol) {
        self.dataService = dataService
    }
}

// In tests, inject mock
let mock = MockCoreDataService()
let viewModel = NotesViewModel(dataService: mock)
```

---

## Test Organization

### File Structure

```
NoteTakerTests/
├── Unit/
│   ├── ViewModels/
│   │   ├── NotesViewModelTests.swift
│   │   └── FoldersViewModelTests.swift
│   ├── Services/
│   │   ├── CoreDataServiceTests.swift
│   │   ├── SearchServiceTests.swift
│   │   └── AttachmentServiceTests.swift
│   └── Utilities/
│       └── ExtensionsTests.swift
├── Integration/
│   ├── CoreDataCloudKitTests.swift
│   └── ViewModelServiceTests.swift
└── Mocks/
    ├── MockCoreDataService.swift
    └── MockSearchService.swift

NoteTakerUITests/
├── NoteCreationUITests.swift
├── SearchUITests.swift
├── FolderManagementUITests.swift
└── AccessibilityUITests.swift
```

### Naming Conventions

```swift
// Unit test format: test[MethodName]_[Scenario]_[ExpectedResult]
func testCreateNote_WithValidTitle_CreatesNote()
func testCreateNote_WithEmptyTitle_ThrowsError()
func testDeleteNote_WithExistingNote_RemovesFromList()

// UI test format: test[Feature]_[Action]_[ExpectedOutcome]
func testNoteList_TapNote_OpensEditor()
func testSearch_TypeQuery_FiltersResults()
```

---

## Test Coverage

### Measuring Coverage

1. In Xcode: Product → Scheme → Edit Scheme
2. Test → Options → Check "Gather coverage for"
3. Select NoteTaker target
4. Run tests: Cmd+U
5. View coverage: Report Navigator → Coverage tab

### Coverage Targets

| Component | Target | Priority |
|-----------|--------|----------|
| Core Data Models | 80% | High |
| ViewModels | 85% | High |
| Services | 80% | High |
| Views | 60% | Medium |
| Utilities | 75% | Medium |
| UI Tests | Critical flows only | Medium |

### What NOT to Test

- SwiftUI View body (test behavior, not rendering)
- Third-party libraries
- Generated Core Data properties (test usage, not properties)
- Simple getters/setters with no logic

---

## Testing Async Code

### Use async/await in tests

```swift
func testAsyncOperation() async throws {
    // Given
    let viewModel = NotesViewModel()

    // When
    await viewModel.createNote(title: "Test", in: nil)

    // Then
    XCTAssertEqual(viewModel.notes.count, 1)
}
```

### Use XCTestExpectation for older code

```swift
func testOldAsyncOperation() {
    let expectation = XCTestExpectation(description: "Note created")

    viewModel.createNote(title: "Test") { result in
        XCTAssertNotNil(result)
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5.0)
}
```

---

## Testing Accessibility

### VoiceOver Labels

```swift
func testAccessibilityLabels() {
    let app = XCUIApplication()
    app.launch()

    let createButton = app.buttons["Create new note"]
    XCTAssertTrue(createButton.exists)
    XCTAssertEqual(createButton.label, "Create new note")
}
```

### Dynamic Type

```swift
func testDynamicType() {
    let app = XCUIApplication()
    app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    app.launch()

    // Verify UI still works at largest text size
    XCTAssertTrue(app.buttons["Create new note"].exists)
}
```

---

## Performance Testing

### Measure Execution Time

```swift
func testSearchPerformance() {
    // Create 1000 test notes
    createTestNotes(count: 1000)

    measure {
        let results = searchService.search(query: "test", in: context)
        XCTAssertGreaterThan(results.count, 0)
    }

    // Baseline: < 100ms for 1000 notes
}
```

### Memory Testing

```swift
func testMemoryUsage() {
    measureMetrics([XCTMemoryMetric()]) {
        // Load large dataset
        let notes = loadNotes(count: 10000)

        // Perform operations
        for note in notes {
            _ = note.attributedContent
        }
    }
}
```

---

## Continuous Integration

### Tests Run Automatically

- Every pull request
- Every push to main
- Before every commit (pre-commit hook)

### CI/CD Requirements

- All tests must pass
- Coverage must be ≥ 70%
- SwiftLint must pass
- Build must succeed

See `.github/workflows/ci.yml` for configuration.

---

## Test-Driven Development (TDD)

### Recommended Workflow

1. **Write test first** (it will fail)
2. **Write minimum code** to make test pass
3. **Refactor** if needed
4. **Repeat**

### Example TDD Flow

```swift
// 1. Write failing test
func testCreateNote_WithTitle_CreatesNote() async {
    // This will fail because method doesn't exist yet
    await viewModel.createNote(title: "Test", in: nil)
    XCTAssertEqual(viewModel.notes.count, 1)
}

// 2. Implement minimum code
func createNote(title: String, in folder: Folder?) async {
    let note = Note()
    note.title = title
    notes.append(note)
}

// 3. Test passes! Now refactor if needed.
```

---

## Common Testing Pitfalls

### Don't

- Test implementation details
- Test third-party code
- Write tests that depend on other tests
- Use real network/database in tests
- Ignore failing tests
- Skip tests to make CI pass
- Write tests without assertions

### Do

- Test behavior, not implementation
- Use mocks for external dependencies
- Keep tests independent
- Use in-memory stores for Core Data
- Fix failing tests immediately
- Maintain high coverage
- Write meaningful assertions

---

## Testing Checklist

Before marking a feature complete:

- [ ] Unit tests written and passing
- [ ] Integration tests written (if applicable)
- [ ] UI tests written for critical flows
- [ ] Test coverage meets target (70%+)
- [ ] All tests pass locally
- [ ] Tests pass in CI/CD
- [ ] Accessibility tested with VoiceOver
- [ ] Tested on iOS simulator
- [ ] Tested on macOS
- [ ] Performance tested (if applicable)
- [ ] Memory leaks checked
- [ ] Edge cases tested

---

## Resources

- [Apple: Testing with Xcode](https://developer.apple.com/documentation/xcode/testing-with-xcode)
- [Apple: Writing Test Classes and Methods](https://developer.apple.com/documentation/xctest/xctestcase)
- [Apple: UI Testing](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [Core Data Testing](https://www.avanderlee.com/swift/core-data-testing/)
- [SwiftUI Testing](https://www.swiftbysundell.com/articles/testing-swiftui-views/)

---

## Summary

- **70% minimum coverage** for all code
- **Tests are not optional** - they're part of "done"
- **Write tests first** when possible (TDD)
- **Use mocks** for dependencies
- **In-memory store** for Core Data tests
- **CI/CD enforces** testing requirements
- **No commits without passing tests** (pre-commit hook)

Testing ensures quality and prevents regressions. It's an investment that pays off.
