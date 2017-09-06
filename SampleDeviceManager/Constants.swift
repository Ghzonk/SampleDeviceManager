//
//  Constants.swift
//  JnJCodingChallenge
//
//  Created by Justin Hur on 7/1/17.
//  Copyright © 2017 Jong Hur. All rights reserved.
//

import Foundation


typealias RequestComplete = (Bool) -> ()


struct Constants {
    static let serverUrl = "http://private-1cc0f-devicecheckout.apiary-mock.com"
    
    static let entityDevice = "Device"
    
    struct Fields {
        static let id = "id"
        static let device = "device"
        static let os = "os"
        static let manufacturer = "manufacturer"
        static let isCheckedOut = "isCheckedOut"
        static let lastCheckedOutBy = "lastCheckedOutBy"
        static let lastCheckedOutDate = "lastCheckedOutDate"
        static let offlineOperation = "offlineOperation"
    }
    
    struct Operation {
        static let add = "add"
        static let checkin = "checkin"
        static let checkout = "checkout"
        static let delete = "delete"
        static let synchronized = ""
    }
    
}
