//
//  SidebarView.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

// swiftlint:disable file_length type_body_length

import SwiftUI
import CoreData

/// Notion-inspired sidebar with hierarchical navigation
/// Fixed width of 224px following Notion's design system
struct SidebarView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var service: CoreDataService
    @State private var searchService: SearchService
    @State private var notes: [Note] = []
    @State private var tags: [Tag] = []
    @State private var folders: [Folder] = []
    @State private var searchText = ""
    @State private var selectedTag: Tag?
    @State private var selectedFolder: Folder?
    @State private var showFolderDialog = false
    @State private var folderToRename: Folder?
    @State private var renameText = ""
    @State private var showRenameAlert = false
    @State private var isSearching = false

    // Search filter state
    @State private var searchStartDate: Date?
    @State private var searchEndDate: Date?
    @State private var showPinnedOnly: Bool?
    @State private var searchScope: SearchScope = .all

    // Folder expansion state
    @State private var expandedFolders: Set<UUID> = []

    @Binding var selectedNote: Note?

    init(selectedNote: Binding<Note?>) {
        self._selectedNote = selectedNote
        let context = PersistenceController.shared.container.viewContext
        self._service = State(initialValue: CoreDataService(context: context))
        self._searchService = State(initialValue: SearchService(context: context))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar
                .padding(.horizontal, .spacingM)
                .padding(.vertical, .spacingS)

            // Search filter bar (shown when searching)
            if !searchText.isEmpty {
                SearchFilterBar(
                    startDate: $searchStartDate,
                    endDate: $searchEndDate,
                    showPinnedOnly: $showPinnedOnly,
                    searchScope: $searchScope
                )
                .padding(.horizontal, .spacingM)
                .padding(.bottom, .spacingS)
            }

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
        .alert("Rename Folder", isPresented: $showRenameAlert) {
            TextField("Folder name", text: $renameText)
            Button("Cancel", role: .cancel) {
                folderToRename = nil
                renameText = ""
            }
            Button("Rename") {
                if let folder = folderToRename {
                    renameFolder(folder, newName: renameText)
                }
                folderToRename = nil
                renameText = ""
            }
        } message: {
            Text("Enter a new name for this folder")
        }
        .onAppear {
            loadNotes()
            loadTags()
            loadFolders()
            loadExpandedFoldersState()
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
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteNote(note)
                        }
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
                    folderRowWithNotes(folder)
                }
            }
        }
    }

    /// Recursively renders a folder with its subfolders and notes
    /// - Parameters:
    ///   - folder: The folder to render
    ///   - depth: The current depth level (0 for root folders)
    @ViewBuilder
    private func recursiveFolderView(_ folder: Folder, depth: Int = 0) -> some View {
        VStack(spacing: 0) {
            // Folder row with depth-based indentation
            folderRow(folder, depth: depth)

            // When expanded, show notes and subfolders
            if isExpanded(folder) {
                // Show notes in this folder
                ForEach(notesInFolder(folder)) { note in
                    noteRow(note, depth: depth + 1)
                }

                // Recursively show subfolders
                if let subfolders = folder.subfolders as? Set<Folder> {
                    ForEach(Array(subfolders).sorted(by: {
                        ($0.name ?? "") < ($1.name ?? "")
                    })) { subfolder in
                        AnyView(recursiveFolderView(subfolder, depth: depth + 1))
                    }
                }
            }
        }
    }

    /// Renders a single folder row with proper indentation
    private func folderRow(_ folder: Folder, depth: Int) -> some View {
        HStack(spacing: .spacingS) {
            // Disclosure triangle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    toggleFolderExpansion(folder)
                }
            } label: {
                Image(systemName: isExpanded(folder) ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24) // Larger hit area
            }
            .buttonStyle(.plain)

            SidebarFolderRow(
                folder: folder,
                isSelected: selectedFolder?.id == folder.id,
                noteCount: noteCount(in: folder)
            ) {
                selectedFolder = folder
            }
            .contextMenu {
                Button("Rename") {
                    startRenaming(folder)
                }
                Divider()
                Button("Delete", role: .destructive) {
                    deleteFolder(folder)
                }
            }
        }
        .padding(.leading, CGFloat(depth) * 16 + .spacingS) // 16pt per depth level
    }

    /// Renders a single note row with proper indentation
    private func noteRow(_ note: Note, depth: Int) -> some View {
        SidebarNoteRow(
            note: note,
            isSelected: selectedNote?.id == note.id
        ) {
            selectedNote = note
        }
        .padding(.leading, CGFloat(depth) * 16 + .spacingS) // 16pt per depth level
        .contextMenu {
            Button("Delete", role: .destructive) {
                deleteNote(note)
            }
        }
    }

    /// Backwards compatibility wrapper - calls recursive version
    private func folderRowWithNotes(_ folder: Folder) -> some View {
        recursiveFolderView(folder, depth: 0)
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
                title: "Unfiled Notes",
                icon: "doc.text"
            )

            ForEach(notesWithoutFolder) { note in
                SidebarNoteRow(
                    note: note,
                    isSelected: selectedNote?.id == note.id
                ) {
                    selectedNote = note
                }
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        deleteNote(note)
                    }
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
        // Use SearchService when searching with text
        if !searchText.isEmpty {
            return performSearch()
        }

        // Simple filtering when no search text
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

        return result
    }

    private var notesWithoutFolder: [Note] {
        notes.filter { $0.folder == nil && !$0.isPinned }
    }

    private func notesInFolder(_ folder: Folder) -> [Note] {
        notes.filter { $0.folder?.id == folder.id }
    }

    private func isExpanded(_ folder: Folder) -> Bool {
        guard let id = folder.id else { return false }
        return expandedFolders.contains(id)
    }

    /// Returns the count of notes directly in a folder (not including subfolders)
    private func noteCount(in folder: Folder) -> Int {
        notesInFolder(folder).count
    }

    // MARK: - Actions

    private func toggleFolderExpansion(_ folder: Folder) {
        guard let id = folder.id else { return }
        if expandedFolders.contains(id) {
            expandedFolders.remove(id)
        } else {
            expandedFolders.insert(id)
        }
        saveExpandedFoldersState()
    }

    /// Saves the expanded folders state to UserDefaults
    private func saveExpandedFoldersState() {
        let uuidStrings = expandedFolders.map { $0.uuidString }
        UserDefaults.standard.set(uuidStrings, forKey: "expandedFolders")
    }

    /// Loads the expanded folders state from UserDefaults
    private func loadExpandedFoldersState() {
        if let uuidStrings = UserDefaults.standard.stringArray(forKey: "expandedFolders") {
            expandedFolders = Set(uuidStrings.compactMap { UUID(uuidString: $0) })
        }
    }

    private func deleteNote(_ note: Note) {
        do {
            try service.deleteNote(note)
            if selectedNote?.id == note.id {
                selectedNote = nil
            }
            loadNotes()
        } catch {
            print("Failed to delete note: \(error)")
        }
    }

    private func performSearch() -> [Note] {
        isSearching = true
        defer { isSearching = false }

        do {
            // Build search filters based on current selections
            let filters = SearchFilters(
                folder: selectedFolder,
                tag: selectedTag,
                startDate: searchStartDate,
                endDate: searchEndDate,
                isPinned: showPinnedOnly
            )

            // Use appropriate search method based on scope
            switch searchScope {
            case .all:
                return try searchService.searchNotes(query: searchText, filters: filters)
            case .titleOnly:
                let results = try searchService.searchNotesByTitle(query: searchText)
                return applyAdditionalFilters(to: results, filters: filters)
            case .contentOnly:
                let results = try searchService.searchNotesByContent(query: searchText)
                return applyAdditionalFilters(to: results, filters: filters)
            case .tags:
                // Tags scope requires tag selection
                guard let tag = selectedTag else { return [] }
                return try searchService.searchNotesByTags([tag])
            }
        } catch {
            print("Search failed: \(error)")
            return []
        }
    }

    private func applyAdditionalFilters(to notes: [Note], filters: SearchFilters) -> [Note] {
        var result = notes

        // Apply folder filter
        if let folder = filters.folder {
            result = result.filter { $0.folder?.id == folder.id }
        }

        // Apply tag filter
        if let tag = filters.tag {
            result = result.filter { note in
                guard let noteTags = note.tags as? Set<Tag> else { return false }
                return noteTags.contains(tag)
            }
        }

        // Apply date range filters
        if let startDate = filters.startDate {
            result = result.filter { note in
                guard let modifiedAt = note.modifiedAt else { return false }
                return modifiedAt >= startDate
            }
        }

        if let endDate = filters.endDate {
            result = result.filter { note in
                guard let modifiedAt = note.modifiedAt else { return false }
                return modifiedAt <= endDate
            }
        }

        // Apply pinned filter
        if let isPinned = filters.isPinned {
            result = result.filter { $0.isPinned == isPinned }
        }

        return result
    }

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

    private func startRenaming(_ folder: Folder) {
        folderToRename = folder
        renameText = folder.name ?? ""
        showRenameAlert = true
    }

    private func renameFolder(_ folder: Folder, newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        do {
            try service.updateFolder(folder, name: trimmedName)
            loadFolders()
        } catch {
            print("Failed to rename folder: \(error)")
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

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingS) {
                Image(systemName: "doc.text")
                    .font(.system(size: 11)) // Smaller icon for notes
                    .foregroundStyle(.tertiary) // More subdued
                    .frame(width: 16, alignment: .center)

                Text(note.title ?? "Untitled")
                    .font(.system(size: 13)) // Regular weight (not bold)
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
            .background(
                isSelected ? Color.accentColor.opacity(0.1) :
                    isHovered ? Color.secondary.opacity(0.05) : Color.clear
            )
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Sidebar Folder Row

struct SidebarFolderRow: View {
    let folder: Folder
    let isSelected: Bool
    let noteCount: Int
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingS) {
                Image(systemName: folder.icon ?? "folder")
                    .font(.system(size: 14, weight: .semibold)) // Larger, bolder for folders
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 18, alignment: .center)

                Text(folder.name ?? "Untitled")
                    .font(.system(size: 13, weight: .semibold)) // Bold for folders
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()

                // Count badge
                if noteCount > 0 {
                    Text("\(noteCount)")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, 4)
            .background(
                isSelected ? Color.accentColor.opacity(0.1) :
                    isHovered ? Color.secondary.opacity(0.05) : Color.clear
            )
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
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
