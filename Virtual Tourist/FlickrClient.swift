//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by mikel lizarralde cabrejas on 8/8/15.
//  Copyright (c) 2015 mikel lizarralde cabrejas. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
}

class FlickrClient: NSObject {
    typealias CompletionHandler = (result: AnyObject!, error: NSError?) -> Void //taken from TheMovieDB.swift, works similar to typedef in C, just added an l
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext!
    }
    
    //Function to parse properly both types so we can generate a random number
    func parseForRandom(number: AnyObject) -> Int
    {
        if let parse = number as? NSNumber {
            return Int(arc4random_uniform(UInt32(Int(parse))))
        } else {
            return Int(arc4random_uniform(UInt32((number as? Int)!)))
        }
    }
    
    func trueRandom(seed: Int, already: [Int]) -> Int
    {
        var candidate:Int = self.parseForRandom(seed)
        
        while (contains(already,candidate)){
                 candidate = self.parseForRandom(seed) //extract random numbers until we got one that there was not there before
        }
        return candidate
    }
    
    //Search method to use against Flicker to try to download pictures with our search parameters
    func searchPicturesForPin(let pin:Pin,completionHandler: (success: Bool,helperArray: [[String]]?, errorString: String?) -> Void) {

        var page = 1
        
        if let numberOfPages = pin.pages{
            page = self.parseForRandom(numberOfPages) + 1 //we don´t want to receive a 0
        }
        
        let resource = FlickrClient.Constants.BASE_URL
        //create the dictionary of search parameters
        var parameters = [
            "method": FlickrClient.Constants.METHOD_NAME,
            "api_key": FlickrClient.Constants.API_KEY,
            "bbox": createBoundingBoxString(pin),
            "safe_search": FlickrClient.Constants.SAFE_SEARCH,
            "extras": FlickrClient.Constants.EXTRAS,
            "format": FlickrClient.Constants.DATA_FORMAT,
            "nojsoncallback": FlickrClient.Constants.NO_JSON_CALLBACK,
            "per_page":FlickrClient.Constants.MAXIMUM_PER_PAGE,
            "page":String(page)
        ]
        
        FlickrClient.sharedInstance.taskForResource(resource, parameters: parameters){ JSONResult, error  in
            if let error = error {
                println(error)
            } else {
                //1.- Get the dictionary
                if let picturesDictionary = JSONResult.valueForKey(FlickrClient.JSONResult.pictures) as? [String:AnyObject] {
                    //2.- Extract the pictures
                    if let picturesArray = picturesDictionary[FlickrClient.JSONResult.picture] as? [[String: AnyObject]] {
                        //3.- Check total pictures
                        var totalPictures = picturesArray.count
                        
                        if totalPictures > 0 {
                            
                            var picturesToShow: Int
                            //some checking to avoid having more pictures to show than the auto-limit decided
                            if totalPictures > FlickrClient.Constants.picturesToShow{
                                picturesToShow = FlickrClient.Constants.picturesToShow
                            } else {
                                picturesToShow = totalPictures
                            }
                            
                            if let totalPicturesPages = picturesDictionary[FlickrClient.JSONResult.pages] as? Int {
                                pin.pages = totalPicturesPages
                            }
                            
                            var alreadyRandom:[Int] = [] //used random numbers
                            var random: Int //unique random number to be used
                            var helperArray = [[String]]()//to store title and URL
                            for a in 0 ..< picturesToShow { //24 iteracies maximum
                                
                                var random = self.trueRandom(picturesArray.count, already: alreadyRandom)
                                //We get a truly and not existing random Int number, or at least it´s what I intended
                                alreadyRandom.append(random)//added to the existing list of random numbers
                                //Extract random picture
                                let pictureDictionary = picturesArray[random] as [String: AnyObject]
                                //create parameters
                                let pictureTitle = pictureDictionary[FlickrClient.JSONResult.title] as! String
                                var pictureURLString = pictureDictionary[FlickrClient.JSONResult.imageType] as! String
                                //add the parameters to the helperArray to be passed
                                helperArray.append([pictureTitle,pictureURLString])
                            }
                            completionHandler(success: true,helperArray:helperArray, errorString: nil) //Good to go
                        } else {
                            completionHandler(success: false,helperArray:nil, errorString: "No pictures to download")
                        }
                    } else {
                        completionHandler(success: false,helperArray:nil, errorString: "No pictures to download")
                    }
                }
            }
        }
    }
    
    //Download picture/image using the images paths
    func requestImageForCell(imagePath:String, cell:CollectionViewCell,completionHandler: (success: Bool, errorString: String?) -> Void){
        
        //build request with imagePath of pre-search/loaded pictures
        let imgURL = NSURL(string: imagePath)
        let request = NSURLRequest(URL: imgURL!)
        let mainQueue = NSOperationQueue.mainQueue()
        
        //send request to get data
        NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
            
            if error == nil {
                //create image with data
                let image = UIImage(data: data)
                //store image to be recover at collectionView
                NSKeyedArchiver.archiveRootObject(image!,toFile: self.parseImagePath(imagePath.lastPathComponent))
                //set cell image with image
                cell.imageCell.image = image
                completionHandler(success: true, errorString: nil)//good to go for next
            }
            else {
                completionHandler(success: false, errorString: "\(imagePath) not available")
                //placeholder cellImage should prevail, not happend so far
            }
        })
    }
    
    // Parse imagePath so it can be archive/save
    func parseImagePath(lastPathComponent:String) -> String{
        let parseURL = (NSFileManager.defaultManager()).URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return parseURL.URLByAppendingPathComponent(lastPathComponent).path!
    }
    
    // Create bounding box: String for search method
    func createBoundingBoxString(let pin:Pin) -> String{
        let maxLatitud:NSNumber = (pin.latitude as Double) + FlickrClient.Constants.boxSideLength
        let latitude = "\(pin.latitude)"
        let maxLongitud:NSNumber = (pin.longitude as Double) + FlickrClient.Constants.boxSideLength
        let longitude = "\(pin.longitude)"
        return longitude + "," + latitude + "," + "\(maxLongitud)" + "," + "\(maxLatitud)"
    }
    
    
    // MARK: - All purpose task method for data
    
    func taskForResource(resource: String, parameters: [String : AnyObject], completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        
        var mutableParameters = parameters
        var mutableResource = resource + FlickrClient.escapedParameters(mutableParameters)
        
        let urlString = mutableResource
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                let newError = FlickrClient.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: downloadError)
            } else {
                FlickrClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
            }
        }
        
        task.resume()
        
        return task
    }
    
    
    
    
    // MARK: - Helpers
    
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String : AnyObject] {
            if let errorMessage = parsedResult["msg"] as? String {
                
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                return NSError(domain: "Flickr Error", code: 1, userInfo: userInfo)
            }
        }
        
        return error
    }
    
    
    // Parsing JSON
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHandler) {
        var parsingError: NSError? = nil
        
        let parsedResults: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResults, error: nil)
        }
    }
    
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            // make sure that it is a string value
            let stringValue = "\(value)"
            
            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it
            
            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
                println("Warning: trouble excaping string \"\(stringValue)\"")
            }
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    
    // MARK: - Shared Instance
    //Suggestion made by reviwer -> take adavntage of a class static/constant
    /*
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }*/
    
    static let sharedInstance = FlickrClient()
    
    // MARK: - Shared Date Formatter
    
    class var sharedDateFormatter: NSDateFormatter  {
        
        struct Singleton {
            static let dateFormatter = Singleton.generateDateFormatter()
            
            static func generateDateFormatter() -> NSDateFormatter {
                var formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-mm-dd"
                
                return formatter
            }
        }
        
        return Singleton.dateFormatter
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }

}