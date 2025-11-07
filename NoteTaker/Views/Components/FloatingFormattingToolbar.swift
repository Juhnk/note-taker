//
//  FloatingFormattingToolbar.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI

/// Floating formatting toolbar that appears near selected text
/// Modern UX similar to Notion, Medium, etc.
struct FloatingFormattingToolbar: View {
    let position: CGPoint
    let onAction: (FormattingAction) -> Void

    var body: some View {
        HStack(spacing: .spacingS) {
            // Bold
            FormatButton(icon: "bold", tooltip: "Bold (⌘B)") {
                onAction(.bold)
            }

            // Italic
            FormatButton(icon: "italic", tooltip: "Italic (⌘I)") {
                onAction(.italic)
            }

            Divider()
                .frame(height: 20)

            // Headings
            FormatButton(icon: "h1.square", tooltip: "Heading 1") {
                onAction(.heading1)
            }

            FormatButton(icon: "h2.square", tooltip: "Heading 2") {
                onAction(.heading2)
            }

            FormatButton(icon: "h3.square", tooltip: "Heading 3") {
                onAction(.heading3)
            }

            Divider()
                .frame(height: 20)

            // Lists
            FormatButton(icon: "list.bullet", tooltip: "Bullet List") {
                onAction(.bulletList)
            }

            FormatButton(icon: "list.number", tooltip: "Numbered List") {
                onAction(.numberedList)
            }
        }
        .padding(.horizontal, .spacingS)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
        .position(x: position.x, y: position.y)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3), value: position)
    }
}

/// Individual format button in the floating toolbar
private struct FormatButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 28, height: 28)
                .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.1)

        FloatingFormattingToolbar(position: CGPoint(x: 200, y: 150)) { _ in
            // Preview action handler
        }
    }
    .frame(width: 600, height: 400)
}
