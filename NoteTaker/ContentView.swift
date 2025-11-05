//
//  ContentView.swift
//  NoteTaker
//
//  Created by Juhnk on 11/4/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)],
        animation: .default)
    private var notes: FetchedResults<Note>

    var body: some View {
        NavigationView {
            List {
                ForEach(notes) { note in
                    NavigationLink {
                        Text("Note: \(note.title ?? "Untitled")")
                            .padding()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(note.title ?? "Untitled")
                                .font(.headline)
                            if let modifiedAt = note.modifiedAt {
                                Text(modifiedAt, formatter: itemFormatter)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteNotes)
            }
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addNote) {
                        Label("Add Note", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Notes")
            Text("Select a note")
        }
    }

    private func addNote() {
        withAnimation {
            let newNote = Note(context: viewContext)
            newNote.id = UUID()
            newNote.title = "New Note"
            newNote.createdAt = Date()
            newNote.modifiedAt = Date()
            newNote.isPinned = false

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            offsets.map { notes[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
