//
//  Persistence.swift
//  NoteTaker
//
//  Created by Juhnk on 11/4/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample notes for preview
        for i in 0..<10 {
            let newNote = Note(context: viewContext)
            newNote.id = UUID()
            newNote.title = "Sample Note \(i + 1)"
            newNote.createdAt = Date()
            newNote.modifiedAt = Date()
            newNote.isPinned = false
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "NoteTaker")

        if inMemory {
            if let description = container.persistentStoreDescriptions.first {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        } else {
            // Configure CloudKit sync
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve persistent store description")
            }

            // Enable persistent history tracking for CloudKit
            description.setOption(true as NSNumber,
                                forKey: NSPersistentHistoryTrackingKey)

            // Enable remote change notifications
            description.setOption(true as NSNumber,
                                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            // CloudKit container options
            // Note: This requires a paid Apple Developer Program account ($99/year)
            // Container ID must match the one in NoteTaker.entitlements
            let cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.juhnk.NoteTaker"
            )
            description.cloudKitContainerOptions = cloudKitContainerOptions
        }

        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 * CloudKit is not configured (requires paid Apple Developer account).
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })

        // Automatically merge changes from parent (CloudKit sync)
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Merge policy: local changes win in conflicts
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Set up notifications for remote changes from CloudKit
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { _ in
            // Handle remote changes if needed
            // The viewContext will automatically merge changes due to automaticallyMergesChangesFromParent
            print("Remote CloudKit changes detected and merged")
        }
    }
}
