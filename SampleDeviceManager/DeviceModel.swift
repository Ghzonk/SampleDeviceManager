//
//  DeviceModel.swift
//  JnJCodingChallenge
//
//  Created by Justin Hur on 6/27/17.
//  Copyright © 2017 Jong Hur. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON


class DeviceModel {
    let id: Int
    let device: String
    let os: String
    let manufacturer: String
    
    var isCheckedOut: Bool
    var lastCheckedOutDate: Date?
    var lastCheckedOutBy: String?
    
    var offlineOperation:String?
    
    
    ///
    /// Initializes if we have all required values in JSON data, or returns nil
    /// SwiftyJSON Optional Getters are named as type
    ///
    init? (withJSON json:JSON) {
        guard let id = json[Constants.Fields.id].int
            , let device = json[Constants.Fields.device].string
            , let os = json[Constants.Fields.os].string
            , let manufacturer = json[Constants.Fields.manufacturer].string
            , let isCheckedOut = json[Constants.Fields.isCheckedOut].bool
            else {
                return nil
        }

        self.id = id
        self.device = device
        self.os = os
        self.manufacturer = manufacturer
        self.isCheckedOut = isCheckedOut

        if let stringDate = json[Constants.Fields.lastCheckedOutDate].string {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
            self.lastCheckedOutDate = dateFormatter.date(from: stringDate)
        }
        else {
            self.lastCheckedOutDate = nil
            
            //We can print an error to console by using SwiftyJSON error property
            //print(json["lastCheckedOutDate"].error!)
        }
        
        self.lastCheckedOutBy = json[Constants.Fields.lastCheckedOutBy].string
        
        self.offlineOperation = Constants.Operation.synchronized
    }
    
    
    ///
    /// Initializes with NSManagedObject from Local Data Storage
    /// NSManagedObject getters
    ///
    init? (withManagedObject object:NSManagedObject) {
        guard let id = object.value(forKey: Constants.Fields.id) as? Int
            , let device = object.value(forKey: Constants.Fields.device) as? String
            , let os = object.value(forKey: Constants.Fields.os) as? String
            , let manufacturer = object.value(forKey: Constants.Fields.manufacturer) as? String
            , let isCheckedOut = object.value(forKey: Constants.Fields.isCheckedOut) as? Bool
            else {
                return nil
        }
        
        self.id = id
        self.device = device
        self.os = os
        self.manufacturer = manufacturer
        self.isCheckedOut = isCheckedOut
        
        self.lastCheckedOutDate = object.value(forKey: Constants.Fields.lastCheckedOutDate) as? Date
        self.lastCheckedOutBy = object.value(forKey: Constants.Fields.lastCheckedOutBy) as? String
        
        self.offlineOperation = object.value(forKey: Constants.Fields.offlineOperation) as? String
    }
    
    
    ///
    /// Special initializer for Add New Device offline operation
    ///
    init (device: String, os: String, manufacturer: String) {
        self.id = Int(arc4random())
        self.device = device
        self.os = os
        self.manufacturer = manufacturer
        self.isCheckedOut = false
        
        self.lastCheckedOutDate = nil
        self.lastCheckedOutBy = nil
        self.offlineOperation = Constants.Operation.add
    }
    
    
}
