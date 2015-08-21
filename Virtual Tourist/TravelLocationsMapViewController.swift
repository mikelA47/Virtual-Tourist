//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by mikel lizarralde cabrejas on 29/7/15.
//  Copyright (c) 2015 mikel lizarralde cabrejas. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class TravelLocationsMapViewController: UIViewController,MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    var pins = [Pin]()
    var selectedPin:Pin!
    var poweredPins = [Int:Pin]() //Hash dictionary to organize annotations with their pins
    
    var map = [Map]() //New entity to exceed expectations 21/08/2015
    
    var firstDrop = true
    var longPressGestureRecognizer:UILongPressGestureRecognizer!
    
    var annotationsToRemove = [MKPointAnnotation]()
    var annotation = MKPointAnnotation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
        //self.restoreMapRegion() // restore map info
     /*   map.append(Map(latitude: -2.934251, longitude: 43.266574, zoom: 50000000, context: self.sharedContext))
        self.map = self.fetchMap()
        if self.map.count == 0 {
            //If there is no map saved, center to Bilbao like tha app On the Map
            //map.append(Map(latitude: -2.934251, longitude: 43.266574, zoom: 50000000, context: self.sharedContext))
        }
        self.mapView.centerCoordinate = CLLocationCoordinate2D(latitude: self.map[0].latitude,
            longitude: self.map[0].longitude)
        self.mapView.camera.altitude = self.map[0].zoom*/
        println(1)
        map = fetchMap()
        println(2)
        if map.count == 0 {
                    println(3)
           // map.append(Map(latitude: Double(-3.831239), longitude: Double(-78.183406), zoom: 50000000, context: self.sharedContext))
           // self.map.append(Map(latitude: -3.831239, longitude: -78.183406, zoom: 50000, context: self.sharedContext))
            self.map[0].latitude = self.mapView.centerCoordinate.latitude
            self.map[0].longitude = self.mapView.centerCoordinate.longitude
            self.map[0].zoom = self.mapView.camera.altitude
                    println(4)
        }
        
        //Sets the map zoom.
        //self.mapView?.camera.altitude = map[0].zoom
        
        //Sets the center of the map.
        //self.mapView?.centerCoordinate = CLLocationCoordinate2D(latitude: map[0].latitude, longitude: map[0].longitude)
        
        self.mapView.delegate = self
        self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "action:")
        self.longPressGestureRecognizer.minimumPressDuration = 2
        self.view.addGestureRecognizer(self.longPressGestureRecognizer)
        self.fetchedResultsController.performFetch(nil)

        self.fechedPins()
        
    }
    
    //Loads map state

    func fetchMap() -> [Map] {
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Map")
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        if error != nil {
            println("Error in fetchMap(): \(error)")
        }
        
        return results as! [Map]
    }
    
    func restoreMapRegion()
    {
        self.map = self.fetchMap()
        if self.map.count != 0 {
            self.mapView.centerCoordinate = CLLocationCoordinate2D(latitude: self.map[0].latitude,
                longitude: self.map[0].longitude)
            self.mapView.camera.altitude = self.map[0].zoom
        } else {
            //If there is no map saved, center to Bilbao like tha app On the Map
            map.append(Map(latitude: -2.934251, longitude: 43.266574, zoom: 50000000, context: self.sharedContext))
        }
    }
    
    func fechedPins()
    {
        let sectionInfo = self.fetchedResultsController.sections![0] as! NSFetchedResultsSectionInfo

        if  !sectionInfo.objects.isEmpty{
            self.pins = sectionInfo.objects as! [Pin]
            for pin in pins{
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: Double(pin.latitude), longitude: Double(pin.longitude))
                self.poweredPins[annotation.hash] = pin
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.toolbarHidden = true
    }
    
    //Core data
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil,cacheName: nil)
        return fetchedResultsController
        
    }()
    
    func action(sender: UILongPressGestureRecognizer)
    {
        if (sender.state == .Began) //finger touched screen long enough
        {
            var annotation = MKPointAnnotation()
            self.firstDrop = true
            let point:CGPoint = sender.locationInView(self.mapView)
            var tapPoint:CLLocationCoordinate2D = mapView.convertPoint(point, toCoordinateFromView: self.mapView)
            annotation.coordinate = tapPoint
            self.mapView.addAnnotation(annotation)
            self.annotation = annotation
            annotationsToRemove.append(annotation)
            
        } else if (sender.state == .Changed){ //finger is moving
            var annotation = MKPointAnnotation()
            self.firstDrop = false
            self.mapView.removeAnnotations(annotationsToRemove) //if we are dragging pin, delete old one, create new one with new position and put it on th array for next time to be removed and a new one created...infinite loop until the finger is lifted
            let point:CGPoint = sender.locationInView(self.mapView)
            var tapPoint:CLLocationCoordinate2D = mapView.convertPoint(point, toCoordinateFromView: self.mapView)
            annotation.coordinate = tapPoint
            self.mapView.addAnnotation(annotation)
            annotationsToRemove.append(annotation)
            self.annotation = annotation
            
        } else if (sender.state == .Ended){ //finger is lifted
            self.firstDrop = false
            self.selectedPin = Pin(dictionary: ["latitude":self.annotation.coordinate.latitude,"longitude":self.annotation.coordinate.longitude], context: sharedContext)
            
            FlickrClient.sharedInstance().searchPicturesForPin(self.selectedPin) { (success,picturesArray, errorString) in
            //same as done in newCollectionButtonPressed() function or the other way arround
                if success {
                    if let pictures = picturesArray{
                        for picture in pictures{
                            let picture_ = Photo(dictionary: ["title":picture[0],"path":picture[1]], context: self.sharedContext)
                            picture_.pin = self.selectedPin
                        }
                    }
                    CoreDataStackManager.sharedInstance().saveContext()
                    let detailController = self.storyboard!.instantiateViewControllerWithIdentifier("PictureCollection")! as! PictureCollectionViewController
                    //pass the pin selected
                    detailController.pin = self.selectedPin
                    self.poweredPins[self.annotation.hash] = self.selectedPin
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationController!.pushViewController(detailController, animated: true)
                    }
                    //leave map untoched and restart "buffer" for drgaging pin
                    self.mapView.deselectAnnotation(self.annotation, animated: false)
                    self.annotationsToRemove = []
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.mapView.removeAnnotation(self.annotation)
                        CoreDataStackManager.sharedInstance().deleteObject(self.selectedPin)
                        println(errorString!) //No pictures to download
                    })
                }
            }
        }
    }
    
    //MARK: MapView Related
    
    //Select pin
    /**************** I think the problem was here ********** Download pictures when selected a pin if there are no pictures
        don´t rely on prefeched pictures alone
    */
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        let detailController = self.storyboard!.instantiateViewControllerWithIdentifier("PictureCollection")! as! PictureCollectionViewController
        if let pin_ = self.poweredPins[view.annotation.hash]{
            detailController.pin = pin_
            self.selectedPin = pin_
            if let pictures = pin_.photos{
                if pictures.isEmpty { //No pictures? download new ones
                    FlickrClient.sharedInstance().searchPicturesForPin(self.selectedPin) { (success,picturesArray, errorString) in
                        if success {
                            dispatch_async(dispatch_get_main_queue()) {
                                detailController.pin = pin_
                                if let pictures = picturesArray{
                                    for picture in pictures{
                                        let picture_ = Photo(dictionary: ["title":picture[0],"path":picture[1]], context: self.sharedContext)
                                        picture_.pin = self.selectedPin
                                    }
                                }
                                CoreDataStackManager.sharedInstance().saveContext()
                                self.navigationController!.pushViewController(detailController, animated: true)
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.mapView.removeAnnotation(view.annotation)
                                CoreDataStackManager.sharedInstance().deleteObject(self.selectedPin)
                                println(errorString!)//No pictures
                            })
                        }
                    }
                }else{
                    self.navigationController!.pushViewController(detailController, animated: true)
                }
            }
        }
        self.mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    //Config pin
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if annotation is MKPointAnnotation {
            let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
            pin.pinColor = .Red //I like it that way
            pin.canShowCallout = false
            pin.draggable = false
            if firstDrop {
                pin.animatesDrop = true
            } else {
                pin.animatesDrop = false
            }
            return pin
        }
        return nil
    }

    //Saves map state
    
    func saveMapRegion2() {
        self.map[0].latitude = self.mapView.centerCoordinate.latitude
        self.map[0].longitude = self.mapView.centerCoordinate.longitude
        self.map[0].zoom = self.mapView.camera.altitude
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    //************************ iOS persistance code example **********************************//
    
    // MARK: - Save the zoom level helpers

    // Here we use the same filePath strategy as the Persistent Master Detail
    // A convenient property
 /*   var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }

    func saveMapRegion() {

        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.

        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
            ]

            // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }

    func restoreMapRegion() {

        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {

            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)

            let savedRegion = MKCoordinateRegion(center: center, span: span)

            println("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")

            mapView.setRegion(savedRegion, animated: false)
        }
    }
    */

    }

    /**
    *  This extension comforms to the MKMapViewDelegate protocol. This allows
    *  the view controller to be notified whenever the map region changes. So
    *  that it can save the new region.
    */

    extension TravelLocationsMapViewController : MKMapViewDelegate {

        func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
            saveMapRegion2()
        }
    }