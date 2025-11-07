//
//  RichTextEditor.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI
import AppKit

/// Rich text editor using NSTextView for macOS
/// Supports inline formatting like Notion: bold, italic, headings, lists
struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var font: NSFont = .systemFont(ofSize: 16)
    var onTextChange: ((NSAttributedString) -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        // Configure text view for rich text editing
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = font
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator

        // Enable automatic features
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticLinkDetectionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true

        // Configure layout
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = NSSize(width: 0, height: 0)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView

        // Only update if text has actually changed
        if textView.attributedString() != attributedText {
            let selectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributedText)

            // Restore selection if possible
            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
        }

        // Update font if changed
        if textView.font != font {
            textView.font = font
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Update binding
            parent.attributedText = textView.attributedString()

            // Call change handler
            parent.onTextChange?(textView.attributedString())
        }
    }
}

// MARK: - Rich Text Formatting Extensions

extension NSAttributedString {
    /// Convert to Data for Core Data storage
    func toData() -> Data? {
        do {
            let range = NSRange(location: 0, length: length)
            return try data(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        } catch {
            print("Failed to convert attributed string to data: \(error)")
            return nil
        }
    }

    /// Create from Data (Core Data storage)
    static func fromData(_ data: Data) -> NSAttributedString {
        do {
            return try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
        } catch {
            print("Failed to convert data to attributed string: \(error)")
            return NSAttributedString(string: "")
        }
    }
}

// MARK: - Text Formatting Helper

struct TextFormatter {
    /// Apply bold formatting to selected text
    static func applyBold(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()

        textStorage.beginEditing()

        let currentAttributes = textStorage.attributes(at: selectedRange.location, effectiveRange: nil)
        let currentFont = currentAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 16)

        let newFont: NSFont
        if currentFont.fontDescriptor.symbolicTraits.contains(.bold) {
            // Remove bold
            newFont = NSFont.systemFont(ofSize: currentFont.pointSize)
        } else {
            // Add bold
            newFont = NSFont.boldSystemFont(ofSize: currentFont.pointSize)
        }

        textStorage.addAttribute(.font, value: newFont, range: selectedRange)
        textStorage.endEditing()
    }

    /// Apply italic formatting to selected text
    static func applyItalic(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()

        textStorage.beginEditing()

        let currentAttributes = textStorage.attributes(at: selectedRange.location, effectiveRange: nil)
        let currentFont = currentAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 16)

        let newFont: NSFont
        if currentFont.fontDescriptor.symbolicTraits.contains(.italic) {
            // Remove italic
            newFont = NSFont.systemFont(ofSize: currentFont.pointSize)
        } else {
            // Add italic
            let fontDescriptor = currentFont.fontDescriptor.withSymbolicTraits(.italic)
            newFont = NSFont(descriptor: fontDescriptor, size: currentFont.pointSize) ?? currentFont
        }

        textStorage.addAttribute(.font, value: newFont, range: selectedRange)
        textStorage.endEditing()
    }

    /// Apply heading style
    static func applyHeading(to textView: NSTextView, level: Int = 1) {
        guard let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()

        // Find the line range
        let string = textStorage.string as NSString
        let lineRange = string.lineRange(for: selectedRange)

        textStorage.beginEditing()

        let fontSize: CGFloat
        let isBold: Bool

        switch level {
        case 1:
            fontSize = 32
            isBold = true
        case 2:
            fontSize = 24
            isBold = true
        case 3:
            fontSize = 20
            isBold = true
        default:
            fontSize = 16
            isBold = false
        }

        let font = isBold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
        textStorage.addAttribute(.font, value: font, range: lineRange)

        textStorage.endEditing()
    }

    /// Apply bullet list
    static func applyBulletList(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()

        // Find the line range
        let string = textStorage.string as NSString
        let lineRange = string.lineRange(for: selectedRange)

        textStorage.beginEditing()

        // Create paragraph style with bullet
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 20
        paragraphStyle.firstLineHeadIndent = 0

        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: lineRange)

        // Add bullet character if not present
        let lineString = string.substring(with: lineRange)
        if !lineString.hasPrefix("• ") {
            textStorage.insert(NSAttributedString(string: "• "), at: lineRange.location)
        }

        textStorage.endEditing()
    }
}
