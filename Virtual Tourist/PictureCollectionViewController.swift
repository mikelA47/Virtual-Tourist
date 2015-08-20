//
//  PictureCollectionViewController.swift
//  Virtual Tourist
//
//  Created by mikel lizarralde cabrejas on 4/8/15.
//  Copyright (c) 2015 mikel lizarralde cabrejas. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PictureCollectionViewController: UIViewController,UICollectionViewDelegate,NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var preLoadedPictures: [Photo]!
    var pin:Pin!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.navigationController?.navigationBarHidden = false
        self.navigationController?.toolbarHidden = false
        self.newCollectionButton.enabled = true //in case
        
        //To-Do: Take out the map capability to interact
        
        self.setPinSelectedToMap()
        //Core Data
        fetchedResultsController.performFetch(nil)
        fetchedResultsController.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.toolbarHidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
    }
    
    // MARK: - Core Data
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    //Core Data
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //Code based on Jason Favourite Actors
    //
    // This is the most interesting method. Take particular note of way the that newIndexPath
    // parameter gets unwrapped and put into an array literal: [newIndexPath!]
    //
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Delete:
                self.collectionView.deleteItemsAtIndexPaths([indexPath!])
            case .Update:
                let cell = self.collectionView.cellForItemAtIndexPath(indexPath!) as! CollectionViewCell
                let picture = controller.objectAtIndexPath(indexPath!) as! Photo
                cell.imageCell.image = picture.image /////////////////////////////
            default:
                return
            }
    }
    
    //MARK: CollectionView - get pictures
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.preLoadedPictures = self.fetchedResultsController.fetchedObjects as! [Photo]
        
        return preLoadedPictures!.count
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CollectionViewCell
        
        //If there is an image assigned to the cell, if not call client to make a request for image
        if let image = NSKeyedUnarchiver.unarchiveObjectWithFile(FlickrClient.sharedInstance().parseImagePath(preLoadedPictures![indexPath.row].path.lastPathComponent)) as? UIImage {
            cell.activityView.stopAnimating() //requirment - stop activity indicator
            cell.activityView.hidesWhenStopped = true //and hide
            cell.imageCell.image = image
        }else{
            cell.activityView.startAnimating()//requirment - start activity indicator
            cell.imageCell.image = UIImage(named: "cellImage") //Default placeholder called cellImage (Udacity app icon?)
            FlickrClient.sharedInstance().requestImageForCell(preLoadedPictures![indexPath.row].path,cell: cell,completionHandler: { (success, errorString) in
                if success {
                    dispatch_async(dispatch_get_main_queue(), {
                        cell.activityView.stopAnimating()//requirment - stop activity indicator
                        cell.activityView.hidesWhenStopped = true//and hide
                    })
                }else{
                    dispatch_async(dispatch_get_main_queue(), {
                        cell.activityView.stopAnimating()//requirment - stop activity indicator
                        cell.activityView.hidesWhenStopped = true//and hide
                    })
                }
            })
        }
        return cell
    }
    
    //requirment - If cell/image selected -> delete
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath){
        let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        CoreDataStackManager.sharedInstance().deleteObject(picture)
    }
    
    //To create a new collection of pictures we do it in three steps. 
    //1.- Try to download another set of pictures
    //If this went right
    //2.- Delete old set of pictures -> 3.- Create new pictures from the ones the client just downloaded and save context
    //4.- Reload collection view
    //If the new download did not go rigth we don´t do anything
    @IBAction func newCollectionPressed(sender: AnyObject) {
        self.newCollectionButton.enabled = false
        FlickrClient.sharedInstance().searchPicturesForPin(pin) { (success,picturesArray, errorString) in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    for picPin in self.pin.photos!{
                        CoreDataStackManager.sharedInstance().deleteObject(picPin)
                    }
                    if let pictures = picturesArray{
                        for picture in pictures{
                            let picture_ = Photo(dictionary: ["title":picture[0],"path":picture[1]], context: self.sharedContext)
                            picture_.pin = self.pin
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    }
                    self.newCollectionButton.enabled = true
                    self.collectionView.reloadData()
                })
            } else {
                self.newCollectionButton.enabled = true
                println(errorString!) //No pictures to download
            }
        }
    }
    
    //Put the received pin on place
    func setPinSelectedToMap(){
        let span = MKCoordinateSpanMake(2, 2)
        var coordinates = CLLocationCoordinate2D(latitude: Double(pin.latitude), longitude: Double(pin.longitude))
        let region = MKCoordinateRegion(center: coordinates, span: span)
        var tempAnnotation = MKPointAnnotation()
        tempAnnotation.coordinate = coordinates
        self.mapView.addAnnotation(tempAnnotation)
        self.mapView.setRegion(region, animated: true)
        self.mapView.camera.altitude = 10000
    }
}


