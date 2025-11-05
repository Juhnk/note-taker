//
//  Attachment+CoreDataProperties.swift
//  NoteTaker
//
//  Created by Juhnk on 11/5/25.
//
//

import Foundation
import CoreData

extension Attachment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attachment> {
        return NSFetchRequest<Attachment>(entityName: "Attachment")
    }

    @NSManaged public var cloudKitAssetURL: String?
    @NSManaged public var fileName: String?
    @NSManaged public var fileSize: Int64
    @NSManaged public var id: UUID?
    @NSManaged public var localURL: String?
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var type: String?
    @NSManaged public var note: Note?

}

extension Attachment: Identifiable {

}
