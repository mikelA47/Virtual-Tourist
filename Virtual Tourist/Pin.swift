//
//  Pin.swift
//  Virtual Tourist
//
//  Created by mikel lizarralde cabrejas on 1/8/15.
//  Copyright (c) 2015 mikel lizarralde cabrejas. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
class Pin:NSManagedObject{
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Pages = "pages"
    }
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var pages: NSNumber?
    @NSManaged var photos: [Photo]?

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        self.latitude = dictionary[Keys.Latitude] as! NSNumber
        self.longitude = dictionary[Keys.Longitude] as! NSNumber
    }
    
}