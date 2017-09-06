//
//  DetailViewModel.swift
//  JnJCodingChallenge
//
//  Created by Justin Hur on 7/2/17.
//  Copyright © 2017 Jong Hur. All rights reserved.
//

import Foundation


class DetailViewModel {
    let model: DeviceModel
    
    let id: Int
    let deviceName: String
    let os: String
    let manufacturer: String
    
    var lastCheckedOutInfo: String
    
    
    ///
    /// Initializer using device model
    ///
    init? (withDeviceModel m:DeviceModel?) {
        guard let id = m?.id
            , let deviceName = m?.device
            , let os = m?.os
            , let manufacturer = m?.manufacturer
            else {
                return nil
        }
        
        model = m!
        
        self.id = id
        self.deviceName = deviceName
        self.os = os
        self.manufacturer = manufacturer
        
        self.lastCheckedOutInfo = ""

        self.updateLastCheckOutInfo(checkedOutBy: model.lastCheckedOutBy, checkedOutDate: model.lastCheckedOutDate)
    }

    
    ///
    /// Check-in by changing check out status
    ///
    func checkIn() {
        model.isCheckedOut = false
    }
    
    
    ///
    /// Check-out by assigning related properties
    ///
    func checkOut(checkedOutBy: String?, checkedOutDate: Date?) {
        model.isCheckedOut = true
        model.lastCheckedOutBy = checkedOutBy
        model.lastCheckedOutDate = checkedOutDate
        
        self.updateLastCheckOutInfo(checkedOutBy: checkedOutBy, checkedOutDate: checkedOutDate)
    }
    
    
    ///
    /// Returns true if device is checked out, false otheriwse.
    ///
    func isCheckedOut() -> Bool {
        return model.isCheckedOut
    }
    
    
    ///
    /// Updates check out information string based on name and date.
    ///
    private func updateLastCheckOutInfo (checkedOutBy: String?, checkedOutDate: Date?) {
        guard let by = checkedOutBy
            , let date = checkedOutDate
            else {
                if self.model.isCheckedOut {
                    self.lastCheckedOutInfo = "Checked out by Unknown Person."
                }
                else {
                    self.lastCheckedOutInfo = ""
                }
                return
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        self.lastCheckedOutInfo = "Last Checked Out:\n\n\(by)\n" + formatter.string(from: date)
    }
}

