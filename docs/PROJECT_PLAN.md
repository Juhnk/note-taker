# NoteTaker - Project Plan

## Project Overview

**Goal**: Create a simple, elegant note-taking app for personal use on iOS and macOS with real-time cloud sync.

**Target User**: Single user (you) who wants to stay organized across iPhone and Mac.

**Key Principle**: Maximum simplicity despite feature-rich requirements.

---

## Feature Requirements

### Must Have (MVP - Phase 1)
1. ✅ Create, edit, and delete notes
2. ✅ Rich text formatting (bold, italic, underline, headings)
3. ✅ Organize notes in folders (hierarchical structure)
4. ✅ Search notes by title and content
5. ✅ Real-time sync between iPhone and Mac via CloudKit
6. ✅ Offline-first (works without internet, syncs when available)

### Should Have (Phase 2)
7. Markdown support (write in markdown, preview formatted)
8. Color coordination for folders and notes
9. Embed images and videos
10. Insert tables
11. Tags for cross-folder organization

### Nice to Have (Phase 3)
12. Whiteboarding/canvas feature
13. Sticky notes view
14. Export notes (PDF, Markdown)
15. Import from other apps
16. Dark mode support
17. Customizable themes

---

## Technical Architecture

### Platform & Technologies

**Language**: Swift 5.9+
**UI**: SwiftUI
**Data**: SwiftData (local) + CloudKit (sync)
**Minimum OS**: iOS 17+, macOS 14+

### Why These Choices?

- **Swift/SwiftUI**: Native performance, modern APIs, single codebase for iOS/macOS
- **SwiftData**: Apple's modern data framework, simpler than Core Data
- **CloudKit**: Free, Apple-native, automatic encryption, seamless sync

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
│  Models/Data    │ ← SwiftData Models
│  (SwiftData)    │
└─────────────────┘
```

---

## Data Model

### Core Models

#### 1. Note
```swift
@Model
class Note {
    var id: UUID
    var title: String
    var content: AttributedString  // Rich text
    var createdAt: Date
    var modifiedAt: Date
    var folder: Folder?
    var tags: [Tag]
    var colorHex: String?
    var isPinned: Bool
    var attachments: [Attachment]
}
```

#### 2. Folder
```swift
@Model
class Folder {
    var id: UUID
    var name: String
    var colorHex: String?
    var icon: String?  // SF Symbol name
    var parentFolder: Folder?
    var subfolders: [Folder]
    var notes: [Note]
    var sortOrder: Int
    var createdAt: Date
}
```

#### 3. Tag
```swift
@Model
class Tag {
    var id: UUID
    var name: String
    var colorHex: String
    var notes: [Note]
}
```

#### 4. Attachment
```swift
@Model
class Attachment {
    var id: UUID
    var type: AttachmentType  // image, video, file
    var fileName: String
    var fileSize: Int64
    var cloudKitAssetURL: URL?
    var localURL: URL?
    var note: Note?
}
```

---

## User Interface Design

### iOS Layout

```
┌──────────────────────────────┐
│  ☰ Folders    Search  [+]    │  ← Navigation Bar
├──────────────────────────────┤
│  📁 Work                      │
│  📁 Personal                  │
│  📁 Ideas                     │  ← Folder List
│  ───────────────────          │
│  📝 Meeting Notes             │
│  📝 Project Ideas             │  ← Note List
│  📝 Todo List                 │
└──────────────────────────────┘
```

### macOS Layout

```
┌────────────┬──────────────────┬─────────────────────┐
│  Folders   │   Notes          │   Editor            │
│            │                  │                     │
│ 📁 Work    │ 📝 Meeting...    │ # Meeting Notes    │
│ 📁 Personal│ 📝 Project...    │                     │
│ 📁 Ideas   │ 📝 Todo List     │ - Item 1           │
│            │                  │ - Item 2           │
│            │                  │                     │
│            │                  │ **Bold text**      │
└────────────┴──────────────────┴─────────────────────┘
  Sidebar       List View          Detail View
```

---

## Development Phases

### Phase 1: Foundation (Weeks 1-4)

**Goal**: Working MVP with basic note-taking and sync

**Tasks**:
- Week 1: Xcode project setup, data models, basic UI shell
- Week 2: Note creation/editing with rich text
- Week 3: Folder organization and navigation
- Week 4: CloudKit integration and basic sync

**Deliverable**: Can create notes, organize in folders, sync between devices

---

### Phase 2: Enhanced Features (Weeks 5-8)

**Goal**: Make it polished and feature-complete for daily use

**Tasks**:
- Week 5: Search functionality, markdown support
- Week 6: Color coordination, tags
- Week 7: Image/video attachments
- Week 8: Tables, polish UI/UX

**Deliverable**: Feature-complete for personal use

---

### Phase 3: Advanced Features (Weeks 9-12)

**Goal**: Add unique features (whiteboard, sticky notes)

**Tasks**:
- Week 9: Whiteboarding with PencilKit
- Week 10: Sticky notes view
- Week 11: Export/import functionality
- Week 12: Settings, preferences, customization

**Deliverable**: Differentiated with unique features

---

### Phase 4: Polish & Distribution (Weeks 13-16)

**Goal**: App Store ready

**Tasks**:
- Week 13: Bug fixes, performance optimization
- Week 14: Accessibility (VoiceOver, Dynamic Type)
- Week 15: App Store assets, TestFlight beta
- Week 16: Final testing, submission

**Deliverable**: Published on App Store

---

## CloudKit Sync Strategy

### Architecture
- **Container**: iCloud.com.yourname.notetaker
- **Database**: Private (user's personal data)
- **Sync**: Automatic with conflict resolution

### Sync Flow
```
┌──────────┐                    ┌──────────┐
│  iPhone  │                    │   Mac    │
└────┬─────┘                    └────┬─────┘
     │                               │
     │  1. Create Note               │
     ├──────────────────────────────→│
     │  2. Upload to CloudKit        │
     │                               │
     ├─────────→ CloudKit ←──────────┤
     │                               │
     │  3. Download Changes          │
     │←──────────────────────────────┤
     │                               │
```

### Conflict Resolution
- **Strategy**: Last Write Wins (LWW)
- **Timestamp**: Use `modifiedAt` field
- **Merge**: No automatic merge, keep most recent version
- **Backup**: Keep version history (future enhancement)

---

## Key Technical Decisions

### 1. Why SwiftData over Core Data?
- Modern, declarative syntax
- Automatic CloudKit sync (coming in future iOS versions)
- Less boilerplate code
- Better SwiftUI integration

### 2. Why CloudKit over Firebase/Supabase?
- Free (up to 1GB storage, 1GB transfer/day)
- Native Apple integration
- Automatic encryption
- No backend code needed
- Works seamlessly with Apple ID

### 3. Why Not Use NSAttributedString?
- Will use `AttributedString` (Swift native)
- Better Swift integration
- Type-safe
- Works with SwiftUI Text views

### 4. Rich Text Editor Approach
- **Phase 1**: Use SwiftUI TextEditor with basic formatting toolbar
- **Phase 2**: Implement custom AttributedString editor
- **Phase 3**: Consider third-party library if needed (e.g., RichTextKit)

---

## Development Environment

### Required Tools
- macOS 14 Sonoma or later
- Xcode 15 or later
- Apple Developer account (free tier OK for development)
- iPhone running iOS 17+ (for testing)

### Testing Strategy
- **Unit Tests**: For ViewModels and business logic
- **UI Tests**: For critical user flows (create note, sync)
- **Manual Testing**: On both iOS and macOS regularly
- **Beta Testing**: TestFlight with 1-2 trusted users before launch

---

## Security & Privacy

### Data Protection
- All data encrypted by CloudKit automatically
- No analytics or tracking
- All data stays in user's iCloud
- No third-party services

### Privacy Features
- No account creation (uses Apple ID)
- No data collection
- Offline-first (works without internet)
- Export data anytime

---

## Success Metrics

Since this is a personal app, success means:

1. ✅ Use it daily for personal notes
2. ✅ Works reliably without bugs
3. ✅ Syncs perfectly between devices
4. ✅ Fast and responsive (< 100ms interactions)
5. ✅ No data loss ever
6. 🎯 Replace current note-taking solution completely

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| CloudKit sync conflicts | High | Implement robust conflict resolution |
| Data loss during sync | Critical | Implement local backup, version history |
| Performance with many notes | Medium | Implement pagination, lazy loading |
| Rich text complexity | Medium | Start simple, iterate based on needs |
| Time commitment | High | Focus on MVP first, iterate later |
| Scope creep | Medium | Strict phase boundaries, MVP focus |

---

## Future Enhancements (Post-Launch)

1. **Collaboration**: Share notes with others
2. **Version History**: See previous versions of notes
3. **Templates**: Predefined note structures
4. **Web Clipper**: Save web content to notes
5. **Siri Integration**: "Hey Siri, create a note"
6. **Widgets**: Quick access from home screen
7. **Apple Watch**: View and quick capture
8. **iPad Optimization**: Multi-window, drag & drop
9. **AI Features**: Summarization, smart search
10. **Encryption**: Additional layer beyond CloudKit

---

## Next Steps

1. ✅ Set up Xcode project (Multiplatform app)
2. ✅ Create initial data models
3. → Start building basic UI shell
4. → Implement note creation and editing
5. → Add folder organization
6. → Set up CloudKit sync

**Let's start building! 🚀**
