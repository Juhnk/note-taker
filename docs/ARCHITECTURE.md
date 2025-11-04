# NoteTaker - Technical Architecture

## System Overview

NoteTaker is a native iOS/macOS note-taking application built with SwiftUI and backed by CloudKit for seamless synchronization.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation Layer                    │
│                          (SwiftUI)                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Home    │  │  Editor  │  │WhiteBoard│  │ Settings │   │
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
│  │   CloudKit   │  │    Search    │  │  Attachment  │      │
│  │   Service    │  │   Service    │  │   Service    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                        Data Layer                            │
│                  (SwiftData + CloudKit)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   Note   │  │  Folder  │  │   Tag    │  │Attachment│   │
│  │  Model   │  │  Model   │  │  Model   │  │  Model   │   │
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

**Guidelines**:
- Views should be dumb (no business logic)
- All state managed by ViewModels
- Reusable components in `Components/` folder
- Platform-specific adaptations using `#if os(iOS)` / `#if os(macOS)`

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

    private let cloudKitService: CloudKitService
    private let searchService: SearchService

    func createNote(title: String, in folder: Folder?) async {
        // Business logic here
    }

    func updateNote(_ note: Note) async {
        // Business logic here
    }
}
```

---

### 3. Service Layer

**Responsibility**: Handle data operations, sync, and external integrations

#### CloudKitService
```swift
actor CloudKitService {
    func save<T: CloudKitSyncable>(_ item: T) async throws
    func fetch<T: CloudKitSyncable>(type: T.Type, predicate: NSPredicate) async throws -> [T]
    func delete<T: CloudKitSyncable>(_ item: T) async throws
    func syncAll() async throws
    func resolveConflicts() async throws
}
```

#### SearchService
```swift
class SearchService {
    func search(query: String, in notes: [Note]) -> [Note]
    func searchByTag(_ tag: Tag) -> [Note]
    func recentSearches() -> [String]
}
```

#### AttachmentService
```swift
class AttachmentService {
    func upload(fileURL: URL) async throws -> Attachment
    func download(_ attachment: Attachment) async throws -> URL
    func delete(_ attachment: Attachment) async throws
}
```

---

### 4. Data Layer (Models)

**Responsibility**: Define data structures and persistence

#### Note Model
```swift
@Model
final class Note {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: AttributedString
    var createdAt: Date
    var modifiedAt: Date
    var colorHex: String?
    var isPinned: Bool = false

    // Relationships
    var folder: Folder?
    var tags: [Tag] = []
    var attachments: [Attachment] = []

    // CloudKit tracking
    var cloudKitRecordID: String?
    var lastSyncedAt: Date?
    var syncStatus: SyncStatus = .pending

    init(title: String, content: AttributedString = AttributedString()) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

enum SyncStatus: Codable {
    case pending
    case syncing
    case synced
    case conflict
    case error
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
  1. Create Note model
  2. Save to SwiftData
         ↓
CloudKitService.save(note)
         ↓
  Upload to CloudKit
         ↓
  Update sync status
         ↓
  View auto-updates (@Observable)
```

### Syncing Between Devices

```
Device A: Modify note
         ↓
CloudKitService uploads change
         ↓
    CloudKit servers
         ↓
CloudKit push notification
         ↓
Device B: CloudKitService receives
         ↓
Download updated note
         ↓
Update SwiftData
         ↓
View auto-updates
```

---

## CloudKit Schema

### Note Record
```
Type: Note
Fields:
- id: String (UUID)
- title: String
- contentData: Data (encoded AttributedString)
- createdAt: Date
- modifiedAt: Date
- colorHex: String?
- isPinned: Int (Bool)
- folderReference: Reference (to Folder)
- tagReferences: List<Reference> (to Tags)
```

### Folder Record
```
Type: Folder
Fields:
- id: String (UUID)
- name: String
- colorHex: String?
- icon: String?
- parentFolderReference: Reference (to Folder)
- sortOrder: Int
- createdAt: Date
```

### Attachment Record
```
Type: Attachment
Fields:
- id: String (UUID)
- fileName: String
- fileSize: Int
- asset: Asset (CKAsset for file data)
- type: String (AttachmentType)
- noteReference: Reference (to Note)
```

---

## Sync Strategy

### Initial Setup
1. User signs in with Apple ID
2. App checks for existing CloudKit data
3. If found, download all records
4. Populate SwiftData with synced data
5. Enable change tracking

### Real-time Sync
1. **Change Detection**: SwiftData notifications trigger sync
2. **Batching**: Group changes within 2-second window
3. **Upload**: Send batched changes to CloudKit
4. **Subscriptions**: Listen for remote changes
5. **Download**: Fetch and merge remote changes

### Conflict Resolution Algorithm
```swift
func resolveConflict(local: Note, remote: Note) -> Note {
    // Last Write Wins strategy
    if local.modifiedAt > remote.modifiedAt {
        return local
    } else {
        return remote
    }
}
```

### Offline Support
- All operations work offline
- Changes queued in `PendingSyncQueue`
- Auto-sync when network returns
- Show sync status indicator

---

## File Structure

```
NoteTaker/
├── NoteTakerApp.swift              # App entry point
├── ContentView.swift               # Root view
│
├── Models/
│   ├── Note.swift                  # Note data model
│   ├── Folder.swift                # Folder data model
│   ├── Tag.swift                   # Tag data model
│   ├── Attachment.swift            # Attachment data model
│   └── SyncStatus.swift            # Sync status enum
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
│   ├── Whiteboard/
│   │   └── WhiteboardView.swift    # Canvas for drawing
│   ├── Components/
│   │   ├── NoteCard.swift          # Note list item
│   │   ├── FolderRow.swift         # Folder list item
│   │   ├── ColorPicker.swift       # Color selection
│   │   └── SearchBar.swift         # Search component
│   └── Settings/
│       └── SettingsView.swift      # App settings
│
├── ViewModels/
│   ├── NotesViewModel.swift        # Note management
│   ├── FoldersViewModel.swift      # Folder management
│   ├── SearchViewModel.swift       # Search logic
│   └── SyncViewModel.swift         # Sync coordination
│
├── Services/
│   ├── CloudKitService.swift       # CloudKit operations
│   ├── SearchService.swift         # Search functionality
│   ├── AttachmentService.swift     # File management
│   └── PersistenceController.swift # SwiftData setup
│
├── Utilities/
│   ├── Extensions/
│   │   ├── AttributedString+Extensions.swift
│   │   ├── Color+Extensions.swift
│   │   └── Date+Extensions.swift
│   ├── Constants.swift             # App constants
│   └── CloudKitConfig.swift        # CloudKit configuration
│
└── Resources/
    ├── Assets.xcassets             # Images, colors
    └── Localizable.strings         # Translations
```

---

## Testing Strategy

### Unit Tests
- ViewModels business logic
- Services (with mocked CloudKit)
- Data model validation
- Search algorithms
- Conflict resolution logic

### Integration Tests
- SwiftData + CloudKit sync
- Offline → Online transitions
- Multi-device sync scenarios

### UI Tests
- Critical user flows:
  - Create note
  - Edit note
  - Create folder
  - Search notes
  - Sync between devices

### Performance Tests
- List view with 1000+ notes
- Search performance
- Sync time for large datasets
- Memory usage during editing

---

## Security Considerations

### Data Protection
- CloudKit automatic encryption at rest and in transit
- Keychain for sensitive local data
- No plaintext credentials stored
- Biometric authentication option (future)

### Privacy
- No analytics or crash reporting
- No third-party SDKs
- All data stays in user's iCloud
- Export data anytime

### Code Security
- Input validation on all user data
- Sanitize rich text content
- Secure file handling for attachments
- CloudKit permission checks

---

## Performance Optimizations

### Lazy Loading
```swift
// Only load visible notes
List(notes.prefix(50)) { note in
    NoteCard(note: note)
}
.onAppear {
    loadMoreNotes()
}
```

### Image Caching
- Cache downloaded attachments locally
- Use low-res thumbnails in lists
- Full-res only in detail view

### Search Indexing
- Maintain searchable index in SwiftData
- Update index on note changes
- Use Core Spotlight for system-wide search

### Batch Operations
- Batch CloudKit operations (max 400 per request)
- Debounce sync triggers
- Background processing for large syncs

---

## Error Handling

### Error Types
```swift
enum NoteTakerError: Error, LocalizedError {
    case syncFailed(underlying: Error)
    case networkUnavailable
    case cloudKitQuotaExceeded
    case attachmentTooLarge
    case invalidNoteData
    case conflictResolutionFailed

    var errorDescription: String? {
        switch self {
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .networkUnavailable:
            return "No internet connection. Changes will sync when online."
        case .cloudKitQuotaExceeded:
            return "iCloud storage full. Please free up space."
        case .attachmentTooLarge:
            return "Attachment too large. Maximum size is 25MB."
        case .invalidNoteData:
            return "Unable to load note. The data may be corrupted."
        case .conflictResolutionFailed:
            return "Unable to resolve sync conflict. Please try again."
        }
    }
}
```

### Error Recovery
1. **Automatic Retry**: Network errors retry 3 times with exponential backoff
2. **User Notification**: Show error banner with action button
3. **Offline Queue**: Queue failed operations for retry
4. **Fallback**: Save locally if CloudKit unavailable

---

## Accessibility

### Support For
- VoiceOver (screen reader)
- Dynamic Type (scalable fonts)
- Keyboard navigation
- Reduce Motion
- High Contrast
- Voice Control

### Implementation
```swift
Text(note.title)
    .accessibilityLabel("Note titled \(note.title)")
    .accessibilityHint("Double tap to open")
    .dynamicTypeSize(.large ... .xxxLarge)
```

---

## Localization

### Supported Languages (Initial)
- English (primary)

### Future
- Spanish
- French
- German
- Chinese (Simplified)

### Implementation
- All user-facing strings in `Localizable.strings`
- Use `LocalizedStringKey` for SwiftUI
- Date/time formatting respects locale

---

## Monitoring & Analytics

### NO Third-Party Analytics
- Privacy-first approach
- No user tracking
- No crash reporting services

### Internal Metrics (Local Only)
- App launch count
- Notes created count
- Sync success rate
- Performance benchmarks

Metrics stored locally, never sent anywhere.

---

## Future Architecture Enhancements

### Phase 2+
1. **Widget Extension**: Home screen widgets
2. **Share Extension**: Save content from other apps
3. **Watch Extension**: Quick note capture
4. **Background Sync**: Using BGTaskScheduler
5. **Core Spotlight**: System-wide search integration
6. **Handoff**: Continue editing across devices
7. **CloudKit Sharing**: Share notes with other users

### Considerations
- Plugin architecture for extensions
- Shared framework for common code
- Webhook support for automation
- GraphQL API (if going multi-platform beyond Apple)

---

## Conclusion

This architecture provides:
- ✅ Clean separation of concerns
- ✅ Testable components
- ✅ Scalable data layer
- ✅ Reliable sync mechanism
- ✅ Offline-first experience
- ✅ Native performance

Ready to build! 🚀
