//
//  FlickerClient_Constants.swift
//  Virtual Tourist
//
//  Created by mikel lizarralde cabrejas on 1/8/15.
//  Copyright (c) 2015 mikel lizarralde cabrejas. All rights reserved.
//

import Foundation

extension FlickrClient{
    
    struct Constants {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "69670e3c762f908aa92328b1fbf3adb8"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let MAXIMUM_PER_PAGE = "240" //24*10 to say something
        static let boxSideLength = 0.07
        static let picturesToShow = 24 //limit of pictures to show on collection
    }
    
    struct JSONResult{
        static let picture = "photo"
        static let pictures = "photos"
        static let pages = "pages"
        static let title = "title"
        static let imageType = "url_m"
    }
    
}
