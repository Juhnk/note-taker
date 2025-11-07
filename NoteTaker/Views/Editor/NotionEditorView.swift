//
//  NotionEditorView.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI
import CoreData

/// Notion-inspired editor view with inline editing and block support
/// Phase 1: Basic text editing with Notion-like UX
/// Future: Block-based architecture, slash commands, inline formatting
struct NotionEditorView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var service: CoreDataService
    @State private var title: String
    @State private var content: String
    @State private var isSaving = false
    @State private var lastSaved: Date?

    @ObservedObject var note: Note

    init(note: Note) {
        self.note = note
        self._service = State(initialValue: CoreDataService())
        self._title = State(initialValue: note.title ?? "")

        let contentString = note.contentData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        self._content = State(initialValue: contentString)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingM) {
                // Title editor - Notion-style
                titleEditor

                // Content editor - Notion-style
                contentEditor

                Spacer(minLength: 200)
            }
            .padding(.spacingXL)
            .padding(.horizontal, 120) // Notion-like centered content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack(spacing: .spacingS) {
                    // Pin button
                    Button(action: togglePin) {
                        Image(systemName: note.isPinned ? "pin.fill" : "pin")
                            .foregroundStyle(note.isPinned ? Color.accentColor : .secondary)
                    }
                    .help(note.isPinned ? "Unpin note" : "Pin note")

                    // Last saved indicator
                    if let lastSaved = lastSaved {
                        Text("Saved \(lastSaved, style: .relative)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .onChange(of: title) { _, newValue in
            saveNote()
        }
        .onChange(of: content) { _, newValue in
            saveNote()
        }
    }

    // MARK: - Subviews

    private var titleEditor: some View {
        TextField("Untitled", text: $title, axis: .vertical)
            .font(.system(size: 40, weight: .bold))
            .textFieldStyle(.plain)
            .lineLimit(3)
            .accessibilityLabel("Note title")
            .accessibilityHint("Enter the title for this note")
    }

    private var contentEditor: some View {
        TextEditor(text: $content)
            .font(.system(size: 16))
            .scrollContentBackground(.hidden)
            .background(.clear)
            .frame(minHeight: 400)
            .accessibilityLabel("Note content")
            .accessibilityHint("Enter the content for this note")
    }

    // MARK: - Actions

    private func saveNote() {
        // Debounced save - wait 1 second after last edit
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                do {
                    try service.updateNote(note, title: title, content: content)
                    lastSaved = Date()
                } catch {
                    print("Failed to save note: \(error)")
                }
            }
        }
    }

    private func togglePin() {
        do {
            try service.updateNote(note, isPinned: !note.isPinned)
            lastSaved = Date()
        } catch {
            print("Failed to toggle pin: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext

    let note = Note(context: context)
    note.id = UUID()
    note.title = "Meeting Notes"
    note.contentData = Data("Discussed project timeline and deliverables.\n\nKey points:\n- Focus on core features first\n- Plan for Q1 launch\n- Review designs next week".utf8)
    note.modifiedAt = Date()
    note.isPinned = false

    return NotionEditorView(note: note)
        .environment(\.managedObjectContext, context)
        .frame(width: 1000, height: 800)
}
