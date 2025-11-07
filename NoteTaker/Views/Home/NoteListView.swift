//
//  NoteListView.swift
//  NoteTaker
//
//  Created by Juhnk on 11/6/25.
//

import SwiftUI
import CoreData

/// List view displaying all notes or notes in a specific folder
/// Follows the Design System: clean, minimal, accessible
struct NoteListView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var service: CoreDataService
    @State private var notes: [Note] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedNote: Note?

    let folder: Folder?

    init(folder: Folder? = nil) {
        self.folder = folder
        self._service = State(initialValue: CoreDataService())
    }

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let errorMessage = errorMessage {
                errorView(message: errorMessage)
            } else if notes.isEmpty {
                emptyStateView
            } else {
                notesList
            }
        }
        .navigationTitle(folder?.name ?? "Notes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: createNote) {
                    Image(systemName: "plus")
                        .accessibilityLabel("Create new note")
                        .accessibilityHint("Double tap to create a new note")
                }
            }
        }
        .onAppear {
            loadNotes()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: .spacingM) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("Loading notes...")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading notes")
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: .spacingM) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Error Loading Notes")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacingXL)

            Button(action: loadNotes) {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.spacingXL)
    }

    private var emptyStateView: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: .spacingS) {
                Text("No Notes Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create your first note to get started")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: createNote) {
                Label("Create Note", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Create your first note")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.spacingXL)
    }

    private var notesList: some View {
        List {
            ForEach(notes) { note in
                Button {
                    selectedNote = note
                } label: {
                    NoteCard(note: note)
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: .spacingXS, leading: .spacingM, bottom: .spacingXS, trailing: .spacingM))
            }
        }
        .listStyle(.plain)
        .refreshable {
            loadNotes()
        }
        .accessibilityLabel("\(notes.count) notes")
    }

    // MARK: - Actions

    private func loadNotes() {
        isLoading = true
        errorMessage = nil

        do {
            notes = try service.fetchNotes(in: folder)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func createNote() {
        do {
            let newNote = try service.createNote(title: "Untitled", in: folder)
            selectedNote = newNote
            loadNotes()
        } catch {
            errorMessage = "Failed to create note: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview

#Preview("Empty State") {
    NavigationStack {
        NoteListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

#Preview("With Notes") {
    let context = PersistenceController.preview.container.viewContext
    let service = CoreDataService(context: context)

    // Create sample notes
    try? service.createNote(title: "Meeting Notes", content: "Discussed project timeline", isPinned: true)
    try? service.createNote(title: "Ideas", content: "New feature ideas for the app")
    try? service.createNote(title: "Shopping List", content: "Groceries needed")

    return NavigationStack {
        NoteListView()
            .environment(\.managedObjectContext, context)
    }
}
