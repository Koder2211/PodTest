//
//  ViewController.swift
//  PodTest
//
//  Created by Santosh Surve on 5/17/16.
//  Copyright © 2016 mindscrub. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    class Image : NSObject {    //all NSObjects in Kinvey implicitly implement KCSPersistable
        var entityId: String! //Kinvey entity _id
        var image: UIImage!
        var senderUsername: KCSUser!
        var recipientUsername: String!
        var metadata: KCSMetadata? //= nil //Kinvey metadata, optional
        
        override func hostToKinveyPropertyMapping() -> [NSObject : AnyObject]! {
            return [
                "entityId" : KCSEntityKeyId, //the required _id field
                "image" : "image",
                "senderUsername" : "senderUsername",
                "recipientUsername" : "recipientUsername",
                "metadata" : KCSEntityKeyMetadata //optional _metadata field
            ]
        }
        
        override class func kinveyPropertyToCollectionMapping() -> [NSObject : AnyObject]! {
            
            return [
                "senderUsername" : KCSUserCollectionName,
                "image" : "_blob"
            ]
        }
        
    }

    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        KCSUser.loginWithUsername(
            "mind1",
            password: "mind1",
            withCompletionBlock: { (user: KCSUser!, errorOrNil: NSError!, result: KCSUserActionResult) -> Void in
                if errorOrNil == nil {
                    //the log-in was successful and the user is now the active user and credentials saved
                    //hide log-in view and show main app content
                    KCSUser.activeUser()
                    
                    
                    // Upload to Kinvey
                    var collection = KCSCollection(fromString: "Images", ofClass:Image.self)
                    
                    var imageToSend = KCSLinkedAppdataStore.storeWithOptions([
                        KCSStoreKeyResource : collection ,
                        KCSStoreKeyCachePolicy : KCSCachePolicy.NetworkFirst.rawValue,
                        KCSStoreKeyOfflineUpdateEnabled : true
                        ])
                    
                    let imageSendingData = Image()
                    imageSendingData.image = UIImage(named: "1-13.jpg")
                    // = UIImage(data: UIImageJPEGRepresentation(image, 0.5)!)
                    imageSendingData.senderUsername = KCSUser.activeUser()
                    print(KCSUser.activeUser().username)
                    imageSendingData.recipientUsername = "pranav"
                    imageSendingData.metadata = KCSMetadata()
                    imageSendingData.metadata!.setGloballyReadable(true)
                    imageSendingData.metadata!.setGloballyWritable(true)
                    
                    imageToSend.saveObject(imageSendingData, withCompletionBlock: { (objectsOrNil, errorOrNil) -> Void in
                        
                        if errorOrNil != nil {
                            
                            print("Error saving image: \(errorOrNil)")
                            
                        } else {
                            
                            print("Save image successful")
                            let newImage = objectsOrNil[0] as! Image
                            
                            // PRANAV COMMENTS
                            // 1. If I just use the KCSLinkedAppdataStore below without Cache policy options, it works fine (referenced KCSUser object is also fetched fine).
                            // 2. If I use the KCSLinkedAppdataStore with Cache policy options (NetworkFirst), I see a crash with 'NSInvalidArgumentException', reason: 'Invalid type in JSON write (KCSUser)'
                            // 3. If I use KCSCachedStore with NetworkFirst cache policy, then the query gets the data from Image collection but the referenced KCSUser object is NOT fetched fine..I think it just gets the _kinveyref dictionary).
                            // 4. How do I use the KCSCachedStore.queryxxx() when there is a referenced object involved?
                            
                            //var imageSendCache = KCSLinkedAppdataStore.storeWithOptions([
                            var imageSendCache = KCSCachedStore.storeWithOptions([
                                KCSStoreKeyResource : collection,
                                KCSStoreKeyCachePolicy : KCSCachePolicy.NetworkFirst.rawValue,
                                KCSStoreKeyOfflineUpdateEnabled : true
                                ])
                            let query = KCSQuery(onField: "_id",  withExactMatchForValue: newImage.entityId )
                            
                            //get all the items back as "DataClass" objects
                            //imageToSend.queryWithQuery(
                            imageSendCache.queryWithQuery(
                                query,
                                withCompletionBlock: { (objectsOrNil: [AnyObject]!, errorOrNil: NSError!) -> Void in
                                    //objectsOrNil will be the imported data
                                    if (errorOrNil == nil) {
                                        var objects = objectsOrNil as! [Image]
                                        
                                        for var obj in objects {
                                            var abc = obj.senderUsername as! KCSUser
                                            //print(abc.username)
                                            //print(abc.valueForKey("_id"))
                                            
                                            // Note: the received object is not in KCSUser format, if we use KCSCachedStore.
                                            // Note: If we use KCSLinkedAppdataStore, then received object is in proper KCSUser format
                                            
                                            
                                        }
                                        //print(objects)
                                    } else {
                                        print(errorOrNil.localizedDescription)
                                    }
                                },
                                withProgressBlock: nil
                                //cachePolicy: KCSCachePolicy.Both
                            )
                            
                        }
                        
                        }, withProgressBlock: nil)

                    
                    
                    
                    
                } 
            }
        )

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

