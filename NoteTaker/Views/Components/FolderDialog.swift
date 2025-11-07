//
//  FolderDialog.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI
import CoreData

/// Dialog for creating or editing folders
/// Notion-style simple form with name and optional icon
struct FolderDialog: View {
    @Environment(\.dismiss) private var dismiss
    @State private var folderName = ""
    @State private var selectedIcon: String?
    @State private var errorMessage: String?

    let parent: Folder?
    let onSave: (String, String?) -> Void

    // Common folder icons
    private let icons = [
        "folder", "folder.fill",
        "doc.text", "book",
        "briefcase", "house",
        "person", "star"
    ]

    var body: some View {
        VStack(spacing: .spacingL) {
            // Header
            Text("New Folder")
                .font(.title2)
                .fontWeight(.semibold)

            // Name field
            VStack(alignment: .leading, spacing: .spacingS) {
                Text("Name")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                TextField("Folder name", text: $folderName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
            }

            // Icon picker
            VStack(alignment: .leading, spacing: .spacingS) {
                Text("Icon (Optional)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: .spacingS) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = selectedIcon == icon ? nil : icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            // Buttons
            HStack(spacing: .spacingM) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createFolder()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(folderName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.spacingL)
        .frame(width: 400, height: 400)
    }

    private func createFolder() {
        let trimmedName = folderName.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            errorMessage = "Folder name cannot be empty"
            return
        }

        onSave(trimmedName, selectedIcon)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    FolderDialog(parent: nil) { _, _ in
        // Preview only - no action needed
    }
}
