//
//  MainView.swift
//  NoteTaker
//
//  Created by Juhnk on 11/7/25.
//

import SwiftUI

/// Main application view with Notion-inspired split layout
/// Sidebar (224px) + Editor/Content area
struct MainView: View {
    @State private var selectedNote: Note?

    var body: some View {
        NavigationSplitView {
            // Sidebar - fixed 224px width like Notion
            SidebarView(selectedNote: $selectedNote)
        } detail: {
            // Detail/Editor view
            if let note = selectedNote {
                NotionEditorView(note: note)
            } else {
                emptyStateView
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)

            VStack(spacing: .spacingS) {
                Text("No Note Selected")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Select a note from the sidebar or create a new one")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .frame(width: 1200, height: 800)
}
