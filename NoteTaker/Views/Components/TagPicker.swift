//
//  TagPicker.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI

/// Notion-style tag picker for adding/removing tags from a note
/// Supports creating new tags and selecting from existing tags
struct TagPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var service: CoreDataService
    @State private var allTags: [Tag] = []
    @State private var selectedTags: Set<UUID> = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    let note: Note

    init(note: Note) {
        self.note = note
        self._service = State(initialValue: CoreDataService())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search/Create field
                searchField

                Divider()

                // Tag list
                if isLoading {
                    ProgressView()
                        .padding(.spacingXL)
                } else if let errorMessage = errorMessage {
                    errorView(errorMessage)
                } else {
                    tagList
                }
            }
            .navigationTitle("Tags")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadTags()
                loadNoteTags()
            }
        }
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack(spacing: .spacingS) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 14))

            TextField("Search or create tag", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .onSubmit {
                    if !searchText.isEmpty {
                        createAndAddTag(name: searchText)
                    }
                }

            if !searchText.isEmpty {
                Button {
                    createAndAddTag(name: searchText)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Create tag '\(searchText)'")
            }
        }
        .padding(.spacingM)
        .background(.background.secondary)
    }

    private var tagList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingXS) {
                ForEach(filteredTags) { tag in
                    TagRow(
                        tag: tag,
                        isSelected: selectedTags.contains(tag.id ?? UUID())
                    ) {
                        toggleTag(tag)
                    }
                }
            }
            .padding(.spacingM)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: .spacingM) {
            Text(message)
                .foregroundStyle(.secondary)
            Button("Retry") {
                loadTags()
            }
        }
        .padding(.spacingXL)
    }

    // MARK: - Computed Properties

    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return allTags
        }
        return allTags.filter { tag in
            guard let name = tag.name else { return false }
            return name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Actions

    private func loadTags() {
        isLoading = true
        errorMessage = nil

        do {
            allTags = try service.fetchTags()
            isLoading = false
        } catch {
            errorMessage = "Failed to load tags: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func loadNoteTags() {
        if let tags = note.tags as? Set<Tag> {
            selectedTags = Set(tags.compactMap { $0.id })
        }
    }

    private func toggleTag(_ tag: Tag) {
        guard let tagId = tag.id else { return }

        do {
            if selectedTags.contains(tagId) {
                // Remove tag
                try service.removeTag(tag, from: note)
                selectedTags.remove(tagId)
            } else {
                // Add tag
                try service.addTag(tag, to: note)
                selectedTags.insert(tagId)
            }
        } catch {
            errorMessage = "Failed to update tag: \(error.localizedDescription)"
        }
    }

    private func createAndAddTag(name: String) {
        do {
            let tag = try service.createTag(name: name.trimmingCharacters(in: .whitespaces))
            try service.addTag(tag, to: note)

            // Reload tags and update selection
            loadTags()
            if let tagId = tag.id {
                selectedTags.insert(tagId)
            }

            // Clear search field
            searchText = ""
        } catch {
            errorMessage = "Failed to create tag: \(error.localizedDescription)"
        }
    }
}

// MARK: - Tag Row

struct TagRow: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingM) {
                Text(tag.name ?? "Unknown")
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.primary)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, .spacingS)
            .padding(.horizontal, .spacingM)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tag.name ?? "Unknown"), \(isSelected ? "selected" : "not selected")")
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let service = CoreDataService(context: context)

    // Create sample tags
    try? service.createTag(name: "Swift")
    try? service.createTag(name: "iOS Development")
    try? service.createTag(name: "Design")

    // Create sample note
    let note = try? service.createNote(title: "Sample Note")

    return TagPicker(note: note ?? Note(context: context))
        .environment(\.managedObjectContext, context)
}
