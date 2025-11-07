//
//  NoteTakerApp.swift
//  NoteTaker
//
//  Created by Juhnk on 11/4/25.
//

import SwiftUI
import CoreData

@main
struct NoteTakerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .defaultSize(width: 1200, height: 800)
    }
}
