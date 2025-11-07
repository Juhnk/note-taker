//
//  NoteTakerApp.swift
//  NoteTaker
//
//  Created by Juhnk on 11/4/25.
//

import SwiftUI
import CoreData
import AppKit

@main
struct NoteTakerApp: App {
    let persistenceController = PersistenceController.shared
    @State private var currentTextView: NSTextView?
    @State private var formatAction: ((FormattingAction) -> Void)?

    var body: some Scene {
        WindowGroup {
            MainView(
                currentTextView: $currentTextView,
                formatAction: $formatAction
            )
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            FormattingCommands(currentTextView: $currentTextView) { action in
                formatAction?(action)
            }
        }
    }
}
