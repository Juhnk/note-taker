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
    @State private var searchText = ""

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
        .onAppear {
            loadNotes()
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
                        isSelected: selectedNote?.id == note.id,
                        action: { selectedNote = note }
                    )
                }
            }
        }
    }

    private var allNotesSection: some View {
        VStack(spacing: 0) {
            SidebarSectionHeader(title: "All Notes", icon: "doc.text")

            ForEach(filteredNotes) { note in
                SidebarNoteRow(
                    note: note,
                    isSelected: selectedNote?.id == note.id,
                    action: { selectedNote = note }
                )
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
        if searchText.isEmpty {
            return notes
        }
        return notes.filter { note in
            let titleMatch = note.title?.localizedCaseInsensitiveContains(searchText) ?? false
            let contentMatch = note.contentData
                .flatMap { String(data: $0, encoding: .utf8) }?
                .localizedCaseInsensitiveContains(searchText) ?? false
            return titleMatch || contentMatch
        }
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
}

// MARK: - Sidebar Section Header

struct SidebarSectionHeader: View {
    let title: String
    let icon: String
    @State private var isExpanded = true

    var body: some View {
        Button(action: { isExpanded.toggle() }) {
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
