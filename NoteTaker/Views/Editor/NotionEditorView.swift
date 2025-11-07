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
/// Keyboard shortcuts: Cmd+B (bold), Cmd+I (italic), Cmd+Shift+1-3 (headings)
struct NotionEditorView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var service: CoreDataService
    @State private var title: String
    @State private var attributedContent: NSAttributedString
    @State private var isSaving = false
    @State private var lastSaved: Date?
    @State private var textViewRef: NSTextView?
    @State private var showTagPicker = false
    @State private var showFolderPicker = false

    @ObservedObject var note: Note
    @Binding var currentTextView: NSTextView?
    @Binding var formatAction: ((FormattingAction) -> Void)?

    init(
        note: Note,
        currentTextView: Binding<NSTextView?> = .constant(nil),
        formatAction: Binding<((FormattingAction) -> Void)?> = .constant(nil)
    ) {
        self.note = note
        self._currentTextView = currentTextView
        self._formatAction = formatAction
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

                    // Tags section
                    tagsSection

                    // Rich text content editor
                    richTextEditor

                    Spacer(minLength: 200)
                }
                .padding(.spacingXL)
                .padding(.horizontal, 120) // Notion-like centered content
            }
        }
        .sheet(isPresented: $showTagPicker) {
            TagPicker(note: note)
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderPicker(note: note) { folder in
                moveToFolder(folder)
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
        .onChange(of: title) { _, _ in
            saveNote()
        }
        .onChange(of: attributedContent) { _, _ in
            saveNote()
        }
        .onChange(of: textViewRef) { _, newValue in
            // Update the current text view reference for keyboard shortcuts
            currentTextView = newValue
        }
        .onAppear {
            // Set up format action handler for menu commands
            formatAction = { action in
                handleFormattingAction(action)
            }
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

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack(spacing: .spacingS) {
                // Display current folder
                if let folder = note.folder {
                    Button {
                        showFolderPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: folder.icon ?? "folder")
                                .font(.system(size: 11))
                            Text(folder.name ?? "Untitled")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, .spacingS)
                        .padding(.vertical, 4)
                        .background(.background.secondary)
                        .cornerRadius(12)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        showFolderPicker = true
                    } label: {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Move to folder")
                }

                // Display current tags
                if let tags = note.tags as? Set<Tag>, !tags.isEmpty {
                    ForEach(Array(tags).sorted(by: {
                        ($0.name ?? "") < ($1.name ?? "")
                    })) { tag in
                        TagChip(tag: tag) {
                            removeTag(tag)
                        }
                    }
                }

                // Add tag button
                Button {
                    showTagPicker = true
                } label: {
                    Image(systemName: "tag")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add tags")
            }
        }
    }

    private var richTextEditor: some View {
        RichTextEditorWrapper(
            attributedText: $attributedContent,
            textViewRef: $textViewRef
        )
        .frame(minHeight: 400)
        .accessibilityLabel("Note content")
        .accessibilityHint(
            "Enter the content for this note. Use formatting toolbar"
        )
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
                    try service.updateNote(
                        note,
                        title: title,
                        content: nil
                    )

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

        applyFormatting(action, to: textView)

        // Update the attributed content binding
        attributedContent = textView.attributedString()
    }

    private func applyFormatting(_ action: FormattingAction, to textView: NSTextView) {
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
            applyNormalText(to: textView)
        case .bulletList:
            TextFormatter.applyBulletList(to: textView)
        case .numberedList:
            TextFormatter.applyNumberedList(to: textView)
        case .code, .link:
            // Code and link formatting will be implemented in future sprint
            break
        }
    }

    private func applyNormalText(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()
        let lineRange = (textStorage.string as NSString).lineRange(for: range)
        textStorage.addAttribute(
            .font,
            value: NSFont.systemFont(ofSize: 16),
            range: lineRange
        )
    }

    private func removeTag(_ tag: Tag) {
        do {
            try service.removeTag(tag, from: note)
        } catch {
            print("Failed to remove tag: \(error)")
        }
    }

    private func moveToFolder(_ folder: Folder?) {
        do {
            try service.updateNote(note, folder: folder)
        } catch {
            print("Failed to move note to folder: \(error)")
        }
    }
}

// MARK: - Rich Text Editor Wrapper

struct RichTextEditorWrapper: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var textViewRef: NSTextView?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            fatalError("Failed to create NSTextView")
        }

        // Configure text view
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear

        // Enable markdown auto-conversion
        let markdownConverter = MarkdownConverter(textView: textView)
        context.coordinator.markdownConverter = markdownConverter
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
        guard let textView = scrollView.documentView as? NSTextView else { return }

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
        var markdownConverter: MarkdownConverter?

        init(_ parent: RichTextEditorWrapper) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // First, let markdown converter process
            markdownConverter?.textDidChange(notification)

            // Then update the binding
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
    let content = """
        Discussed project timeline and deliverables.

        Key points:
        - Focus on core features first
        - Plan for Q1 launch
        - Review designs next week
        """
    note.contentData = Data(content.utf8)
    note.modifiedAt = Date()
    note.isPinned = false

    return NotionEditorView(note: note)
        .environment(\.managedObjectContext, context)
        .frame(width: 1000, height: 800)
}
