//
//  Folder+CoreDataProperties.swift
//  NoteTaker
//
//  Created by Juhnk on 11/5/25.
//
//

import Foundation
import CoreData

extension Folder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var icon: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var sortOrder: Int16
    @NSManaged public var notes: NSSet?
    @NSManaged public var parentFolder: Folder?
    @NSManaged public var subfolders: NSSet?

}

// MARK: Generated accessors for notes
extension Folder {

    @objc(addNotesObject:)
    @NSManaged public func addToNotes(_ value: Note)

    @objc(removeNotesObject:)
    @NSManaged public func removeFromNotes(_ value: Note)

    @objc(addNotes:)
    @NSManaged public func addToNotes(_ values: NSSet)

    @objc(removeNotes:)
    @NSManaged public func removeFromNotes(_ values: NSSet)

}

// MARK: Generated accessors for subfolders
extension Folder {

    @objc(addSubfoldersObject:)
    @NSManaged public func addToSubfolders(_ value: Folder)

    @objc(removeSubfoldersObject:)
    @NSManaged public func removeFromSubfolders(_ value: Folder)

    @objc(addSubfolders:)
    @NSManaged public func addToSubfolders(_ values: NSSet)

    @objc(removeSubfolders:)
    @NSManaged public func removeFromSubfolders(_ values: NSSet)

}

extension Folder: Identifiable {

}
