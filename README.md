# NoteTaker - Modern Note-Taking App

A simple, elegant note-taking application built with SwiftUI for iOS and macOS.

## Overview

NoteTaker is designed with maximum simplicity in mind while providing powerful features like:
- Rich text editing with markdown support
- Hierarchical folder organization
- Color coordination
- Tables, images, and videos
- Whiteboarding and sticky notes
- Real-time cloud sync via CloudKit
- Search functionality
- Notion-like design and UX

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Platforms**: iOS 17+, macOS 14+ (Sonoma)
- **Backend**: CloudKit for sync and storage
- **Storage**: SwiftData for local persistence

## Project Structure

```
NoteTaker/
├── NoteTaker/                 # Main app target (Shared code)
│   ├── App/                  # App lifecycle and configuration
│   ├── Models/               # Data models (Note, Folder, etc.)
│   ├── Views/                # SwiftUI views
│   │   ├── Home/            # Home screen and note list
│   │   ├── Editor/          # Note editing interface
│   │   ├── Whiteboard/      # Whiteboarding feature
│   │   └── Components/      # Reusable UI components
│   ├── ViewModels/           # View models and business logic
│   ├── Services/             # CloudKit, storage, search services
│   └── Utilities/            # Helper functions and extensions
├── NoteTaker-iOS/            # iOS-specific code
├── NoteTaker-macOS/          # macOS-specific code
└── NoteTaker-Shared/         # Shared resources and assets
```

## Development Roadmap

### Phase 1: Core MVP (Weeks 1-4)
- [ ] Project setup with iOS and macOS targets
- [ ] Basic SwiftData models (Note, Folder)
- [ ] Simple note creation and editing
- [ ] Rich text editor with basic formatting
- [ ] Folder/hierarchy organization
- [ ] Search functionality
- [ ] Basic CloudKit sync

### Phase 2: Enhanced Features (Weeks 5-8)
- [ ] Markdown support
- [ ] Color coordination system
- [ ] Image and video embedding
- [ ] Table support
- [ ] Improved sync and conflict resolution
- [ ] Polish UI/UX

### Phase 3: Advanced Features (Weeks 9-12)
- [ ] Whiteboarding feature
- [ ] Sticky notes
- [ ] Advanced formatting options
- [ ] Export/import functionality
- [ ] Settings and preferences
- [ ] Performance optimization

### Phase 4: Polish & Launch (Weeks 13-16)
- [ ] Bug fixes and testing
- [ ] Accessibility improvements
- [ ] App Store preparation
- [ ] Documentation
- [ ] Beta testing

## Getting Started

### Prerequisites

- macOS 14 (Sonoma) or later
- Xcode 15 or later
- Apple Developer account (for CloudKit)
- iOS device running iOS 17+ or macOS 14+ for testing

### Setup Instructions

1. **Clone the repository**
   ```bash
   cd /Users/juhnk/repos/notes/note-taker
   ```

2. **Open Xcode and create the project**
   - Open Xcode
   - Select "Create New Project"
   - Choose "Multiplatform > App"
   - Product Name: `NoteTaker`
   - Team: Your Apple Developer team
   - Organization Identifier: `com.yourname.notetaker`
   - Interface: SwiftUI
   - Language: Swift
   - Storage: SwiftData
   - Include Tests: Yes
   - Save in: `/Users/juhnk/repos/notes/note-taker`

3. **Enable CloudKit**
   - Select project in Xcode
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "iCloud"
   - Check "CloudKit"
   - Create/select a container: `iCloud.com.yourname.notetaker`

4. **Run the app**
   - Select iOS or macOS target
   - Press Cmd+R to build and run

## Architecture

### Data Layer
- **SwiftData**: Local persistence and caching
- **CloudKit**: Cloud sync and backup
- Models include: `Note`, `Folder`, `Tag`, `Attachment`

### UI Layer
- **SwiftUI**: Declarative UI across platforms
- **MVVM Pattern**: Clean separation of concerns
- Platform-specific adaptations for iOS and macOS

### Sync Strategy
- Automatic sync on changes
- Conflict resolution with last-write-wins
- Offline-first with queue for pending changes

## Design Principles

1. **Simplicity First**: Clean, minimal interface
2. **Fast & Responsive**: Instant feedback, smooth animations
3. **Native Feel**: Platform-appropriate interactions
4. **Reliable Sync**: Never lose your notes
5. **Privacy**: All data encrypted with CloudKit

## Contributing

This is currently a personal project. Contributions may be considered in the future.

## License

TBD

## Contact

For questions or feedback: nick@adbox.io
