//
//  NotionEditorView.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI
import CoreData
import AppKit

/// Notion-inspired editor view with rich text editing and formatting toolbar
/// Supports inline formatting: bold, italic, headings, lists, etc.
struct NotionEditorView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var service: CoreDataService
    @State private var title: String
    @State private var attributedContent: NSAttributedString
    @State private var isSaving = false
    @State private var lastSaved: Date?
    @State private var textViewRef: NSTextView?

    @ObservedObject var note: Note

    init(note: Note) {
        self.note = note
        self._service = State(initialValue: CoreDataService())
        self._title = State(initialValue: note.title ?? "")

        // Load rich text content or create default
        if let contentData = note.contentData {
            self._attributedContent = State(initialValue: NSAttributedString.fromData(contentData))
        } else {
            self._attributedContent = State(initialValue: NSAttributedString(string: ""))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Formatting toolbar
            FormattingToolbar(textView: textViewRef) { action in
                handleFormattingAction(action)
            }
            .padding(.horizontal, .spacingXL)
            .padding(.top, .spacingM)

            // Editor content
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingM) {
                    // Title editor - Notion-style
                    titleEditor

                    // Rich text content editor
                    richTextEditor

                    Spacer(minLength: 200)
                }
                .padding(.spacingXL)
                .padding(.horizontal, 120) // Notion-like centered content
            }
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
        .onChange(of: attributedContent) { _, newValue in
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

    private var richTextEditor: some View {
        RichTextEditorWrapper(attributedText: $attributedContent, textViewRef: $textViewRef)
            .frame(minHeight: 400)
            .accessibilityLabel("Note content")
            .accessibilityHint("Enter the content for this note. Use formatting toolbar for bold, italic, headings, and lists")
    }

    // MARK: - Actions

    private func saveNote() {
        // Debounced save - wait 1 second after last edit
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                do {
                    // Convert attributed string to data for storage
                    let contentData = attributedContent.toData()
                    try service.updateNote(note, title: title, content: nil)

                    // Update content data separately
                    note.contentData = contentData
                    try context.save()

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

    private func handleFormattingAction(_ action: FormattingAction) {
        guard let textView = textViewRef else { return }

        switch action {
        case .bold:
            TextFormatter.applyBold(to: textView)
        case .italic:
            TextFormatter.applyItalic(to: textView)
        case .heading1:
            TextFormatter.applyHeading(to: textView, level: 1)
        case .heading2:
            TextFormatter.applyHeading(to: textView, level: 2)
        case .heading3:
            TextFormatter.applyHeading(to: textView, level: 3)
        case .normal:
            // Reset to normal text
            if let textStorage = textView.textStorage {
                let range = textView.selectedRange()
                let lineRange = (textStorage.string as NSString).lineRange(for: range)
                textStorage.addAttribute(.font, value: NSFont.systemFont(ofSize: 16), range: lineRange)
            }
        case .bulletList:
            TextFormatter.applyBulletList(to: textView)
        case .numberedList:
            // TODO: Implement numbered list
            break
        case .code, .link:
            // TODO: Implement code and link formatting
            break
        }

        // Update the attributed content binding
        attributedContent = textView.attributedString()
    }
}

// MARK: - Rich Text Editor Wrapper

struct RichTextEditorWrapper: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var textViewRef: NSTextView?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        // Configure text view
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator

        // Automatic features
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticLinkDetectionEnabled = true

        // Layout
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = NSSize(width: 0, height: 0)

        // Store reference
        DispatchQueue.main.async {
            self.textViewRef = textView
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView

        if textView.attributedString() != attributedText {
            let selectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributedText)

            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditorWrapper

        init(_ parent: RichTextEditorWrapper) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.attributedText = textView.attributedString()
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
