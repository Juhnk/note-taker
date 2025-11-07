//
//  KeyboardShortcuts.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI
import AppKit

/// Keyboard shortcuts for text formatting
/// Notion-style shortcuts: Cmd+B (bold), Cmd+I (italic), Cmd+E (code), etc.
struct FormattingKeyboardShortcuts: ViewModifier {
    let textViewRef: NSTextView?
    let onFormat: (FormattingAction) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                setupResponderChain()
            }
    }

    private func setupResponderChain() {
        guard let textView = textViewRef else { return }

        // Create custom responder for keyboard shortcuts
        let responder = FormattingResponder(onFormat: onFormat)
        textView.nextResponder = responder
    }
}

// MARK: - Custom Responder

class FormattingResponder: NSResponder {
    let onFormat: (FormattingAction) -> Void

    init(onFormat: @escaping (FormattingAction) -> Void) {
        self.onFormat = onFormat
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Cmd+B - Bold
    @objc func toggleBold(_ sender: Any?) {
        onFormat(.bold)
    }

    // Cmd+I - Italic
    @objc func toggleItalic(_ sender: Any?) {
        onFormat(.italic)
    }

    // Cmd+Shift+1 - Heading 1
    @objc func heading1(_ sender: Any?) {
        onFormat(.heading1)
    }

    // Cmd+Shift+2 - Heading 2
    @objc func heading2(_ sender: Any?) {
        onFormat(.heading2)
    }

    // Cmd+Shift+3 - Heading 3
    @objc func heading3(_ sender: Any?) {
        onFormat(.heading3)
    }

    // Cmd+Shift+0 - Normal text
    @objc func normalText(_ sender: Any?) {
        onFormat(.normal)
    }

    // Cmd+Shift+8 - Bullet list
    @objc func bulletList(_ sender: Any?) {
        onFormat(.bulletList)
    }

    // Cmd+Shift+7 - Numbered list
    @objc func numberedList(_ sender: Any?) {
        onFormat(.numberedList)
    }
}

extension View {
    func formattingKeyboardShortcuts(
        textViewRef: NSTextView?,
        onFormat: @escaping (FormattingAction) -> Void
    ) -> some View {
        self.modifier(FormattingKeyboardShortcuts(textViewRef: textViewRef, onFormat: onFormat))
    }
}

// MARK: - Menu Commands

/// Add formatting commands to the app menu
struct FormattingCommands: Commands {
    @Binding var currentTextView: NSTextView?
    let onFormat: (FormattingAction) -> Void

    var body: some Commands {
        CommandMenu("Format") {
            Button("Bold") {
                onFormat(.bold)
            }
            .keyboardShortcut("b", modifiers: .command)

            Button("Italic") {
                onFormat(.italic)
            }
            .keyboardShortcut("i", modifiers: .command)

            Divider()

            Button("Heading 1") {
                onFormat(.heading1)
            }
            .keyboardShortcut("1", modifiers: [.command, .shift])

            Button("Heading 2") {
                onFormat(.heading2)
            }
            .keyboardShortcut("2", modifiers: [.command, .shift])

            Button("Heading 3") {
                onFormat(.heading3)
            }
            .keyboardShortcut("3", modifiers: [.command, .shift])

            Button("Normal Text") {
                onFormat(.normal)
            }
            .keyboardShortcut("0", modifiers: [.command, .shift])

            Divider()

            Button("Bullet List") {
                onFormat(.bulletList)
            }
            .keyboardShortcut("8", modifiers: [.command, .shift])

            Button("Numbered List") {
                onFormat(.numberedList)
            }
            .keyboardShortcut("7", modifiers: [.command, .shift])
        }
    }
}
