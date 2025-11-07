//
//  NoteCard.swift
//  NoteTaker
//
//  Created by Juhnk on 11/6/25.
//

import SwiftUI
import CoreData

/// A card component displaying a note preview
/// Follows the Design System: monochrome, minimal, accessible
struct NoteCard: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Note title
            HStack {
                Text(note.title ?? "Untitled")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                // Pin indicator
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Pinned")
                }
            }

            // Note preview (first few lines of content)
            if let contentData = note.contentData,
               let content = String(data: contentData, encoding: .utf8),
               !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            } else {
                Text("No content")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .italic()
            }

            // Metadata (modified date)
            if let modifiedAt = note.modifiedAt {
                Text(modifiedAt, style: .relative)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double tap to open note")
    }

    /// Accessibility label combining title, content preview, and metadata
    private var accessibilityLabelText: String {
        var label = note.title ?? "Untitled note"

        if note.isPinned {
            label += ", Pinned"
        }

        if let contentData = note.contentData,
           let content = String(data: contentData, encoding: .utf8),
           !content.isEmpty {
            let preview = String(content.prefix(100))
            label += ", \(preview)"
        }

        if let modifiedAt = note.modifiedAt {
            label += ", Modified \(modifiedAt.formatted(.relative(presentation: .named)))"
        }

        return label
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext

    let note = Note(context: context)
    note.id = UUID()
    note.title = "Meeting Notes"
    let noteContent = "Discussed project timeline and deliverables. " +
        "Key points: focus on core features first, plan for Q1 launch."
    note.contentData = Data(noteContent.utf8)
    note.isPinned = false
    note.modifiedAt = Date().addingTimeInterval(-3600)

    let pinnedNote = Note(context: context)
    pinnedNote.id = UUID()
    pinnedNote.title = "Important Reminder"
    pinnedNote.contentData = Data("Don't forget to submit the report by Friday.".utf8)
    pinnedNote.isPinned = true
    pinnedNote.modifiedAt = Date().addingTimeInterval(-7200)

    return VStack(spacing: .spacingM) {
        NoteCard(note: note)
        NoteCard(note: pinnedNote)
    }
    .padding(.spacingM)
}
