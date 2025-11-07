//
//  EditorView.swift
//  NoteTaker
//
//  Created by Juhnk on 11/6/25.
//

import SwiftUI
import CoreData

/// Note editor view (placeholder for Sprint 1.4+)
/// Will be implemented with rich text editing in future sprint
struct EditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var service: CoreDataService
    @State private var title: String
    @State private var content: String
    @State private var errorMessage: String?

    let note: Note

    init(note: Note) {
        self.note = note
        self._service = State(initialValue: CoreDataService())
        self._title = State(initialValue: note.title ?? "")

        let contentString = note.contentData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        self._content = State(initialValue: contentString)
    }

    var body: some View {
        VStack(spacing: .spacingM) {
            // Title field
            TextField("Note title", text: $title, axis: .vertical)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.spacingM)
                .background(.background.secondary)
                .cornerRadius(8)
                .accessibilityLabel("Note title")
                .accessibilityHint("Enter the title for this note")

            // Content editor (placeholder - plain text for now)
            TextEditor(text: $content)
                .font(.body)
                .padding(.spacingM)
                .background(.background.secondary)
                .cornerRadius(8)
                .accessibilityLabel("Note content")
                .accessibilityHint("Enter the content for this note")

            Spacer()

            // Error message if any
            if let errorMessage = errorMessage {
                HStack(spacing: .spacingS) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)

                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.spacingM)
                .background(.background.secondary)
                .cornerRadius(8)
            }
        }
        .padding(.spacingM)
        .navigationTitle("Edit Note")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .accessibilityLabel("Cancel editing")
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    saveNote()
                }
                .fontWeight(.semibold)
                .accessibilityLabel("Save note")
                .accessibilityHint("Save changes and close the editor")
            }
        }
    }

    // MARK: - Actions

    private func saveNote() {
        do {
            try service.updateNote(note, title: title, content: content)
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext

    let note = Note(context: context)
    note.id = UUID()
    note.title = "Meeting Notes"
    note.contentData = Data("Discussed project timeline and deliverables.".utf8)
    note.modifiedAt = Date()

    return NavigationStack {
        EditorView(note: note)
    }
}
