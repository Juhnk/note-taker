//
//  MarkdownConverter.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import Foundation
import AppKit

/// Markdown auto-conversion for Notion-style shortcuts
/// Converts markdown syntax to rich text formatting as you type
/// Examples: **bold**, *italic*, # Heading, - bullet list
class MarkdownConverter: NSObject, NSTextViewDelegate {
    weak var textView: NSTextView?
    private var isProcessing = false

    init(textView: NSTextView) {
        self.textView = textView
        super.init()
    }

    func textDidChange(_ notification: Notification) {
        guard let textView = textView,
              !isProcessing,
              let textStorage = textView.textStorage else { return }

        let selectedRange = textView.selectedRange()

        // Only process when user just typed a space or newline (triggers conversion)
        guard selectedRange.location > 0 else { return }

        let text = textStorage.string as NSString
        let lastChar = text.substring(with: NSRange(location: selectedRange.location - 1, length: 1))

        guard lastChar == " " || lastChar == "\n" else { return }

        isProcessing = true
        defer { isProcessing = false }

        // Find the current line
        let lineRange = text.lineRange(for: NSRange(location: selectedRange.location - 1, length: 0))
        let lineText = text.substring(with: lineRange)

        // Try different markdown patterns
        if let result = convertBoldMarkdown(lineText, in: lineRange, textStorage: textStorage, cursor: selectedRange.location) {
            textView.setSelectedRange(NSRange(location: result, length: 0))
        } else if let result = convertItalicMarkdown(lineText, in: lineRange, textStorage: textStorage, cursor: selectedRange.location) {
            textView.setSelectedRange(NSRange(location: result, length: 0))
        } else if let result = convertHeadingMarkdown(lineText, in: lineRange, textStorage: textStorage, cursor: selectedRange.location) {
            textView.setSelectedRange(NSRange(location: result, length: 0))
        } else if let result = convertBulletListMarkdown(lineText, in: lineRange, textStorage: textStorage, cursor: selectedRange.location) {
            textView.setSelectedRange(NSRange(location: result, length: 0))
        }
    }

    // MARK: - Bold Conversion (**text**)

    private func convertBoldMarkdown(_ lineText: String, in lineRange: NSRange, textStorage: NSTextStorage, cursor: Int) -> Int? {
        // Pattern: **text** followed by space
        let pattern = "\\*\\*(.+?)\\*\\* $"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.count)) else {
            return nil
        }

        let matchRange = NSRange(location: lineRange.location + match.range.location,
                                length: match.range.length)
        let contentRange = NSRange(location: lineRange.location + match.range(at: 1).location,
                                  length: match.range(at: 1).length)

        textStorage.beginEditing()

        // Get the matched text
        let text = textStorage.string as NSString
        let content = text.substring(with: contentRange)

        // Create bold attributed string
        let boldFont = NSFont.boldSystemFont(ofSize: 16)
        let boldText = NSAttributedString(string: content, attributes: [.font: boldFont])

        // Replace the markdown with formatted text
        textStorage.replaceCharacters(in: matchRange, with: boldText)

        textStorage.endEditing()

        // Return new cursor position (after the bold text and space)
        return matchRange.location + content.count + 1
    }

    // MARK: - Italic Conversion (*text*)

    private func convertItalicMarkdown(_ lineText: String, in lineRange: NSRange, textStorage: NSTextStorage, cursor: Int) -> Int? {
        // Pattern: *text* followed by space (but not **text**)
        let pattern = "(?<!\\*)\\*([^*]+?)\\* $"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.count)) else {
            return nil
        }

        let matchRange = NSRange(location: lineRange.location + match.range.location,
                                length: match.range.length)
        let contentRange = NSRange(location: lineRange.location + match.range(at: 1).location,
                                  length: match.range(at: 1).length)

        textStorage.beginEditing()

        // Get the matched text
        let text = textStorage.string as NSString
        let content = text.substring(with: contentRange)

        // Create italic attributed string
        let italicFont = NSFont.systemFont(ofSize: 16)
        let fontDescriptor = italicFont.fontDescriptor.withSymbolicTraits(.italic)
        let italicFontFinal = NSFont(descriptor: fontDescriptor, size: 16) ?? italicFont
        let italicText = NSAttributedString(string: content, attributes: [.font: italicFontFinal])

        // Replace the markdown with formatted text
        textStorage.replaceCharacters(in: matchRange, with: italicText)

        textStorage.endEditing()

        // Return new cursor position
        return matchRange.location + content.count + 1
    }

    // MARK: - Heading Conversion (# Heading)

    private func convertHeadingMarkdown(_ lineText: String, in lineRange: NSRange, textStorage: NSTextStorage, cursor: Int) -> Int? {
        // Pattern: # Heading, ## Heading, or ### Heading at start of line
        let pattern = "^(#{1,3}) (.+?) $"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.count)) else {
            return nil
        }

        let hashesRange = match.range(at: 1)
        let contentRange = NSRange(location: lineRange.location + match.range(at: 2).location,
                                  length: match.range(at: 2).length)
        let matchRange = NSRange(location: lineRange.location, length: match.range.length)

        let hashCount = hashesRange.length

        textStorage.beginEditing()

        // Get the matched text
        let text = textStorage.string as NSString
        let content = text.substring(with: contentRange)

        // Determine heading level
        let fontSize: CGFloat
        switch hashCount {
        case 1: fontSize = 32  // H1
        case 2: fontSize = 24  // H2
        case 3: fontSize = 20  // H3
        default: fontSize = 16
        }

        // Create heading attributed string
        let headingFont = NSFont.boldSystemFont(ofSize: fontSize)
        let headingText = NSAttributedString(string: content + " ", attributes: [.font: headingFont])

        // Replace the markdown with formatted text
        textStorage.replaceCharacters(in: matchRange, with: headingText)

        textStorage.endEditing()

        // Return new cursor position
        return lineRange.location + content.count + 1
    }

    // MARK: - Bullet List Conversion (- or *)

    private func convertBulletListMarkdown(_ lineText: String, in lineRange: NSRange, textStorage: NSTextStorage, cursor: Int) -> Int? {
        // Pattern: - or * at start of line followed by space
        let pattern = "^[-*] $"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              regex.firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.count)) != nil else {
            return nil
        }

        textStorage.beginEditing()

        // Create paragraph style with bullet
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 20
        paragraphStyle.firstLineHeadIndent = 0

        // Replace "- " or "* " with bullet "• "
        let bulletText = NSAttributedString(string: "• ", attributes: [
            .font: NSFont.systemFont(ofSize: 16),
            .paragraphStyle: paragraphStyle
        ])

        textStorage.replaceCharacters(in: NSRange(location: lineRange.location, length: 2), with: bulletText)

        textStorage.endEditing()

        // Return new cursor position
        return lineRange.location + 2
    }
}

// MARK: - Text View Extension

extension NSTextView {
    /// Enable markdown auto-conversion for this text view
    func enableMarkdownConversion() -> MarkdownConverter {
        let converter = MarkdownConverter(textView: self)
        self.delegate = converter
        return converter
    }
}
