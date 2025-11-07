//
//  FormattingToolbar.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI
import AppKit

/// Notion-style formatting toolbar for inline text formatting
/// Appears when text is selected or via keyboard shortcuts
struct FormattingToolbar: View {
    let textView: NSTextView?
    let onFormat: (FormattingAction) -> Void

    var body: some View {
        HStack(spacing: .spacingS) {
            // Bold
            ToolbarButton(
                icon: "bold",
                label: "Bold",
                shortcut: "⌘B",
                action: { onFormat(.bold) }
            )

            Divider()
                .frame(height: 20)

            // Italic
            ToolbarButton(
                icon: "italic",
                label: "Italic",
                shortcut: "⌘I",
                action: { onFormat(.italic) }
            )

            Divider()
                .frame(height: 20)

            // Headings
            Menu {
                Button("Heading 1") { onFormat(.heading1) }
                Button("Heading 2") { onFormat(.heading2) }
                Button("Heading 3") { onFormat(.heading3) }
                Button("Normal Text") { onFormat(.normal) }
            } label: {
                Label("Text Style", systemImage: "textformat.size")
                    .font(.system(size: 13))
            }
            .menuStyle(.borderlessButton)
            .frame(height: 28)

            Divider()
                .frame(height: 20)

            // Bullet List
            ToolbarButton(
                icon: "list.bullet",
                label: "Bullet List",
                action: { onFormat(.bulletList) }
            )

            // Numbered List
            ToolbarButton(
                icon: "list.number",
                label: "Numbered List",
                action: { onFormat(.numberedList) }
            )

            Spacer()

            // Markdown hint
            Text("Tip: Use **bold**, *italic*, # heading")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, .spacingM)
        .padding(.vertical, .spacingS)
        .background(.background.secondary)
        .cornerRadius(8)
    }
}

// MARK: - Toolbar Button

struct ToolbarButton: View {
    let icon: String
    let label: String
    var shortcut: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .help(shortcut != nil ? "\(label) (\(shortcut!))" : label)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.clear)
        )
    }
}

// MARK: - Formatting Actions

enum FormattingAction {
    case bold
    case italic
    case heading1
    case heading2
    case heading3
    case normal
    case bulletList
    case numberedList
    case code
    case link
}

// MARK: - Preview

#Preview {
    FormattingToolbar(textView: nil) { action in
        print("Format action: \(action)")
    }
    .frame(width: 800)
    .padding()
}
