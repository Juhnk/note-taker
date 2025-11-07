//
//  SidebarView.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI
import CoreData

/// Notion-inspired sidebar with hierarchical navigation
/// Fixed width of 224px following Notion's design system
struct SidebarView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var service: CoreDataService
    @State private var notes: [Note] = []
    @State private var tags: [Tag] = []
    @State private var folders: [Folder] = []
    @State private var searchText = ""
    @State private var selectedTag: Tag?
    @State private var selectedFolder: Folder?
    @State private var showFolderDialog = false

    @Binding var selectedNote: Note?

    init(selectedNote: Binding<Note?>) {
        self._selectedNote = selectedNote
        self._service = State(initialValue: CoreDataService())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar
                .padding(.horizontal, .spacingM)
                .padding(.vertical, .spacingS)

            Divider()

            // Navigation sections
            ScrollView {
                VStack(spacing: .spacingXS) {
                    // Favorites section
                    favoritesSection

                    // Folders section
                    foldersSection

                    // Tags section
                    tagsSection

                    // All notes section
                    allNotesSection
                }
                .padding(.vertical, .spacingS)
            }

            Spacer()

            Divider()

            // New note button at bottom
            newNoteButton
                .padding(.spacingM)
        }
        .frame(width: 224) // Notion's sidebar width
        .background(Color(nsColor: .controlBackgroundColor))
        .sheet(isPresented: $showFolderDialog) {
            FolderDialog(parent: nil) { name, icon in
                createFolder(name: name, icon: icon)
            }
        }
        .onAppear {
            loadNotes()
            loadTags()
            loadFolders()
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: .spacingS) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 14))

            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, .spacingS)
        .padding(.vertical, 6)
        .background(.background.secondary)
        .cornerRadius(6)
    }

    private var favoritesSection: some View {
        VStack(spacing: 0) {
            if !favoriteNotes.isEmpty {
                SidebarSectionHeader(title: "Favorites", icon: "star.fill")

                ForEach(favoriteNotes) { note in
                    SidebarNoteRow(
                        note: note,
                        isSelected: selectedNote?.id == note.id
                    ) {
                        selectedNote = note
                    }
                }
            }
        }
    }

    private var foldersSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: .spacingS) {
                SidebarSectionHeader(title: "Folders", icon: "folder")
                Spacer()
                Button {
                    showFolderDialog = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, .spacingM)
            }

            if !folders.isEmpty {
                ForEach(folders) { folder in
                    SidebarFolderRow(
                        folder: folder,
                        isSelected: selectedFolder?.id == folder.id
                    ) {
                        toggleFolderFilter(folder)
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteFolder(folder)
                        }
                    }
                }
            }
        }
    }

    private var tagsSection: some View {
        VStack(spacing: 0) {
            if !tags.isEmpty {
                SidebarSectionHeader(title: "Tags", icon: "tag")

                ForEach(tags) { tag in
                    SidebarTagRow(
                        tag: tag,
                        isSelected: selectedTag?.id == tag.id
                    ) {
                        toggleTagFilter(tag)
                    }
                }
            }
        }
    }

    private var allNotesSection: some View {
        VStack(spacing: 0) {
            SidebarSectionHeader(
                title: selectedTag == nil ? "All Notes" : "Filtered Notes",
                icon: "doc.text"
            )

            ForEach(filteredNotes) { note in
                SidebarNoteRow(
                    note: note,
                    isSelected: selectedNote?.id == note.id
                ) {
                    selectedNote = note
                }
            }
        }
    }

    private var newNoteButton: some View {
        Button(action: createNote) {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 14))
                Text("New Note")
                    .font(.system(size: 13))
                Spacer()
            }
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, .spacingS)
        .padding(.vertical, 6)
        .background(.background.secondary)
        .cornerRadius(6)
    }

    // MARK: - Computed Properties

    private var favoriteNotes: [Note] {
        notes.filter { $0.isPinned }
    }

    private var filteredNotes: [Note] {
        var result = notes

        // Filter by selected folder
        if let selectedFolder = selectedFolder {
            result = result.filter { note in
                note.folder?.id == selectedFolder.id
            }
        }

        // Filter by selected tag
        if let selectedTag = selectedTag {
            result = result.filter { note in
                guard let noteTags = note.tags as? Set<Tag> else { return false }
                return noteTags.contains(selectedTag)
            }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { note in
                let titleMatch = note.title?.localizedCaseInsensitiveContains(searchText) ?? false
                let contentMatch = note.contentData
                    .flatMap { String(data: $0, encoding: .utf8) }?
                    .localizedCaseInsensitiveContains(searchText) ?? false
                return titleMatch || contentMatch
            }
        }

        return result
    }

    // MARK: - Actions

    private func loadNotes() {
        do {
            notes = try service.fetchNotes()
        } catch {
            print("Failed to load notes: \(error)")
        }
    }

    private func createNote() {
        do {
            let newNote = try service.createNote(title: "Untitled")
            selectedNote = newNote
            loadNotes()
        } catch {
            print("Failed to create note: \(error)")
        }
    }

    private func loadTags() {
        do {
            tags = try service.fetchTags()
        } catch {
            print("Failed to load tags: \(error)")
        }
    }

    private func toggleTagFilter(_ tag: Tag) {
        if selectedTag?.id == tag.id {
            // Deselect if already selected
            selectedTag = nil
        } else {
            // Select new tag
            selectedTag = tag
            // Clear folder filter when selecting tag
            selectedFolder = nil
        }
    }

    private func loadFolders() {
        do {
            folders = try service.fetchFolders(under: nil) // Load root folders
        } catch {
            print("Failed to load folders: \(error)")
        }
    }

    private func createFolder(name: String, icon: String?) {
        do {
            let newFolder = try service.createFolder(name: name, parent: nil, icon: icon)
            loadFolders()
            selectedFolder = newFolder
        } catch {
            print("Failed to create folder: \(error)")
        }
    }

    private func deleteFolder(_ folder: Folder) {
        do {
            try service.deleteFolder(folder)
            if selectedFolder?.id == folder.id {
                selectedFolder = nil
            }
            loadFolders()
        } catch {
            print("Failed to delete folder: \(error)")
        }
    }

    private func toggleFolderFilter(_ folder: Folder) {
        if selectedFolder?.id == folder.id {
            // Deselect if already selected
            selectedFolder = nil
        } else {
            // Select new folder
            selectedFolder = folder
            // Clear tag filter when selecting folder
            selectedTag = nil
        }
    }
}

// MARK: - Sidebar Section Header

struct SidebarSectionHeader: View {
    let title: String
    let icon: String
    @State private var isExpanded = true

    var body: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: .spacingS) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)

                Spacer()
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sidebar Note Row

struct SidebarNoteRow: View {
    let note: Note
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingS) {
                Image(systemName: "doc.text")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, alignment: .center)

                Text(note.title ?? "Untitled")
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()

                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sidebar Folder Row

struct SidebarFolderRow: View {
    let folder: Folder
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingS) {
                Image(systemName: folder.icon ?? "folder")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, alignment: .center)

                Text(folder.name ?? "Untitled")
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show notes in \(folder.name ?? "folder")")
    }
}

// MARK: - Sidebar Tag Row

struct SidebarTagRow: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingS) {
                Image(systemName: "tag")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, alignment: .center)

                Text(tag.name ?? "Unknown")
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(tag.name ?? "tag")")
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let service = CoreDataService(context: context)

    // Create sample notes
    try? service.createNote(title: "Meeting Notes", isPinned: true)
    try? service.createNote(title: "Ideas for App")
    try? service.createNote(title: "Shopping List")
    try? service.createNote(title: "Project Timeline", isPinned: true)

    return SidebarView(selectedNote: .constant(nil))
        .environment(\.managedObjectContext, context)
        .frame(height: 600)
}
