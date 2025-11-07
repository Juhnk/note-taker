//
//  FolderPicker.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI
import CoreData

/// Picker for selecting a folder to move a note into
/// Shows hierarchical folder structure with breadcrumbs
struct FolderPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var service: CoreDataService
    @State private var rootFolders: [Folder] = []
    @State private var currentFolder: Folder?
    @State private var showCreateDialog = false

    let note: Note
    let onSelect: (Folder?) -> Void

    init(note: Note, onSelect: @escaping (Folder?) -> Void) {
        self.note = note
        self.onSelect = onSelect
        self._service = State(initialValue: CoreDataService())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Breadcrumb navigation
                if currentFolder != nil {
                    breadcrumbBar
                    Divider()
                }

                // Folder list
                ScrollView {
                    VStack(spacing: .spacingXS) {
                        // "No folder" option
                        if currentFolder == nil {
                            Button {
                                onSelect(nil)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                    Text("No Folder")
                                        .font(.system(size: 14))
                                    Spacer()
                                    if note.folder == nil {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding(.spacingM)
                                .background(.background.secondary)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }

                        // Current level folders
                        ForEach(displayedFolders) { folder in
                            FolderPickerRow(
                                folder: folder,
                                isSelected: note.folder?.id == folder.id,
                                hasSubfolders: hasSubfolders(folder)
                            ) {
                                selectFolder(folder)
                            } onNavigate: {
                                navigateToFolder(folder)
                            }
                        }
                    }
                    .padding(.spacingM)
                }

                Divider()

                // Bottom actions
                HStack {
                    Button {
                        showCreateDialog = true
                    } label: {
                        Label("New Folder", systemImage: "plus")
                    }

                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }
                }
                .padding(.spacingM)
            }
            .navigationTitle("Move to Folder")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .sheet(isPresented: $showCreateDialog) {
            FolderDialog(parent: currentFolder) { name, icon in
                createFolder(name: name, icon: icon)
            }
        }
        .onAppear {
            loadFolders()
        }
    }

    // MARK: - Subviews

    private var breadcrumbBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingS) {
                Button {
                    currentFolder = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "house")
                            .font(.system(size: 12))
                        Text("All Folders")
                            .font(.system(size: 13))
                    }
                }
                .buttonStyle(.plain)

                if let folder = currentFolder {
                    ForEach(folderPath(folder), id: \.id) { pathFolder in
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)

                        Button {
                            currentFolder = pathFolder
                        } label: {
                            Text(pathFolder.name ?? "Untitled")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.spacingM)
        }
    }

    private var displayedFolders: [Folder] {
        rootFolders
    }

    // MARK: - Helpers

    private func loadFolders() {
        do {
            rootFolders = try service.fetchFolders(under: currentFolder)
        } catch {
            print("Failed to load folders: \(error)")
        }
    }

    private func selectFolder(_ folder: Folder) {
        onSelect(folder)
        dismiss()
    }

    private func navigateToFolder(_ folder: Folder) {
        currentFolder = folder
        loadFolders()
    }

    private func hasSubfolders(_ folder: Folder) -> Bool {
        do {
            let subfolders = try service.fetchFolders(under: folder)
            return !subfolders.isEmpty
        } catch {
            return false
        }
    }

    private func folderPath(_ folder: Folder) -> [Folder] {
        var path: [Folder] = []
        var current: Folder? = folder

        while let currentFolder = current {
            path.insert(currentFolder, at: 0)
            current = currentFolder.parentFolder
        }

        return path
    }

    private func createFolder(name: String, icon: String?) {
        do {
            _ = try service.createFolder(name: name, parent: currentFolder, icon: icon)
            loadFolders()
        } catch {
            print("Failed to create folder: \(error)")
        }
    }
}

// MARK: - Folder Picker Row

struct FolderPickerRow: View {
    let folder: Folder
    let isSelected: Bool
    let hasSubfolders: Bool
    let onSelect: () -> Void
    let onNavigate: () -> Void

    var body: some View {
        HStack(spacing: .spacingM) {
            Button(action: onSelect) {
                HStack {
                    Image(systemName: folder.icon ?? "folder")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Text(folder.name ?? "Untitled")
                        .font(.system(size: 14))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .buttonStyle(.plain)

            if hasSubfolders {
                Button(action: onNavigate) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.spacingM)
        .background(.background.secondary)
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let service = CoreDataService(context: context)

    // swiftlint:disable:next force_try
    let note = try! service.createNote(title: "Test Note")

    return FolderPicker(note: note) { _ in
        // Preview only - no action needed
    }
    .environment(\.managedObjectContext, context)
}
