# NoteTaker - Project Plan

## Project Overview

**Goal**: Create a simple, elegant note-taking app for personal use on iOS and macOS with real-time cloud sync.

**Target User**: Single user who wants to stay organized across iPhone and Mac.

**Key Principle**: Maximum simplicity. Build a reliable foundation first, add features incrementally.

---

## Feature Requirements

### Must Have (MVP - Phase 1: Months 1-3)
1. Create, edit, and delete notes
2. Rich text formatting (bold, italic, underline, headings, lists)
3. Organize notes in folders (hierarchical structure)
4. Search notes by title and content
5. Real-time sync between iPhone and Mac
6. Offline-first (works without internet, syncs when available)
7. Basic image attachments

### Should Have (Phase 2: Months 4-6)
8. Markdown preview mode
9. Video attachments
10. Tags for cross-folder organization
11. Export notes (PDF, Markdown, plain text)
12. Import from other apps
13. Advanced search with filters

### Nice to Have (Phase 3: Months 7-9)
14. Sticky notes view
15. Performance optimization for 10,000+ notes
16. Advanced formatting options
17. Custom keyboard shortcuts (macOS)
18. Share extension (save from other apps)

### Deferred to Future Versions
- Block-based editor (like Notion): Extremely complex, no Swift libraries exist
- Editable tables: Requires custom implementation, months of work
- Whiteboarding: PencilKit not available on macOS, would be iOS-only
- Collaboration features: Requires backend infrastructure
- Version history: Complex conflict resolution needed

---

## Technical Architecture

### Platform & Technologies

**Language**: Swift 5.9+
**UI**: SwiftUI
**Data**: Core Data (local) + CloudKit or Supabase (sync)
**Minimum OS**: iOS 17+, macOS 14+

### Why These Choices?

**Swift/SwiftUI**
- Native performance
- Modern APIs
- Single codebase for iOS/macOS (with platform-specific views)

**Core Data (NOT SwiftData)**
- Battle-tested (15+ years of production use)
- Stable and mature
- Better CloudKit integration
- Superior performance at scale (tested with 100,000+ records)
- All successful note apps use Core Data
- SwiftData is too immature (significant bugs in iOS 17 and iOS 18)

**CloudKit or Supabase for Sync**
- CloudKit: Free, Apple-native, automatic encryption
  - Cons: Reliability concerns, opaque pricing, sync complexity
- Supabase: Open-source, predictable pricing, reliable
  - Cons: Not Apple-native, requires backend setup
- Decision: Start with CloudKit, evaluate Supabase if issues arise

### Architecture Pattern: MVVM

```
┌─────────────────┐
│     Views       │ ← SwiftUI Views (UI Layer)
│   (SwiftUI)    │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   ViewModels    │ ← Business Logic
│ (@Observable)   │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│    Services     │ ← Data Access Layer
│ (CloudKit, etc) │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Models/Data    │ ← Core Data Models
│  (Core Data)    │
└─────────────────┘
```

---

## Data Model

### Core Entities (Core Data)

#### 1. Note
```swift
@objc(Note)
public class Note: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var contentData: Data  // Encoded AttributedString
    @NSManaged public var createdAt: Date
    @NSManaged public var modifiedAt: Date
    @NSManaged public var isPinned: Bool
    @NSManaged public var folder: Folder?
    @NSManaged public var tags: NSSet?  // Set of Tag
    @NSManaged public var attachments: NSSet?  // Set of Attachment

    // CloudKit sync tracking
    @NSManaged public var cloudKitRecordID: String?
    @NSManaged public var lastSyncedAt: Date?
    @NSManaged public var syncStatus: String  // pending, syncing, synced, conflict, error
}
```

#### 2. Folder
```swift
@objc(Folder)
public class Folder: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var icon: String?  // SF Symbol name
    @NSManaged public var parentFolder: Folder?
    @NSManaged public var subfolders: NSSet?  // Set of Folder
    @NSManaged public var notes: NSSet?  // Set of Note
    @NSManaged public var sortOrder: Int16
    @NSManaged public var createdAt: Date
}
```

#### 3. Tag
```swift
@objc(Tag)
public class Tag: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var notes: NSSet?  // Set of Note
}
```

#### 4. Attachment
```swift
@objc(Attachment)
public class Attachment: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var type: String  // image, video, file
    @NSManaged public var fileName: String
    @NSManaged public var fileSize: Int64
    @NSManaged public var cloudKitAssetURL: String?
    @NSManaged public var localURL: String?
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var note: Note?
}
```

---

## User Interface Design

Design System: Minimal, clean, easy to navigate
- Colors: White background, subtle greys, black text
- No additional colors until Phase 2 (when introduced for folders/tags)
- No emojis in UI
- Typography: System fonts, clear hierarchy
- Spacing: Generous whitespace

### iOS Layout

```
┌──────────────────────────────┐
│  [Menu] Folders  Search  [+] │  ← Navigation Bar
├──────────────────────────────┤
│  Work                         │
│  Personal                     │
│  Ideas                        │  ← Folder List
│  ───────────────────          │
│  Meeting Notes                │
│  Project Ideas                │  ← Note List
│  Todo List                    │
└──────────────────────────────┘
```

### macOS Layout

```
┌────────────┬──────────────────┬─────────────────────┐
│  Folders   │   Notes          │   Editor            │
│            │                  │                     │
│  Work      │  Meeting Notes   │  Meeting Notes      │
│  Personal  │  Project Ideas   │                     │
│  Ideas     │  Todo List       │  - Item 1           │
│            │                  │  - Item 2           │
│            │                  │                     │
│            │                  │  Bold text here     │
└────────────┴──────────────────┴─────────────────────┘
  Sidebar       List View          Detail View
```

---

## Development Phases

### Phase 1: Foundation (Months 1-3)

**Goal**: Working MVP with basic note-taking and sync

**Month 1: Core Infrastructure**
- Week 1-2: Xcode project setup, Core Data stack, basic UI shell
- Week 3-4: Core Data models, basic CRUD operations

**Month 2: Rich Text & Folders**
- Week 5-6: Rich text editing (iOS 18 native or RichTextKit)
- Week 7-8: Folder organization and navigation

**Month 3: Sync & Polish**
- Week 9-10: CloudKit integration and basic sync
- Week 11-12: Search functionality, bug fixes, testing

**Deliverable**: Can create/edit notes with rich text, organize in folders, sync between devices, search notes

---

### Phase 2: Enhanced Features (Months 4-6)

**Goal**: Feature-complete for daily personal use

**Month 4: Attachments & Tags**
- Week 13-14: Image/video attachments
- Week 15-16: Tagging system

**Month 5: Advanced Features**
- Week 17-18: Markdown preview mode
- Week 19-20: Export/import functionality

**Month 6: Polish & Refinement**
- Week 21-22: Advanced search with filters
- Week 23-24: UI/UX polish, performance testing

**Deliverable**: Full-featured personal note-taking app ready for daily use

---

### Phase 3: Advanced Features (Months 7-9)

**Goal**: Differentiated features and optimization

**Month 7: Views & Organization**
- Week 25-26: Sticky notes view
- Week 27-28: Custom keyboard shortcuts (macOS)

**Month 8: Integration**
- Week 29-30: Share extension (save from Safari, etc.)
- Week 31-32: Advanced formatting options

**Month 9: Performance & Distribution**
- Week 33-34: Performance optimization for large note collections
- Week 35-36: Accessibility improvements, TestFlight beta

**Deliverable**: Polished, optimized app ready for App Store

---

## CloudKit Sync Strategy

### Architecture
- **Container**: iCloud.com.yourname.notetaker
- **Database**: Private (user's personal data)
- **Sync**: Automatic with NSPersistentCloudKitContainer

### Sync Flow
```
┌──────────┐                    ┌──────────┐
│  iPhone  │                    │   Mac    │
└────┬─────┘                    └────┬─────┘
     │                               │
     │  1. Create Note               │
     ├──────────────────────────────→│
     │  2. Core Data + CloudKit      │
     │     NSPersistentCloudKit      │
     │     Container handles sync    │
     ├─────────→ CloudKit ←──────────┤
     │                               │
     │  3. Automatic download        │
     │←──────────────────────────────┤
     │                               │
```

### Conflict Resolution
- **Strategy**: Last Write Wins (LWW) with NSPersistentCloudKitContainer
- **Timestamp**: Use `modifiedAt` field
- **Automatic**: Core Data handles most conflicts
- **Manual**: Custom resolution for complex scenarios

### Fallback: Supabase Option
If CloudKit proves unreliable:
- PostgreSQL database
- REST API or GraphQL
- Real-time subscriptions
- Row-level security
- Predictable costs

---

## Key Technical Decisions

### 1. Why Core Data over SwiftData?
**Decision: Core Data**

Reasons:
- SwiftData has significant bugs in iOS 17 and iOS 18
- Performance issues with large datasets
- Developers are abandoning SwiftData in production
- Core Data is stable, battle-tested (15+ years)
- Better CloudKit integration via NSPersistentCloudKitContainer
- All successful note apps use Core Data
- SwiftData may be viable in 2-3 years, but not today

### 2. Why CloudKit (with reservations)?
**Decision: Start with CloudKit, evaluate alternatives**

Pros:
- Free for personal use
- Native Apple integration
- Automatic encryption
- No backend code needed

Cons:
- Reliability concerns (sync failures reported)
- Opaque pricing (Apple removed documentation)
- Sync complexity for large datasets
- macOS sync slower than iOS

Mitigation:
- Design abstraction layer for easy backend swap
- Monitor sync reliability closely
- Have Supabase migration plan ready

### 3. Rich Text Editor Approach
**Decision: Native iOS 18+ or RichTextKit**

- iOS 18+/macOS 15+: Use native SwiftUI TextEditor with AttributedString
- iOS 17/macOS 14: Use RichTextKit library
- Custom toolbar for formatting buttons
- No block-based editor (too complex without libraries)

### 4. What We're NOT Building (and Why)

**Block-based Editor (Notion-style)**
- Reason: No Swift libraries exist, would take months to build from scratch
- Alternative: Rich text editor with formatting

**Editable Tables**
- Reason: SwiftUI doesn't support this well, requires custom implementation
- Alternative: Markdown tables (display only) or simple grid layouts

**Whiteboarding on macOS**
- Reason: PencilKit canvas not available on native macOS
- Alternative: iOS/iPadOS only feature, or defer entirely

---

## Development Environment

### Required Tools
- macOS 14 Sonoma or later
- Xcode 15 or later
- Apple Developer account ($99/year for App Store distribution)
- iPhone running iOS 17+ (for testing)

### Testing Strategy
- **Unit Tests**: ViewModels, business logic, Core Data operations
- **Integration Tests**: CloudKit sync, conflict resolution
- **UI Tests**: Critical user flows (create note, sync, search)
- **Manual Testing**: Both iOS and macOS regularly
- **Beta Testing**: TestFlight with trusted users before launch

---

## Security & Privacy

### Data Protection
- All data encrypted by CloudKit automatically
- No analytics or tracking
- No third-party services
- Open-source option available (Supabase)

### Privacy Features
- No account creation (uses Apple ID with CloudKit)
- No data collection
- Offline-first (works without internet)
- Export data anytime

---

## Success Metrics

Since this is a personal app, success means:

1. Use it daily for all personal notes
2. Works reliably without crashes or data loss
3. Syncs perfectly between iPhone and Mac
4. Fast and responsive (< 100ms for common operations)
5. Handles 1,000+ notes without performance issues
6. Replaces current note-taking solution completely

---

## Risks & Mitigations

| Risk | Impact | Mitigation | Status |
|------|--------|-----------|--------|
| CloudKit sync unreliable | High | Design backend abstraction, have Supabase plan ready | Monitored |
| Core Data complexity | Medium | Use tutorials, Apple docs, start simple | Accepted |
| Performance with many notes | Medium | Implement pagination, lazy loading, NSFetchedResultsController | Planned |
| Rich text complexity | Medium | Use iOS 18 native or RichTextKit, start with basics | Solved |
| Time commitment (9 months) | High | Focus on MVP first, defer advanced features | Accepted |
| Scope creep | Medium | Strict phase boundaries, document deferred features | Documented |

---

## Deferred Features (Post-Launch)

These features are deferred to future versions after initial release:

1. **Collaboration**: Share notes with other users
2. **Version History**: See previous versions of notes
3. **Templates**: Predefined note structures
4. **Web Clipper**: Browser extension to save web content
5. **Siri Integration**: Voice commands
6. **Widgets**: Home screen and lock screen widgets
7. **Apple Watch**: View and quick capture
8. **iPad Optimization**: Multi-window, drag & drop
9. **AI Features**: Summarization, smart search, auto-tagging
10. **Block-based Editor**: Notion-style blocks
11. **Advanced Tables**: Editable, database-like tables
12. **Whiteboarding**: Full canvas drawing
13. **End-to-end Encryption**: Additional layer beyond CloudKit
14. **Web Version**: Access notes from any browser

---

## Timeline Summary

**Realistic Timeline: 9 months**

- Months 1-3: MVP (basic notes, folders, sync, search)
- Months 4-6: Enhanced features (attachments, tags, export)
- Months 7-9: Advanced features and App Store launch

**Key Milestones:**
- Month 3: Start using for personal notes (MVP complete)
- Month 6: Feature-complete for daily use
- Month 9: App Store submission

---

## Next Steps

Current Status: Project planning complete, documentation updated

**Ready to Start Development:**

1. Create Xcode project with Core Data template
2. Set up Core Data stack with NSPersistentCloudKitContainer
3. Create Core Data model (.xcdatamodeld file)
4. Build basic SwiftUI views
5. Implement first CRUD operations
6. Set up version control workflow (see GITHUB_WORKFLOW.md)

Refer to:
- ARCHITECTURE.md: Technical implementation details
- GITHUB_WORKFLOW.md: Development process and Git workflow
- DESIGN_SYSTEM.md: UI/UX guidelines
- .claude.md: How to work with this project using Claude Code
