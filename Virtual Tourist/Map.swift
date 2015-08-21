//
//  Map.swift
//  Virtual Tourist
//
//  Added to exceed expectations
//  Created by mikel lizarralde cabrejas on 21/8/15.
//  Copyright (c) 2015 mikel lizarralde cabrejas. All rights reserved.
//

//import Foundation
import CoreData

@objc(Map)

class Map: NSManagedObject {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var zoom: Double
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(latitude: Double, longitude: Double, zoom: Double, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Map", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = latitude
        self.longitude = longitude
        self.zoom = zoom
    }
}