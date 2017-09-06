//
//  DeviceViewModel.swift
//  JnJCodingChallenge
//
//  Created by Justin Hur on 7/2/17.
//  Copyright © 2017 Jong Hur. All rights reserved.
//

import Foundation
import CoreData
import Alamofire
import SwiftyJSON


/// This class handles all server request for Device object with synchronization logics.
/// Synchorization is done in local storage using CoreData.
class DeviceSynchronizedRequest {

    
    // MARK: - Adding a New Device to Server and Local Storage
    
    ///
    /// Adds a new device to Server and syncronize to local storage.
    /// If server is not available, just adds it to the local storage for future synchronization.
    /// Complete is True if it was successful either server or local storage. False if it fails to add in both locations.
    ///
    func addNewDevice(forDevice device: String,
                      withOS os: String,
                      byManufacturer manufacturer: String,
                      complete: @escaping (Bool, DeviceModel) -> ())
    {
        if Reachability.isConnectedToNetwork() {
            let url = Constants.serverUrl + "/devices"
            let params: Parameters = [Constants.Fields.device : device,
                                      Constants.Fields.os : os,
                                      Constants.Fields.manufacturer : manufacturer]
            
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.default).responseJSON { response in
                let success: Bool
                let deviceObject: DeviceModel
                
                switch response.result {
                case .success(let value):
                    print("New Device saved to Server successfully. Synchonizing... \(value)")
                    success = true      // Operation considered as successful once we have successs response from server.
                    
                    // We will use input data instead of response data from server
                    // Because server always returns same data for this challenge.
                    
                    //deviceObject = DeviceModel(withJSON: JSON(value))!
                    deviceObject = DeviceModel(device: device, os: os, manufacturer: manufacturer)
                    self.addNewDeviceToLocalStorage(deviceObject, isOfflineMode: false)
                    
                case .failure(let error):
                    print("Failed to save a new device to Server. Saving offline... \(error.localizedDescription)")
                    deviceObject = DeviceModel(device: device, os: os, manufacturer: manufacturer)
                    success = self.addNewDeviceToLocalStorage(deviceObject, isOfflineMode: true)
                    
                }
                
                complete(success, deviceObject)
            }
        }
        else {
            let deviceObject = DeviceModel(device: device, os: os, manufacturer: manufacturer)
            let success = self.addNewDeviceToLocalStorage(deviceObject, isOfflineMode: true)
            complete(success, deviceObject)
        }
        
    }
    
    
    ///
    /// Add a new device to local stroage with an option of synchronized (Online) or marked added (Offline)
    ///
    @discardableResult
    private func addNewDeviceToLocalStorage(_ d: DeviceModel?, isOfflineMode: Bool) -> Bool
    {
        guard let device = d else {
            return false
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: Constants.entityDevice, in: managedContext)!
        let deviceObject = NSManagedObject(entity: entity, insertInto: managedContext) as! Device
        
        deviceObject.id = Int64(device.id)
        deviceObject.device = device.device
        deviceObject.os = device.os
        deviceObject.manufacturer = device.manufacturer
        deviceObject.isCheckedOut = device.isCheckedOut
        deviceObject.lastCheckedOutDate = device.lastCheckedOutDate as NSDate?
        deviceObject.lastCheckedOutBy = device.lastCheckedOutBy
        
        if isOfflineMode {
            deviceObject.offlineOperation = device.offlineOperation
        }
        else {
            deviceObject.offlineOperation = Constants.Operation.synchronized
        }
        
        do {
            try managedContext.save()
            print("New device \(device.id) added to local storage successfully.")
        } catch let error as NSError {
            print("Error while adding a new device \(device.id) to local data: \(error.localizedDescription)")
        }
        
        return true
    }
    
    

    // MARK: - Check-In Device to the Server and Local Storage
    
    
    ///
    /// If network is connected, check in to server, and update local data.
    /// If we are offline, mark the local data as checked in.
    /// Complete is True if it is successfully checked in to either server or local storage. False if both fails.
    ///
    func checkInDevice(_ id: Int, complete: @escaping RequestComplete) {
        if Reachability.isConnectedToNetwork() {
            let url = Constants.serverUrl + "/devices/\(id)"
            let params: Parameters = [Constants.Fields.isCheckedOut : false as Bool]
            
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.default).responseString { response in
                let success:Bool
                
                if response.result.isSuccess {
                    print("New Device is checked in to Server successfully. Synchonizing...")
                    success = true      // Operation considered as successful once we have successs response from server.
                    self.checkInDeviceToLocalStorage(id, isOfflineMode: false)
                }
                else {
                    print("Failed to check-in a device to Server. Saving offline... \(response.result.description)")
                    success = self.checkInDeviceToLocalStorage(id, isOfflineMode: true)
                }

                complete(success)
            }

        }
        else {
            let success = self.checkInDeviceToLocalStorage(id, isOfflineMode: true)
            complete(success)
        }
    }
    
    
    ///
    /// Check-in a device based on its ID with an option of permanant delete (Online) or marked delete (Offline)
    /// After fetching, we only update the first item (assuming id is unique in real world).
    ///
    @discardableResult
    func checkInDeviceToLocalStorage(_ id: Int, isOfflineMode: Bool) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Constants.entityDevice)
        fetchRequest.predicate = NSPredicate(format: "id = \(id)")

        var isUpdated = false
        
        do {
            let devices = try managedContext.fetch(fetchRequest)
            if devices.count == 0 {
                print("Failed to fetch unique device ID, \(id).")
                return false
            }
            
            if isOfflineMode {
                devices[0].setValue(false, forKey: Constants.Fields.isCheckedOut)
                devices[0].setValue(Constants.Operation.checkin, forKey: Constants.Fields.offlineOperation)
            }
            else {
                devices[0].setValue(false, forKey: Constants.Fields.isCheckedOut)
                devices[0].setValue(Constants.Operation.synchronized, forKey: Constants.Fields.offlineOperation)
            }

            try managedContext.save()
            isUpdated = true

            print("Device \(id) checked in to local storage successfully. Offline mode = \(isOfflineMode)")
        }
        catch let error as NSError {
            print("Error while checking in device \(id) to local storage: \(error.localizedDescription)")
            isUpdated = false
        }
        
        return isUpdated
    }
    
    
    
    // MARK: - Check-Out Device from the Server and Local Storage
    
    
    ///
    /// If network is connected, check in to server, and update local data.
    /// If we are offline, mark the local data as checked in.
    /// Complete is True if it is successfully checked in to either server or local storage. False if both fails.
    ///
    func checkOutDevice(_ id: Int, checkOutBy: String, complete: @escaping (Bool, Date) -> ()) {
        if Reachability.isConnectedToNetwork() {
            let url = Constants.serverUrl + "/devices/\(id)"
            
            let currentDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
            let dateString = dateFormatter.string(from: currentDate)
            
            let params: Parameters = [Constants.Fields.lastCheckedOutDate : dateString,
                                      Constants.Fields.lastCheckedOutBy : checkOutBy,
                                      Constants.Fields.isCheckedOut : true as Bool]

            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.default).responseString { response in
                let success:Bool
                
                if response.result.isSuccess {
                    print("New Device is checked out from Server successfully. Synchonizing...")
                    success = true      // Operation considered as successful once we have successs response from server.
                    self.checkOutDeviceFromLocalStorage(id, checkOutBy: checkOutBy, checkOutDate: currentDate, isOfflineMode: false)
                }
                else {
                    print("Failed to check-out a device from Server. Saving offline... \(response.result.description)")
                    success = self.checkOutDeviceFromLocalStorage(id, checkOutBy: checkOutBy, checkOutDate: currentDate, isOfflineMode: true)
                }
                
                complete(success, currentDate)
            }
            
        }
        else {
            let currentDate = Date()
            let success = self.checkOutDeviceFromLocalStorage(id, checkOutBy: checkOutBy, checkOutDate: currentDate, isOfflineMode: true)
            complete(success, currentDate)
        }
    }

    
    ///
    /// Check-out a device based on its ID with an option of permanant delete (Online) or marked delete (Offline)
    /// After fetching, we only update the first item (assuming id is unique in real world).
    ///
    @discardableResult
    func checkOutDeviceFromLocalStorage(_ id: Int, checkOutBy: String, checkOutDate: Date, isOfflineMode: Bool) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Constants.entityDevice)
        fetchRequest.predicate = NSPredicate(format: "id = \(id)")
        
        var isUpdated = false
        
        do {
            let devices = try managedContext.fetch(fetchRequest)
            if devices.count == 0 {
                print("Failed to fetch unique device ID, \(id).")
                return false
            }
            
            if isOfflineMode {
                devices[0].setValue(checkOutBy, forKey: Constants.Fields.lastCheckedOutBy)
                devices[0].setValue(checkOutDate, forKey: Constants.Fields.lastCheckedOutDate)
                devices[0].setValue(true, forKey: Constants.Fields.isCheckedOut)
                devices[0].setValue(Constants.Operation.checkout, forKey: Constants.Fields.offlineOperation)
            }
            else {
                devices[0].setValue(checkOutBy, forKey: Constants.Fields.lastCheckedOutBy)
                devices[0].setValue(checkOutDate, forKey: Constants.Fields.lastCheckedOutDate)
                devices[0].setValue(true, forKey: Constants.Fields.isCheckedOut)
                devices[0].setValue(Constants.Operation.synchronized, forKey: Constants.Fields.offlineOperation)
            }
            
            try managedContext.save()
            isUpdated = true
            
            print("Device \(id) checked out from local storage successfully. Offline mode = \(isOfflineMode)")
        }
        catch let error as NSError {
            print("Error while checking in device \(id) to local storage: \(error.localizedDescription)")
            isUpdated = false
        }
        
        return isUpdated
    }
    
    

    // MARK: - Deleting Device from the Server and Local Storage
    
    
    ///
    /// If network is connected, delete from Server, and delete local data
    /// If we are working offline, mark the local data as deleted.
    /// Complete is True if it successfully deleted from either server or local storage. False if both fails.
    ///
    func deleteDevice(_ id: Int, complete: @escaping RequestComplete) {
        if Reachability.isConnectedToNetwork() {
            let url = Constants.serverUrl + "/devices/\(id)"
            
            Alamofire.request(url, method: .delete).validate().responseJSON { response in
                let success: Bool
                
                switch response.result {
                case .success(let value):
                    print("Data deleted from Server successfully. Synchronizing... \(value)")
                    success = true      // Delete operation is considered successful once we get success response from server
                    self.deleteFromLocalStorage(id, isOfflineMode: false)
                case .failure(let error):
                    print("Failed to delete data from Server. Deleting offline... \(error.localizedDescription)")
                    success = self.deleteFromLocalStorage(id, isOfflineMode: true)
                }
                
                complete(success)
            }
        }
        else {
            let success = deleteFromLocalStorage(id, isOfflineMode: true)
            complete(success)
        }
    }
    
    
    ///
    /// Delete a device based on its ID with an option of permanant delete (Online) or marked delete (Offline)
    /// After fetching, we only delete the first item (assuming id is unique in real world).
    ///
    @discardableResult
    private func deleteFromLocalStorage(_ id: Int, isOfflineMode: Bool) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Constants.entityDevice)
        fetchRequest.predicate = NSPredicate(format: "id = \(id)")
        
        var isDeleted: Bool = false
        
        do {
            let devices = try managedContext.fetch(fetchRequest)
            if devices.count == 0 {
                print("Failed to fetch unique device ID.")
                return false
            }
            
            if isOfflineMode {
                devices[0].setValue(Constants.Operation.delete, forKey: Constants.Fields.offlineOperation)
            }
            else {
                managedContext.delete(devices[0])
            }
            
            try managedContext.save()
            isDeleted = true
            
            print("Device \(id) deleted from local storage successfully. Offline Mode = \(isOfflineMode)")
        }
        catch let error as NSError {
            print("Error while deleting device \(id) from local storage: \(error.localizedDescription)")
            isDeleted = false
        }
        
        return isDeleted
    }


}
