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
- Xcode 15 or later (currently using Xcode 26.1 beta)
- **Apple Developer Program** ($99/year) - **REQUIRED for CloudKit sync**
- iOS device running iOS 17+ for testing CloudKit sync

### Important: CloudKit Requires Paid Developer Account

**Current Status**: CloudKit is **configured but not active**. The project is ready for CloudKit sync but requires a paid Apple Developer Program membership to function.

**Free "Personal Team" accounts DO NOT support**:
- iCloud/CloudKit capabilities
- Push Notifications (needed for CloudKit sync)
- CloudKit container access

**What Works Now** (Free Account):
- ✅ Local Core Data storage
- ✅ Full CRUD operations
- ✅ App builds and runs
- ✅ All UI and features (except sync)

**What Requires Paid Account** ($99/year):
- ☁️ CloudKit sync between devices
- ☁️ iCloud backup
- ☁️ Remote change notifications
- 📱 App Store distribution

### Setup Instructions

**Project is already created!** Follow these steps to enable CloudKit sync:

1. **Purchase Apple Developer Program** ($99/year)
   - Go to https://developer.apple.com/programs/enroll/
   - Complete enrollment
   - This usually takes 24-48 hours to process

2. **Sign into Xcode with Paid Account**
   - Xcode → Settings → Accounts
   - Add your Apple ID (must be enrolled in Developer Program)
   - Sign out of free "Personal Team" account first

3. **Enable CloudKit in Project**
   - Open `NoteTaker.xcodeproj`
   - Edit `project.pbxproj` and uncomment these lines (around line 390):
     ```
     CODE_SIGN_ENTITLEMENTS = NoteTaker/NoteTaker.entitlements;
     ```
   - Or in Xcode UI: Signing & Capabilities → Add "iCloud" → Check "CloudKit"

4. **Build and Test**
   - Build project (should succeed now with entitlements)
   - Run on physical iOS device (CloudKit doesn't work in Simulator)
   - Sign into iCloud on device
   - CloudKit sync will start automatically

**Already Configured**:
- ✅ Core Data model with 4 entities (Note, Folder, Tag, Attachment)
- ✅ `NSPersistentCloudKitContainer` with full CloudKit configuration
- ✅ Entitlements file: `NoteTaker/NoteTaker.entitlements`
- ✅ CloudKit container ID: `iCloud.com.juhnk.NoteTaker`
- ✅ Persistent history tracking enabled
- ✅ Remote change notifications configured
- ✅ Merge policy set

### Running the App (Local-Only Mode)

Without paid account, the app works in local-only mode:

1. **Select target**
   - iOS or macOS target in Xcode

2. **Run app**
   - Press Cmd+R to build and run
   - App functions normally with local Core Data
   - Notes are saved locally, no sync

3. **Test CloudKit** (requires paid account + physical device)
   - After enabling entitlements
   - Run on physical device
   - Create notes
   - Check iCloud.com to see synced data

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

### Planning & Architecture
- **[PROJECT_PLAN.md](docs/PROJECT_PLAN.md)** - Features, timeline, technical decisions
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Technical architecture, Core Data models, patterns
- **[DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)** - UI/UX guidelines, colors, typography

### Development Process
- **[GITHUB_WORKFLOW.md](docs/GITHUB_WORKFLOW.md)** - Git workflow, commit conventions, PR process, CI/CD
- **[TESTING.md](docs/TESTING.md)** - Testing guidelines, TDD approach, coverage requirements
- **[DEVELOPMENT_CYCLES.md](docs/DEVELOPMENT_CYCLES.md)** - Small cycle management (2-3 days max)
- **[.claude/.claude.md](.claude/.claude.md)** - Development workflow for Claude Code

### Progress Tracking
- **[PROGRESS.md](PROGRESS.md)** - Main progress tracker with checkboxes for all tasks

## Progress Tracking

Development is tracked in [PROGRESS.md](PROGRESS.md) with:
- Checkbox-based task tracking
- 37 sprints across 3 phases (9 months)
- Estimated time and test coverage targets for each sprint
- Weekly progress updates
- Testing metrics

**Current Status**: See [PROGRESS.md](PROGRESS.md) Sprint 0.1

## Quality Standards

### No Code Without Tests
- Progressive coverage targets (40% → 70%)
- TDD approach (write tests first)
- Fast pre-commit hooks (~30 sec)
- CI/CD blocks untested PRs

### Development Cycles
- Maximum 2-3 days per cycle
- 1-3 features per cycle
- Each cycle includes: tests, docs, manual testing
- See [DEVELOPMENT_CYCLES.md](docs/DEVELOPMENT_CYCLES.md)

### Code Quality Gates
1. **Pre-commit hook** (local, ~30 sec) - Fast syntax and style checks
2. **CI/CD pipeline** (GitHub) - Full validation, prevents bad merges
3. **Progressive coverage** (40% → 70%) - Practical quality improvement
4. **Progress tracking** (PROGRESS.md) - Maintains visibility

### Philosophy
- **"Maximum simplicity"** - Fast commits (~30 sec), not 6-16 minutes
- **Small cycles** - Multiple commits per day without pain
- **Quality enforced** - CI/CD blocks bad merges (not local commits)

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

**No code is complete without tests.**

### Testing Requirements

- **Progressive coverage targets** (see [TESTING.md](docs/TESTING.md)):
  - Sprint 0: Disabled (empty project)
  - Sprint 1-2: 40% minimum
  - Sprint 3-5: 50% minimum
  - Sprint 6-9: 60% minimum
  - Sprint 10+: 70% minimum (final target)
- Unit tests for ViewModels and business logic (85% target)
- Integration tests for Core Data operations and sync (80% target)
- UI tests for critical user flows
- Manual testing on iOS and macOS
- Accessibility testing (VoiceOver, Dynamic Type)
- TestFlight beta before App Store release

### Test-Driven Development (TDD)

We follow TDD approach:
1. Write failing test first
2. Implement minimum code to pass
3. Refactor if needed
4. Repeat

### Pre-Commit Hooks (FAST - ~30 seconds)

Pre-commit hooks run before every commit (~30 seconds) and block commits if:
- SwiftLint fails
- Debug print statements found (with confirmation)
- Syntax errors detected

**What's NOT in pre-commit** (runs in CI/CD instead):
- Full builds (too slow: 2-5 min each)
- Full test suites (too slow: 1-3 min each)
- Coverage checks (too slow: ~2 min)

Setup: `./scripts/setup-hooks.sh`

**Philosophy**: Fast feedback loop supports "maximum simplicity" and small 2-3 day cycles

### CI/CD Pipeline (COMPREHENSIVE)

GitHub Actions run on every PR and push to main (macOS-15, Xcode 16.4):
- ✅ SwiftLint (code quality)
- ✅ Build iOS and macOS (full builds)
- ✅ Run all tests (full test suites)
- ✅ Check progressive coverage targets
- ✅ Validate commit messages
- ✅ Check documentation updates

**Cannot merge without all checks passing.**

See [TESTING.md](docs/TESTING.md) for complete testing guidelines.

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

**Current Phase**: Planning complete, testing infrastructure ready, ready to create Xcode project

**Setup Steps**:
1. Run `./scripts/setup-hooks.sh` to install pre-commit hooks and SwiftLint
2. Create Xcode project with Core Data template (Sprint 0.1)
3. Set up Core Data entities (see ARCHITECTURE.md)
4. Implement PersistenceController with CloudKit
5. Build basic UI shell
6. Implement note CRUD operations

**Testing Infrastructure**:
- ✅ PROGRESS.md - Checkbox-based progress tracking
- ✅ Fast pre-commit hooks - Quick checks (~30 sec), no builds/tests
- ✅ CI/CD pipeline - Full validation, blocks bad merges
- ✅ Progressive coverage - 40% → 70% (practical approach)
- ✅ Testing guidelines - TDD approach, see TESTING.md
- ✅ Development cycles - 2-3 day maximum cycles

**Optimized for "maximum simplicity":**
- Pre-commit: ~30 seconds (was 6-16 minutes)
- CI/CD: Full validation without slowing local development
- Progressive coverage: Practical targets that increase over time

**Key Decisions Made**:
- Using Core Data instead of SwiftData (stability)
- CloudKit for sync (free, native, automatic)
- Minimal design (white, greys, black only)
- 9-month timeline (realistic based on research)
- iOS 17+ and macOS 14+ minimum versions
- TDD approach with progressive coverage (40% → 70%)
- Fast pre-commit (~30 sec), full CI/CD validation
- Small cycles (2-3 days max) to avoid AI overload
- macOS-15 runners, Xcode 16.4 (current as of Nov 2024-2025)

See [PROJECT_PLAN.md](docs/PROJECT_PLAN.md) for complete roadmap and decisions.
See [PROGRESS.md](PROGRESS.md) for current sprint and tasks.
