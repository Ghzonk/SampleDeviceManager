//
//  DeviceCellViewModel.swift
//  JnJCodingChallenge
//
//  Created by Justin Hur on 6/28/17.
//  Copyright © 2017 Jong Hur. All rights reserved.
//

import Foundation
import UIKit
import CoreData

import Alamofire


class DeviceCellViewModel {
    let model: DeviceModel
    
    let deviceDescription: String
    let checkOutStatus: String
    let checkOutStatusColor: UIColor
    
    
    ///
    /// Initializer using device model
    ///
    init? (withDeviceModel m:DeviceModel?) {
        guard let device = m?.device
            , let os = m?.os
            else {
                return nil
        }
        
        model = m!
        
        self.deviceDescription = String("\(device) - \(os)")
        
        if model.isCheckedOut {
            if let checkedOutBy = model.lastCheckedOutBy {
                checkOutStatus = "Checked out by \(checkedOutBy)"
                checkOutStatusColor = UIColor.red
            }
            else {
                checkOutStatus = "Checked out by Unknown Person"
                checkOutStatusColor = UIColor.orange
            }
        }
        else {
            checkOutStatus = "Available"
            checkOutStatusColor = UIColor.blue
        }
    }
}
