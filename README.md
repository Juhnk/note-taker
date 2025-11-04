# NoteTaker - Modern Note-Taking App

A simple, elegant note-taking application built with Swift and SwiftUI for iOS and macOS.

## Overview

NoteTaker is designed with maximum simplicity in mind:
- Rich text editing with formatting support
- Hierarchical folder organization
- Real-time cloud sync via CloudKit
- Search functionality
- Minimal, clean design
- Privacy-first approach

**Philosophy**: Build a reliable foundation first, add features incrementally.

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Platforms**: iOS 17+, macOS 14+
- **Data**: Core Data with NSPersistentCloudKitContainer
- **Sync**: CloudKit (private database)
- **Design**: Minimal (white, greys, black)

### Why Core Data?

Core Data is battle-tested and production-ready:
- 15+ years of optimization and stability
- Superior performance at scale (10,000+ notes)
- Automatic CloudKit sync via NSPersistentCloudKitContainer
- All successful note apps use Core Data
- SwiftData is too immature (significant bugs in iOS 17 and iOS 18)

## Project Structure

```
NoteTaker/
├── NoteTaker.xcdatamodeld/         # Core Data model
├── Models/                         # Core Data entities
│   ├── Note+CoreDataClass.swift
│   ├── Folder+CoreDataClass.swift
│   ├── Tag+CoreDataClass.swift
│   └── Attachment+CoreDataClass.swift
├── Views/                          # SwiftUI views
│   ├── Home/                      # Main screen and note list
│   ├── Editor/                    # Note editing interface
│   ├── Components/                # Reusable UI components
│   └── Settings/                  # App settings
├── ViewModels/                     # View models and business logic
├── Services/                       # Core Data, CloudKit, search services
│   ├── PersistenceController.swift
│   ├── CoreDataService.swift
│   └── SearchService.swift
└── Utilities/                      # Helper functions and extensions
```

## Development Roadmap

**Realistic Timeline: 9 months**

### Phase 1: MVP (Months 1-3)
- [ ] Xcode project setup with Core Data
- [ ] Core Data models (Note, Folder, Tag, Attachment)
- [ ] Basic note CRUD operations
- [ ] Rich text editor with formatting toolbar
- [ ] Folder hierarchy organization
- [ ] Search functionality
- [ ] CloudKit sync via NSPersistentCloudKitContainer
- [ ] Basic image attachments

**Deliverable**: Working note-taking app with sync

### Phase 2: Enhanced Features (Months 4-6)
- [ ] Markdown preview mode
- [ ] Video attachments
- [ ] Tagging system
- [ ] Export to PDF, Markdown, plain text
- [ ] Import from other apps
- [ ] Advanced search with filters
- [ ] Color coordination (folders and tags)
- [ ] Performance optimization

**Deliverable**: Feature-complete for daily personal use

### Phase 3: Advanced Features & Polish (Months 7-9)
- [ ] Sticky notes view
- [ ] Custom keyboard shortcuts (macOS)
- [ ] Share extension (save from other apps)
- [ ] Advanced formatting options
- [ ] Performance optimization for 10,000+ notes
- [ ] Accessibility improvements
- [ ] TestFlight beta testing
- [ ] App Store preparation

**Deliverable**: App Store release

### Deferred Features (Post-Launch)
- Block-based editor (Notion-style) - No Swift libraries exist
- Editable tables - Requires months of custom work
- Whiteboarding - PencilKit not available on macOS
- Collaboration - Requires backend infrastructure
- Version history - Complex implementation

## Getting Started

### Prerequisites

- macOS 14 Sonoma or later
- Xcode 15 or later
- Apple Developer account ($99/year for App Store)
- iOS device running iOS 17+ for testing

### Setup Instructions

1. **Create Xcode project**
   - Open Xcode
   - File → New → Project
   - Choose "Multiplatform > App"
   - Product Name: `NoteTaker`
   - Organization Identifier: `com.yourname.notetaker`
   - Interface: SwiftUI
   - Language: Swift
   - Storage: **Core Data** (Important!)
   - Include Tests: Yes
   - Save in: `/Users/juhnk/repos/notes/note-taker`

2. **Enable CloudKit**
   - Select project target in Xcode
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "iCloud"
   - Check "CloudKit"
   - Create container: `iCloud.com.yourname.NoteTaker`

3. **Configure Core Data**
   - Update `PersistenceController` to use `NSPersistentCloudKitContainer`
   - Enable persistent history tracking
   - Set up merge policies
   - See `docs/ARCHITECTURE.md` for complete setup

4. **Run the app**
   - Select iOS or macOS target
   - Press Cmd+R to build and run

## Architecture

### Data Layer
- **Core Data**: Local persistence with SQLite
- **NSPersistentCloudKitContainer**: Automatic CloudKit sync
- **Entities**: Note, Folder, Tag, Attachment
- **Relationships**: Fully modeled with inverses

### UI Layer
- **SwiftUI**: Declarative UI across platforms
- **MVVM Pattern**: Clean separation of concerns
- **@Observable**: State management (iOS 17+)
- **Platform-specific**: Conditional code for iOS vs macOS

### Sync Strategy
- Automatic sync via NSPersistentCloudKitContainer
- Conflict resolution with merge policies
- Offline-first with automatic sync when online
- No manual sync code required

## Design Principles

### Phase 1 Design (Current)
1. **Minimal**: White background, subtle greys, black text
2. **No Colors**: Only system colors (no custom colors until Phase 2)
3. **No Emojis**: Clean, professional interface
4. **System Fonts**: SF Pro for iOS, SF Pro for macOS
5. **SF Symbols**: System icons only
6. **Generous Spacing**: 8pt grid system
7. **Accessibility**: VoiceOver, Dynamic Type, keyboard navigation

### Core Values
1. **Simplicity First**: Clean, minimal interface
2. **Fast & Responsive**: < 100ms for common operations
3. **Native Feel**: Platform-appropriate interactions
4. **Reliable Sync**: Never lose your notes
5. **Privacy**: All data encrypted, no tracking

## Documentation

Comprehensive documentation is available in `/docs`:

- **[PROJECT_PLAN.md](docs/PROJECT_PLAN.md)** - Features, timeline, technical decisions
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Technical architecture, Core Data models, patterns
- **[DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)** - UI/UX guidelines, colors, typography
- **[GITHUB_WORKFLOW.md](docs/GITHUB_WORKFLOW.md)** - Git workflow, commit conventions, PR process
- **[.claude.md](.claude.md)** - Development workflow for Claude Code

## Development Workflow

### Git Workflow
1. Create feature branch: `git checkout -b feature/description`
2. Make changes with conventional commits
3. Push and create Pull Request
4. Review and merge to main
5. Delete branch after merge

### Commit Convention
```
<type>(<scope>): <subject>

feat(editor): add bold formatting button
fix(sync): resolve duplicate note issue
docs: update ARCHITECTURE.md with Core Data setup
```

See [GITHUB_WORKFLOW.md](docs/GITHUB_WORKFLOW.md) for complete guidelines.

## Contributing

This is currently a personal project. The workflow and documentation are designed to support solo development with Claude Code assistance.

## Testing

- Unit tests for ViewModels and business logic
- Integration tests for Core Data operations and sync
- UI tests for critical user flows
- Manual testing on iOS and macOS
- TestFlight beta before App Store release

## Performance

Targets:
- Support 10,000+ notes without performance degradation
- Search results in < 100ms
- Sync 100 notes in < 10 seconds
- App launch in < 1 second

## Security & Privacy

- All data encrypted by CloudKit automatically
- No analytics or tracking
- No third-party services
- Private database only (user's iCloud)
- Export data anytime
- No account creation (uses Apple ID)

## License

TBD

## Contact

For questions or feedback: nick@adbox.io

---

## Project Status

**Current Phase**: Planning complete, ready to create Xcode project

**Next Steps**:
1. Create Xcode project with Core Data template
2. Set up Core Data entities (see ARCHITECTURE.md)
3. Implement PersistenceController with CloudKit
4. Build basic UI shell
5. Implement note CRUD operations

**Key Decisions Made**:
- Using Core Data instead of SwiftData (stability)
- CloudKit for sync (free, native, automatic)
- Minimal design (white, greys, black only)
- 9-month timeline (realistic based on research)
- iOS 17+ and macOS 14+ minimum versions

See [PROJECT_PLAN.md](docs/PROJECT_PLAN.md) for complete roadmap and decisions.
