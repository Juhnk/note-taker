# Design System - NoteTaker

## Design Philosophy

**Maximum simplicity. Minimal and easy to navigate.**

NoteTaker follows a strict minimal design approach:
- Clean, uncluttered interface
- Focus on content, not decoration
- Respect system conventions
- Accessibility first
- No unnecessary visual elements

---

## Color Palette

### Phase 1: Monochrome Only

**Background Colors:**
- Primary Background: `Color(.systemBackground)` - White in light mode, black in dark mode
- Secondary Background: `Color(.secondarySystemBackground)` - Subtle grey
- Tertiary Background: `Color(.tertiarySystemBackground)` - Even subtler grey

**Text Colors:**
- Primary Text: `Color(.label)` - Black in light mode, white in dark mode
- Secondary Text: `Color(.secondaryLabel)` - Medium grey
- Tertiary Text: `Color(.tertiaryLabel)` - Light grey
- Quaternary Text: `Color(.quaternaryLabel)` - Very light grey

**Separator Colors:**
- Default Separator: `Color(.separator)` - Subtle divider line
- Opaque Separator: `Color(.opaqueSeparator)` - Slightly more visible

### Color Usage Rules

1. **NO custom colors** in Phase 1
2. **NO emojis** anywhere in the app
3. **NO accent colors** until Phase 2
4. Use only system-provided semantic colors (see above)
5. Colors automatically adapt to light/dark mode

### Phase 2: Selective Color Introduction

**When introduced (Month 4+), colors will be:**
- Folder colors: Optional accent for organization
- Tag colors: Optional accent for categorization
- Minimal palette: 6-8 predefined colors maximum
- Still no emojis

**Future Color Palette** (when implemented):
```swift
// Subtle, professional colors
static let folderBlue = Color(red: 0.0, green: 0.47, blue: 0.84)
static let folderGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
static let folderOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
static let folderPurple = Color(red: 0.69, green: 0.32, blue: 0.87)
static let folderRed = Color(red: 1.0, green: 0.23, blue: 0.19)
static let folderYellow = Color(red: 1.0, green: 0.80, blue: 0.0)
```

---

## Typography

### Font Hierarchy

Use system fonts exclusively. Never use custom fonts.

**Headings:**
```swift
.font(.largeTitle)      // 34pt - Main screen titles
.font(.title)           // 28pt - Section headers
.font(.title2)          // 22pt - Subsection headers
.font(.title3)          // 20pt - Card titles
```

**Body Text:**
```swift
.font(.body)            // 17pt - Default text
.font(.callout)         // 16pt - Secondary text
.font(.subheadline)     // 15pt - Supporting text
.font(.footnote)        // 13pt - Captions
.font(.caption)         // 12pt - Smallest text
```

**Special:**
```swift
.font(.headline)        // 17pt semibold - Emphasis
.font(.caption2)        // 11pt - Tiny labels
```

### Font Weights

Use semantic weights:
```swift
.fontWeight(.regular)   // Default
.fontWeight(.medium)    // Slight emphasis
.fontWeight(.semibold)  // Strong emphasis
.fontWeight(.bold)      // Maximum emphasis (use sparingly)
```

### Typography Rules

1. **Body text**: Always `.body` weight `.regular`
2. **Headings**: Use `.headline` or `.title` variants with `.semibold`
3. **Labels**: Use `.subheadline` or `.footnote`
4. **Dynamic Type**: Always support, never fix font sizes
5. **Line height**: Use default (do not customize)
6. **Letter spacing**: Use default (do not customize)

### Text Styles Example

```swift
// Note title
Text(note.title)
    .font(.title2)
    .fontWeight(.semibold)
    .foregroundColor(.primary)

// Note preview
Text(note.preview)
    .font(.body)
    .foregroundColor(.secondary)
    .lineLimit(3)

// Metadata (date, author, etc.)
Text(note.modifiedDate)
    .font(.footnote)
    .foregroundColor(.tertiary)
```

---

## Spacing

### Spacing Scale

Use consistent spacing based on 8pt grid:

```swift
// Padding scale
extension CGFloat {
    static let spacingXXS: CGFloat = 4    // Tight spacing
    static let spacingXS: CGFloat = 8     // Minimum spacing
    static let spacingS: CGFloat = 12     // Small spacing
    static let spacingM: CGFloat = 16     // Default spacing
    static let spacingL: CGFloat = 24     // Large spacing
    static let spacingXL: CGFloat = 32    // Extra large
    static let spacingXXL: CGFloat = 48   // Maximum spacing
}
```

### Spacing Rules

1. **Component padding**: Use `.spacingM` (16pt) as default
2. **Section spacing**: Use `.spacingL` (24pt) between sections
3. **List item spacing**: Use `.spacingS` (12pt) between items
4. **Screen edges**: Use `.spacingM` (16pt) from edges
5. **Dense layouts**: Use `.spacingXS` (8pt) minimum
6. **Generous layouts**: Use `.spacingXL` (32pt) for breathing room

### Spacing Examples

```swift
// Card with proper spacing
VStack(alignment: .leading, spacing: .spacingS) {
    Text(note.title)
        .font(.headline)
    Text(note.preview)
        .font(.body)
}
.padding(.spacingM)
.background(Color(.secondarySystemBackground))

// Screen with sections
VStack(spacing: .spacingL) {
    HeaderView()
    ContentView()
    FooterView()
}
.padding(.spacingM)
```

---

## Components

### Buttons

**Primary Button (rare, for main actions):**
```swift
Button(action: createNote) {
    Text("Create Note")
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.spacingM)
        .background(Color.accentColor)
        .cornerRadius(12)
}
```

**Secondary Button (most common):**
```swift
Button(action: cancel) {
    Text("Cancel")
        .font(.body)
        .foregroundColor(.primary)
}
```

**Icon Button:**
```swift
Button(action: addNote) {
    Image(systemName: "plus")
        .font(.title3)
        .foregroundColor(.primary)
}
```

### Cards

```swift
VStack(alignment: .leading, spacing: .spacingS) {
    // Content
}
.padding(.spacingM)
.background(Color(.secondarySystemBackground))
.cornerRadius(12)
.shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
```

### Lists

```swift
List {
    ForEach(notes) { note in
        NoteRow(note: note)
            .listRowSeparator(.hidden) // Optional: hide separators
    }
}
.listStyle(.plain) // Clean list style
```

### Text Fields

```swift
TextField("Note title", text: $title)
    .font(.body)
    .padding(.spacingM)
    .background(Color(.tertiarySystemBackground))
    .cornerRadius(8)
```

---

## Layout Patterns

### iOS Layouts

**Main Screen (List View):**
```
┌──────────────────────────────┐
│  [≡] Notes         [Search]  │  ← Navigation Bar (44pt)
├──────────────────────────────┤
│                              │
│  ┌────────────────────────┐ │
│  │ Note Title             │ │  ← Note Card
│  │ Preview text...        │ │
│  │ 2 hours ago            │ │
│  └────────────────────────┘ │
│                              │
│  ┌────────────────────────┐ │
│  │ Another Note           │ │
│  └────────────────────────┘ │
│                              │
└──────────────────────────────┘
```

**Editor View:**
```
┌──────────────────────────────┐
│  [<] Back        [•••] More  │  ← Navigation Bar
├──────────────────────────────┤
│  Note Title                  │  ← Title field (larger)
│  ────────────────────────    │
│                              │
│  Start typing...             │  ← Editor (full screen)
│                              │
│                              │
│                              │
├──────────────────────────────┤
│  [B] [I] [U] [•] [#] [...]  │  ← Toolbar (if visible)
└──────────────────────────────┘
```

### macOS Layouts

**Three-Column Layout:**
```
┌────────┬─────────────┬────────────────────┐
│Folders │ Notes       │ Editor             │
│        │             │                    │
│ Work   │ Note 1      │ # Note Title       │
│ Home   │ Note 2      │                    │
│ Ideas  │ Note 3      │ Content here...    │
│        │             │                    │
│        │             │                    │
│        │             │                    │
└────────┴─────────────┴────────────────────┘
 200pt     280pt         Flexible
```

**Minimum Widths:**
- Sidebar: 200pt
- List: 280pt
- Detail: 400pt

---

## Icons

### Icon System

Use SF Symbols exclusively. Never use custom icons in Phase 1.

**Common Icons:**
```swift
// Actions
Image(systemName: "plus")              // Create
Image(systemName: "pencil")            // Edit
Image(systemName: "trash")             // Delete
Image(systemName: "square.and.arrow.up") // Share
Image(systemName: "magnifyingglass")   // Search

// Navigation
Image(systemName: "chevron.left")      // Back
Image(systemName: "chevron.right")     // Forward
Image(systemName: "sidebar.left")      // Toggle sidebar

// Status
Image(systemName: "checkmark")         // Complete
Image(systemName: "xmark")             // Cancel/Close
Image(systemName: "exclamationmark.triangle") // Warning
Image(systemName: "icloud")            // Sync status

// Content
Image(systemName: "doc.text")          // Note
Image(systemName: "folder")            // Folder
Image(systemName: "tag")               // Tag
Image(systemName: "paperclip")         // Attachment
```

### Icon Sizing

```swift
// Small icons (toolbar, inline)
.font(.body)  // 17pt

// Medium icons (buttons)
.font(.title3)  // 20pt

// Large icons (empty states)
.font(.largeTitle)  // 34pt
```

### Icon Colors

Always use semantic colors:
```swift
.foregroundColor(.primary)     // Default
.foregroundColor(.secondary)   // Less important
.foregroundColor(.red)         // Destructive actions
```

---

## Dark Mode

### Automatic Support

All colors and components automatically adapt to dark mode by using system colors.

**Do:**
- Use semantic colors (`.systemBackground`, `.label`, etc.)
- Test in both light and dark mode
- Trust system defaults

**Don't:**
- Hardcode hex colors
- Create custom dark mode variants
- Override system appearance

---

## Accessibility

### Requirements

Every UI element must:
1. Have accessibility label
2. Have accessibility hint (if not obvious)
3. Support Dynamic Type
4. Have minimum 44x44pt touch target
5. Support VoiceOver
6. Support keyboard navigation (macOS)

### Implementation

```swift
Button(action: createNote) {
    Image(systemName: "plus")
}
.accessibilityLabel("Create new note")
.accessibilityHint("Double tap to create a new note")
.frame(minWidth: 44, minHeight: 44) // Touch target

Text(note.title)
    .font(.headline)
    .dynamicTypeSize(.large ... .xxxLarge) // Limit extreme sizes if needed
```

### Color Contrast

All text must meet WCAG AA standards:
- Normal text: 4.5:1 contrast ratio
- Large text: 3:1 contrast ratio

System colors handle this automatically.

---

## Animation

### Principles

1. **Purposeful**: Animate to provide feedback or guide attention
2. **Subtle**: No flashy or distracting animations
3. **Fast**: Animations should be quick (0.2-0.3s)
4. **Respect Reduce Motion**: Disable decorative animations

### Standard Animations

```swift
// Fade in/out
.transition(.opacity)

// Slide
.transition(.move(edge: .trailing))

// Scale (for modals)
.transition(.scale)

// Standard duration
.animation(.easeInOut(duration: 0.25), value: someState)

// Respect Reduce Motion
@Environment(\.accessibilityReduceMotion) var reduceMotion

if !reduceMotion {
    withAnimation {
        // Animate
    }
}
```

---

## Empty States

### Design

```swift
VStack(spacing: .spacingL) {
    Image(systemName: "doc.text")
        .font(.system(size: 64))
        .foregroundColor(.secondary)

    VStack(spacing: .spacingS) {
        Text("No Notes Yet")
            .font(.title2)
            .fontWeight(.semibold)

        Text("Create your first note to get started")
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }

    Button(action: createFirstNote) {
        Label("Create Note", systemImage: "plus")
    }
    .buttonStyle(.borderedProminent)
}
.padding(.spacingXL)
```

---

## Error States

### Design

```swift
HStack(spacing: .spacingS) {
    Image(systemName: "exclamationmark.triangle")
        .foregroundColor(.red)

    VStack(alignment: .leading, spacing: 4) {
        Text("Sync Failed")
            .font(.headline)

        Text("Changes will sync when online")
            .font(.footnote)
            .foregroundColor(.secondary)
    }
}
.padding(.spacingM)
.background(Color(.tertiarySystemBackground))
.cornerRadius(8)
```

---

## Loading States

### Design

```swift
// Inline loading
ProgressView()
    .progressViewStyle(.circular)

// Full screen loading
VStack(spacing: .spacingM) {
    ProgressView()
    Text("Loading notes...")
        .font(.footnote)
        .foregroundColor(.secondary)
}
```

---

## Platform-Specific Considerations

### iOS
- Bottom toolbar for primary actions
- Swipe gestures for delete/archive
- Pull to refresh
- Tab bar for main navigation

### macOS
- Menu bar for actions
- Keyboard shortcuts
- Toolbar items
- Three-column layout
- Window management

---

## Design Checklist

Before implementing any UI:

- [ ] Uses only system colors
- [ ] Uses only SF Symbols
- [ ] No emojis
- [ ] Follows spacing scale
- [ ] Supports Dynamic Type
- [ ] Has accessibility labels
- [ ] Tested in light and dark mode
- [ ] Respects Reduce Motion
- [ ] Minimum 44x44pt touch targets
- [ ] Consistent with existing UI
- [ ] Simple and minimal

---

## Anti-Patterns

**Don't:**
- Use gradients
- Use shadows excessively (subtle only)
- Use custom fonts
- Use emojis
- Use bright or saturated colors
- Create visual clutter
- Override system behavior
- Hardcode sizes
- Ignore accessibility
- Add unnecessary decoration

---

## Resources

- [Human Interface Guidelines - iOS](https://developer.apple.com/design/human-interface-guidelines/ios)
- [Human Interface Guidelines - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Accessibility Guidelines](https://developer.apple.com/accessibility/)

---

## Summary

NoteTaker's design is intentionally minimal:
- White, greys, black only (Phase 1)
- System fonts and colors
- SF Symbols for icons
- No emojis
- Clean, spacious layouts
- Accessibility first
- Platform-appropriate interactions

**The best design is invisible.**
