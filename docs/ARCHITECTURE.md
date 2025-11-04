# NoteTaker - Technical Architecture

## System Overview

NoteTaker is a native iOS/macOS note-taking application built with SwiftUI, Core Data for persistence, and CloudKit for seamless synchronization.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation Layer                    │
│                          (SwiftUI)                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Home    │  │  Editor  │  │  Search  │  │ Settings │   │
│  │  View    │  │   View   │  │   View   │  │   View   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                      Business Logic Layer                    │
│                        (ViewModels)                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Notes   │  │  Folders │  │  Search  │  │   Sync   │   │
│  │ViewModel │  │ViewModel │  │ViewModel │  │ViewModel │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                       Service Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Core Data   │  │    Search    │  │  Attachment  │      │
│  │   Service    │  │   Service    │  │   Service    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                        Data Layer                            │
│           (Core Data + NSPersistentCloudKitContainer)        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   Note   │  │  Folder  │  │   Tag    │  │Attachment│   │
│  │  Entity  │  │  Entity  │  │  Entity  │  │  Entity  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                       │
                       ↓
              ┌────────────────┐
              │   CloudKit     │
              │   (Backend)    │
              └────────────────┘
```

---

## Layer Details

### 1. Presentation Layer (SwiftUI Views)

**Responsibility**: Display UI and handle user interactions

**Key Components**:
- `HomeView`: Main navigation and note list
- `EditorView`: Rich text editing interface
- `FolderView`: Folder organization
- `SearchView`: Search interface
- `SettingsView`: App preferences

**Design Guidelines**:
- Minimal design: White, subtle greys, black text
- No emojis in UI
- No colors until Phase 2
- System fonts with clear hierarchy
- Generous whitespace

**Implementation Guidelines**:
- Views should be "dumb" (no business logic)
- All state managed by ViewModels
- Reusable components in `Components/` folder
- Platform-specific adaptations using `#if os(iOS)` / `#if os(macOS)`
- Use `@FetchRequest` or `@ObservedObject` for Core Data integration

---

### 2. Business Logic Layer (ViewModels)

**Responsibility**: Handle business logic, state management, and coordinate between Views and Services

**Key Components**:
- `NotesViewModel`: Manage note CRUD operations
- `FoldersViewModel`: Manage folder hierarchy
- `SearchViewModel`: Handle search queries and results
- `SyncViewModel`: Manage sync status and conflicts

**Pattern**: MVVM with `@Observable` macro (iOS 17+)

**Example**:
```swift
@Observable
class NotesViewModel {
    var notes: [Note] = []
    var selectedNote: Note?
    var isLoading = false
    var error: Error?

    private let coreDataService: CoreDataService
    private let searchService: SearchService

    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        self.searchService = SearchService()
    }

    func createNote(title: String, in folder: Folder?) async {
        await coreDataService.createNote(title: title, folder: folder)
        await fetchNotes()
    }

    func updateNote(_ note: Note, content: Data) async {
        await coreDataService.updateNote(note, content: content)
    }

    func deleteNote(_ note: Note) async {
        await coreDataService.deleteNote(note)
        await fetchNotes()
    }

    private func fetchNotes() async {
        notes = await coreDataService.fetchNotes()
    }
}
```

---

### 3. Service Layer

**Responsibility**: Handle data operations, sync, and external integrations

#### CoreDataService
```swift
@MainActor
class CoreDataService {
    private let persistenceController: PersistenceController

    var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func createNote(title: String, folder: Folder?) async throws -> Note {
        let note = Note(context: viewContext)
        note.id = UUID()
        note.title = title
        note.createdAt = Date()
        note.modifiedAt = Date()
        note.folder = folder

        try viewContext.save()
        return note
    }

    func fetchNotes(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> [Note] {
        let request = Note.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        return (try? viewContext.fetch(request)) ?? []
    }

    func updateNote(_ note: Note, content: Data) async throws {
        note.contentData = content
        note.modifiedAt = Date()
        try viewContext.save()
    }

    func deleteNote(_ note: Note) async throws {
        viewContext.delete(note)
        try viewContext.save()
    }
}
```

#### SearchService
```swift
class SearchService {
    func search(query: String, in context: NSManagedObjectContext) -> [Note] {
        let request = Note.fetchRequest()
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR contentData CONTAINS[cd] %@", query, query)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }

    func searchByTag(_ tag: Tag, in context: NSManagedObjectContext) -> [Note] {
        let request = Note.fetchRequest()
        request.predicate = NSPredicate(format: "ANY tags == %@", tag)

        return (try? context.fetch(request)) ?? []
    }
}
```

#### AttachmentService
```swift
class AttachmentService {
    private let coreDataService: CoreDataService

    func upload(fileURL: URL, for note: Note) async throws -> Attachment {
        let attachment = Attachment(context: coreDataService.viewContext)
        attachment.id = UUID()
        attachment.fileName = fileURL.lastPathComponent
        attachment.fileSize = try fileURL.fileSize()
        attachment.type = fileURL.attachmentType
        attachment.note = note

        // Copy to app's document directory
        let localURL = try await copyToLocalStorage(fileURL)
        attachment.localURL = localURL.absoluteString

        try coreDataService.viewContext.save()

        // CloudKit will sync automatically via NSPersistentCloudKitContainer
        return attachment
    }

    func delete(_ attachment: Attachment) async throws {
        if let localURLString = attachment.localURL,
           let localURL = URL(string: localURLString) {
            try? FileManager.default.removeItem(at: localURL)
        }

        coreDataService.viewContext.delete(attachment)
        try coreDataService.viewContext.save()
    }

    private func copyToLocalStorage(_ url: URL) async throws -> URL {
        // Implementation here
        return url
    }
}
```

---

### 4. Data Layer (Core Data Models)

**Responsibility**: Define data structures and persistence

#### Core Data Schema

The Core Data model is defined in `NoteTaker.xcdatamodeld` with the following entities:

#### Note Entity
```
Entity Name: Note
Class: Note (NSManagedObject)

Attributes:
- id: UUID (required, indexed)
- title: String (required)
- contentData: Binary Data (stores encoded AttributedString)
- createdAt: Date (required)
- modifiedAt: Date (required, indexed for sorting)
- isPinned: Boolean (default: false)
- cloudKitRecordID: String (optional, for tracking)
- lastSyncedAt: Date (optional)
- syncStatus: String (optional: pending, syncing, synced, conflict, error)

Relationships:
- folder: To-One to Folder (optional, cascade: nullify)
- tags: To-Many to Tag (optional)
- attachments: To-Many to Attachment (optional, cascade: delete)

Fetched Properties:
- recentNotes: modifiedAt > 7 days ago
- pinnedNotes: isPinned == true
```

#### Folder Entity
```
Entity Name: Folder
Class: Folder (NSManagedObject)

Attributes:
- id: UUID (required, indexed)
- name: String (required)
- icon: String (optional, SF Symbol name)
- sortOrder: Integer 16 (default: 0)
- createdAt: Date (required)

Relationships:
- parentFolder: To-One to Folder (optional, cascade: nullify)
- subfolders: To-Many to Folder (optional, inverse: parentFolder)
- notes: To-Many to Note (optional, inverse: folder, cascade: nullify)
```

#### Tag Entity
```
Entity Name: Tag
Class: Tag (NSManagedObject)

Attributes:
- id: UUID (required, indexed)
- name: String (required, unique)

Relationships:
- notes: To-Many to Note (optional, inverse: tags)
```

#### Attachment Entity
```
Entity Name: Attachment
Class: Attachment (NSManagedObject)

Attributes:
- id: UUID (required, indexed)
- type: String (required: image, video, file)
- fileName: String (required)
- fileSize: Integer 64
- cloudKitAssetURL: String (optional, CKAsset reference)
- localURL: String (optional, local file path)
- thumbnailData: Binary Data (optional, for preview)

Relationships:
- note: To-One to Note (optional, inverse: attachments, cascade: nullify)
```

#### Generated NSManagedObject Subclasses

```swift
// Note+CoreDataClass.swift
@objc(Note)
public class Note: NSManagedObject {
    // Core Data will generate properties
}

// Note+CoreDataProperties.swift
extension Note {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var contentData: Data
    @NSManaged public var createdAt: Date
    @NSManaged public var modifiedAt: Date
    @NSManaged public var isPinned: Bool
    @NSManaged public var cloudKitRecordID: String?
    @NSManaged public var lastSyncedAt: Date?
    @NSManaged public var syncStatus: String?
    @NSManaged public var folder: Folder?
    @NSManaged public var tags: NSSet?
    @NSManaged public var attachments: NSSet?
}

// MARK: - Convenience
extension Note {
    public var wrappedTitle: String {
        title ?? "Untitled"
    }

    public var tagsArray: [Tag] {
        let set = tags as? Set<Tag> ?? []
        return set.sorted { $0.name < $1.name }
    }

    public var attachmentsArray: [Attachment] {
        let set = attachments as? Set<Attachment> ?? []
        return set.sorted { $0.fileName < $1.fileName }
    }

    // Decode AttributedString from contentData
    public var attributedContent: AttributedString {
        get {
            guard let data = contentData,
                  let attributed = try? NSKeyedUnarchiver.unarchivedObject(
                    ofClass: NSAttributedString.self,
                    from: data
                  ) else {
                return AttributedString()
            }
            return AttributedString(attributed)
        }
        set {
            let nsAttributed = NSAttributedString(newValue)
            contentData = try? NSKeyedArchiver.archivedData(
                withRootObject: nsAttributed,
                requiringSecureCoding: true
            )
        }
    }
}
```

---

## Data Flow

### Creating a Note

```
User Action (Tap '+' button)
         ↓
   EditorView calls
         ↓
NotesViewModel.createNote()
         ↓
CoreDataService.createNote()
         ↓
  1. Create Note entity in NSManagedObjectContext
  2. Set properties
  3. Save context
         ↓
NSPersistentCloudKitContainer
  automatically syncs to CloudKit
         ↓
  View auto-updates via @FetchRequest
  or ViewModel refresh
```

### Syncing Between Devices

```
Device A: Modify note
         ↓
Core Data saves to viewContext
         ↓
NSPersistentCloudKitContainer
  detects change, uploads to CloudKit
         ↓
    CloudKit servers
         ↓
CloudKit push notification to Device B
         ↓
NSPersistentCloudKitContainer
  downloads change on Device B
         ↓
Core Data updates local store
         ↓
@FetchRequest detects change
         ↓
View auto-updates
```

**Key Advantage**: NSPersistentCloudKitContainer handles all sync logic automatically. We just save to Core Data and CloudKit sync happens behind the scenes.

---

## Persistence Setup

### PersistenceController

```swift
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "NoteTaker")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        // Configure CloudKit sync
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }

        // Enable persistent history tracking for CloudKit
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // CloudKit container options
        let cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.yourname.NoteTaker")
        description.cloudKitContainerOptions = cloudKitContainerOptions

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Handle error appropriately
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // Automatically merge changes from parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Set up notifications for remote changes
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { _ in
            // Handle remote changes if needed
        }
    }

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample data for preview
        let folder = Folder(context: viewContext)
        folder.id = UUID()
        folder.name = "Work"
        folder.createdAt = Date()

        let note = Note(context: viewContext)
        note.id = UUID()
        note.title = "Sample Note"
        note.createdAt = Date()
        note.modifiedAt = Date()
        note.folder = folder

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()
}
```

---

## CloudKit Integration

### Automatic Sync with NSPersistentCloudKitContainer

NSPersistentCloudKitContainer provides automatic CloudKit sync with zero additional code. It:

1. Automatically exports local changes to CloudKit
2. Imports remote changes from CloudKit
3. Resolves conflicts using merge policies
4. Handles network availability
5. Batches changes efficiently

### CloudKit Container Setup

1. In Xcode, select project target
2. Go to "Signing & Capabilities"
3. Add "iCloud" capability
4. Check "CloudKit"
5. Create/select container: `iCloud.com.yourname.NoteTaker`
6. Ensure container identifier matches PersistenceController

### CloudKit Schema

NSPersistentCloudKitContainer automatically:
- Creates CloudKit record types from Core Data entities
- Maps attributes to CloudKit fields
- Creates references for relationships
- Handles CKAssets for Binary Data

**Generated CloudKit Schema**:
- `CD_Note` record type
- `CD_Folder` record type
- `CD_Tag` record type
- `CD_Attachment` record type

### Conflict Resolution

Configure merge policy in PersistenceController:

```swift
container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
```

Options:
- `NSMergeByPropertyObjectTrumpMergePolicy`: Local changes win (default)
- `NSMergeByPropertyStoreTrumpMergePolicy`: Remote changes win
- `NSOverwriteMergePolicy`: Last write wins
- Custom policy for advanced scenarios

---

## File Structure

```
NoteTaker/
├── NoteTakerApp.swift              # App entry point with @main
├── ContentView.swift               # Root view
│
├── NoteTaker.xcdatamodeld/         # Core Data model
│   └── NoteTaker.xcdatamodel       # Entity definitions
│
├── Models/
│   ├── Note+CoreDataClass.swift            # Note entity
│   ├── Note+CoreDataProperties.swift       # Generated properties
│   ├── Folder+CoreDataClass.swift          # Folder entity
│   ├── Folder+CoreDataProperties.swift     # Generated properties
│   ├── Tag+CoreDataClass.swift             # Tag entity
│   ├── Tag+CoreDataProperties.swift        # Generated properties
│   ├── Attachment+CoreDataClass.swift      # Attachment entity
│   ├── Attachment+CoreDataProperties.swift # Generated properties
│   └── SyncStatus.swift                    # Sync status enum
│
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift          # Main screen
│   │   ├── NoteListView.swift     # List of notes
│   │   └── FolderSidebarView.swift # Folder navigation
│   ├── Editor/
│   │   ├── EditorView.swift        # Note editor
│   │   ├── FormattingToolbar.swift # Rich text toolbar
│   │   └── MarkdownPreview.swift   # Markdown preview
│   ├── Components/
│   │   ├── NoteCard.swift          # Note list item
│   │   ├── FolderRow.swift         # Folder list item
│   │   └── SearchBar.swift         # Search component
│   └── Settings/
│       └── SettingsView.swift      # App settings
│
├── ViewModels/
│   ├── NotesViewModel.swift        # Note management
│   ├── FoldersViewModel.swift      # Folder management
│   ├── SearchViewModel.swift       # Search logic
│   └── SyncViewModel.swift         # Sync status monitoring
│
├── Services/
│   ├── PersistenceController.swift # Core Data + CloudKit setup
│   ├── CoreDataService.swift       # Core Data operations
│   ├── SearchService.swift         # Search functionality
│   └── AttachmentService.swift     # File management
│
├── Utilities/
│   ├── Extensions/
│   │   ├── AttributedString+Extensions.swift
│   │   ├── Color+Extensions.swift
│   │   ├── Date+Extensions.swift
│   │   └── URL+Extensions.swift
│   ├── Constants.swift             # App constants
│   └── CloudKitConfig.swift        # CloudKit configuration
│
└── Resources/
    ├── Assets.xcassets             # Images, colors (minimal)
    └── Localizable.strings         # Translations
```

---

## Testing Strategy

### Unit Tests
- ViewModels business logic
- Core Data CRUD operations (using in-memory store)
- Search algorithms
- Data transformations (AttributedString encoding/decoding)

### Integration Tests
- Core Data + CloudKit sync
- Offline to online transitions
- Multi-device sync scenarios
- Conflict resolution

### UI Tests
- Critical user flows:
  - Create note
  - Edit note with rich text
  - Create folder hierarchy
  - Search notes
  - Verify sync status

### Performance Tests
- NSFetchedResultsController with 1000+ notes
- Search performance with large dataset
- Sync time for 100+ notes
- Memory usage during editing with images

---

## Security Considerations

### Data Protection
- CloudKit automatic encryption at rest and in transit
- Keychain for sensitive local data (if any)
- No plaintext credentials
- File system encryption via iOS/macOS

### Privacy
- No analytics or crash reporting
- No third-party SDKs
- All data stays in user's iCloud private database
- Export data anytime (to JSON, Markdown, PDF)

### Code Security
- Input validation on user data
- Sanitize rich text content to prevent injection
- Secure file handling for attachments
- CloudKit permission checks (private database only)

---

## Performance Optimizations

### NSFetchedResultsController

Use for efficient list views:

```swift
class NotesViewModel: NSObject, ObservableObject {
    @Published var notes: [Note] = []

    private var fetchedResultsController: NSFetchedResultsController<Note>?

    func setupFetchedResultsController(context: NSManagedObjectContext) {
        let request = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)]
        request.fetchBatchSize = 20

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: "NotesCache"
        )

        fetchedResultsController?.delegate = self

        try? fetchedResultsController?.performFetch()
        notes = fetchedResultsController?.fetchedObjects ?? []
    }
}

extension NotesViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        notes = controller.fetchedObjects as? [Note] ?? []
    }
}
```

### Image Caching
- Store thumbnails as Binary Data in Core Data
- Full images in app's documents directory
- CloudKit handles CKAsset caching

### Search Indexing
- Use Core Data predicates for search
- Index frequently searched attributes
- Consider Core Spotlight integration for system-wide search

### Batch Operations
- CloudKit batching handled automatically by NSPersistentCloudKitContainer
- Use batch Core Data operations for bulk updates

---

## Error Handling

### Error Types
```swift
enum NoteTakerError: Error, LocalizedError {
    case coreDataSaveFailed(Error)
    case syncFailed(Error)
    case networkUnavailable
    case cloudKitQuotaExceeded
    case attachmentTooLarge
    case invalidNoteData
    case conflictResolutionFailed

    var errorDescription: String? {
        switch self {
        case .coreDataSaveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .networkUnavailable:
            return "No internet connection. Changes will sync when online."
        case .cloudKitQuotaExceeded:
            return "iCloud storage full. Please free up space."
        case .attachmentTooLarge:
            return "Attachment too large. Maximum size is 250MB."
        case .invalidNoteData:
            return "Unable to load note. The data may be corrupted."
        case .conflictResolutionFailed:
            return "Unable to resolve sync conflict."
        }
    }
}
```

### Error Recovery
1. **Automatic Retry**: Network errors handled by NSPersistentCloudKitContainer
2. **User Notification**: Show error banner with clear message
3. **Offline Queue**: Changes saved locally, synced when online
4. **Fallback**: All operations work offline

---

## Accessibility

### Support For
- VoiceOver (screen reader)
- Dynamic Type (scalable fonts)
- Keyboard navigation (especially macOS)
- Reduce Motion
- High Contrast
- Voice Control

### Implementation
```swift
Text(note.title)
    .accessibilityLabel("Note titled \(note.wrappedTitle)")
    .accessibilityHint("Double tap to open note")
    .accessibilityAddTraits(.isButton)

Button(action: createNote) {
    Image(systemName: "plus")
}
.accessibilityLabel("Create new note")
```

---

## Localization

### Supported Languages (Initial)
- English (primary)

### Future
- Spanish, French, German, Chinese (Simplified)

### Implementation
- All user-facing strings in `Localizable.strings`
- Use `LocalizedStringKey` in SwiftUI
- Date/time formatting respects locale
- Core Data attributes support localization

---

## Monitoring

### NO Third-Party Analytics
- Privacy-first approach
- No user tracking
- No crash reporting services

### Internal Metrics (Local Only)
- App launch count
- Notes created count
- Sync events logged locally
- Performance benchmarks

All metrics stored locally in UserDefaults, never sent anywhere.

---

## Future Architecture Enhancements

### Phase 2+
1. **Widget Extension**: Home screen/lock screen widgets
2. **Share Extension**: Save content from Safari, other apps
3. **Core Spotlight**: System-wide search integration
4. **Handoff**: Continue editing across devices
5. **Shortcuts**: Siri integration
6. **CloudKit Sharing**: Share individual notes

### Considerations
- Extensions share data via App Group
- Shared Core Data store across extensions
- Background fetch for sync
- CloudKit subscriptions for real-time updates

---

## Migration Strategy

### From SwiftData (if needed)
If SwiftData matures in 2-3 years:
1. Core Data can migrate to SwiftData
2. Export data to portable format
3. Import into SwiftData models
4. Test thoroughly before release

### Version Updates
- Use Core Data lightweight migration for schema changes
- Add migration mappings for complex changes
- Test migration on large datasets

---

## Conclusion

This architecture provides:
- Clean separation of concerns
- Testable components
- Stable, proven data layer (Core Data)
- Reliable sync via NSPersistentCloudKitContainer
- Offline-first experience
- Native performance
- Production-ready foundation

Key advantage over SwiftData: Stability and maturity. Core Data has 15+ years of production use and handles large datasets reliably.

Ready to build.
