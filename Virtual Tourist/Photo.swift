//
//  Picture.swift //I did not read properly and created the entire proyect with an entitie called Picture instead of Photo
//  Virtual Tourist
//
//  Created by mikel lizarralde cabrejas on 1/8/15.
//  Copyright (c) 2015 mikel lizarralde cabrejas. All rights reserved.
//

import Foundation
import CoreData
import UIKit


@objc(Photo)
class Photo: NSManagedObject{
    
    struct Keys {
        static let Title = "title"
        static let Path = "path"
    }
    
    @NSManaged var title: String
    @NSManaged var path: String
    @NSManaged var pin:Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        

        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        self.title = dictionary[Keys.Title] as! String
        
        if var imagePath = dictionary[Keys.Path] as? String {
            self.path = imagePath
        }
    }
    
    var image: UIImage? {
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(self.path)
        }
        set {
            FlickrClient.Caches.imageCache.storeImage(image, withIdentifier: self.path)
        }
    }
}