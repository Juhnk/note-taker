//
//  TagChip.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI

/// Small pill-shaped chip for displaying tags
/// Notion-style design with minimal monochrome styling
struct TagChip: View {
    let tag: Tag
    let onDelete: (() -> Void)?

    init(tag: Tag, onDelete: (() -> Void)? = nil) {
        self.tag = tag
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(spacing: .spacingXS) {
            Text(tag.name ?? "Unknown")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(tag.name ?? "tag")")
            }
        }
        .padding(.horizontal, .spacingS)
        .padding(.vertical, 4)
        .background(.background.secondary)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tag: \(tag.name ?? "Unknown")")
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext

    let tag1 = Tag(context: context)
    tag1.id = UUID()
    tag1.name = "Swift"

    let tag2 = Tag(context: context)
    tag2.id = UUID()
    tag2.name = "iOS Development"

    return VStack(spacing: .spacingM) {
        // Tag without delete button
        TagChip(tag: tag1)

        // Tag with delete button
        TagChip(tag: tag2) {
            print("Delete tag")
        }

        // Multiple tags in a row
        HStack(spacing: .spacingS) {
            TagChip(tag: tag1)
            TagChip(tag: tag2)
        }
    }
    .padding()
}
