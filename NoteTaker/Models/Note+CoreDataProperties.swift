//
//  Note+CoreDataProperties.swift
//  NoteTaker
//
//  Created by Juhnk on 11/5/25.
//
//

import Foundation
import CoreData

extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var cloudKitRecordID: String?
    @NSManaged public var contentData: Data?
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isPinned: Bool
    @NSManaged public var lastSyncedAt: Date?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var syncStatus: String?
    @NSManaged public var title: String?
    @NSManaged public var attachments: NSSet?
    @NSManaged public var folder: Folder?
    @NSManaged public var tags: NSSet?

}

// MARK: Generated accessors for attachments
extension Note {

    @objc(addAttachmentsObject:)
    @NSManaged public func addToAttachments(_ value: Attachment)

    @objc(removeAttachmentsObject:)
    @NSManaged public func removeFromAttachments(_ value: Attachment)

    @objc(addAttachments:)
    @NSManaged public func addToAttachments(_ values: NSSet)

    @objc(removeAttachments:)
    @NSManaged public func removeFromAttachments(_ values: NSSet)

}

// MARK: Generated accessors for tags
extension Note {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}

extension Note: Identifiable {

}
