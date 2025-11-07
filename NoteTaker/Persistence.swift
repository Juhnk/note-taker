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

    /// Check if CloudKit is available (requires paid Apple Developer account)
    private static var isCloudKitAvailable: Bool {
        // CloudKit requires the com.apple.developer.icloud-services entitlement
        // This is only available with a paid Apple Developer Program account ($99/year)
        #if targetEnvironment(simulator)
        // Always disable CloudKit in simulator to avoid entitlement issues
        return false
        #else
        // Check if entitlements are present
        let entitlements = Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.icloud-services") as? [String]
        return entitlements?.contains("CloudKit") ?? false
        #endif
    }

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "NoteTaker")

        if inMemory {
            if let description = container.persistentStoreDescriptions.first {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        } else {
            // Configure persistent store
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve persistent store description")
            }

            // Always enable persistent history tracking (even without CloudKit)
            // This is required once enabled, and is good practice for multi-context scenarios
            description.setOption(true as NSNumber,
                                forKey: NSPersistentHistoryTrackingKey)

            if Self.isCloudKitAvailable {
                // CloudKit is available - enable full sync
                print("CloudKit is available - enabling sync")

                // Enable remote change notifications
                description.setOption(true as NSNumber,
                                    forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

                // CloudKit container options
                let cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: "iCloud.com.juhnk.NoteTaker"
                )
                description.cloudKitContainerOptions = cloudKitContainerOptions
            } else {
                // CloudKit not available - disable sync and run locally only
                print("CloudKit not available - running in local-only mode")
                print("To enable CloudKit sync:")
                print("1. Enroll in Apple Developer Program ($99/year)")
                print("2. Enable iCloud capability in Xcode")
                print("3. Sign the app with your developer account")

                // Explicitly disable CloudKit
                description.cloudKitContainerOptions = nil
            }
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
