//
//  DeviceTableViewModel.swift
//  JnJCodingChallenge
//
//  Created by Justin Hur on 6/28/17.
//  Copyright © 2017 Jong Hur. All rights reserved.
//

import Foundation
import CoreData

import Alamofire
import SwiftyJSON


class DeviceTableViewModel {

    var isNetworkConnected: Bool

    let managedContext: NSManagedObjectContext
    
    var deviceModelArray: [DeviceModel] = []    // Array to hold DeviceModel objects
    
    
    init() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.managedContext = appDelegate.persistentContainer.viewContext
        
        self.isNetworkConnected = Reachability.isConnectedToNetwork()
        
        //self.deleteAllLocalData()     // to reset local data for testing purpose.
    }
    
    
    ///
    /// Returns ViewModel for Device's Table Cell
    ///
    func getDeviceCellViewModel(atIndex index: Int) -> DeviceCellViewModel? {
        if deviceModelArray.indices.contains(index) {
            return DeviceCellViewModel(withDeviceModel: deviceModelArray[index])
        }
        else {
            return nil
        }
    }
    

    ///
    /// If we have a network conection, we process with URL and execute closure.
    /// Otherwise, get data from local storage (CoreData), and execute closure.
    ///
    func requestGet(completion: @escaping () -> ()) {
        if self.isNetworkConnected {
            let url = Constants.serverUrl + "/devices"

            // Alamofire is used to send request
            Alamofire.request(url, method: .get).validate().responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("Network connected. Data loaded from Server.")

                    // Syncronize previous data if any
                    self.loadServerData(JSON(value))
                    self.syncronizeOfflineData()
                    
                    completion()
                case .failure(let error):
                    // When there is an error, Change to offline & use local data (CoreData)
                    print("Network Error. Data loaded from local storage. \(error.localizedDescription)")
                    
                    self.isNetworkConnected = false
                    self.loadLocalData()
                    
                    completion()
                }
            }
        }
        else {
            print("Network not connected. Data loaded from local storage.")
            self.loadLocalData()
            
            completion()
        }
    }
    
    
    
    // MARK: - Load Data methods (Server and Local)
    
    ///
    /// Loads JSON data from Server into devicesModelArray variable
    /// Then, synchronize all server data to local if local data does not have specific offline operation.
    ///
    private func loadServerData(_ json: JSON) {
        deviceModelArray.removeAll()

        for (_, item):(String, JSON) in json {
            if let deviceModel = DeviceModel(withJSON: item) {
                deviceModelArray.append(deviceModel)

                // Check to see if we have a local data for this device
                synchronizeDataToLocalStorage(deviceModel)
            }
        }
        
        // Check to see if we need to initialize local data with Server Data
        if self.getLocalDataCount() == 0 {
            self.initializeLocalData(json)
        }
    }
    
    
    ///
    /// Loads local CoreData into deviceModelArray variable
    ///
    private func loadLocalData() {
        deviceModelArray.removeAll()

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Constants.entityDevice)
        
        do {
            let devices = try managedContext.fetch(fetchRequest)
            
            for device in devices {
                if let deviceModel = DeviceModel(withManagedObject: device) {
                    self.deviceModelArray.append(deviceModel)
                }
            }
        }
        catch let error as NSError {
            print("Error while fetching data from local storage: \(error.localizedDescription)")
        }        
    }
    
    

    // MARK: - Deleting Device from the Array
    
    ///
    /// If network is connected, delete from Server, and delete local data
    /// If we are working offline, mark the local data as deleted.
    ///
    /// - returns: true if data is deleted either online or offline. It returns false only when idex is out of range.
    ///
    func deleteDevice(at index: Int, completed: @escaping (Bool) -> ()) {
        if !deviceModelArray.indices.contains(index) {
            completed(false)
        }
        
        let device = deviceModelArray[index]
        
        let deviceRequest = DeviceSynchronizedRequest()
        deviceRequest.deleteDevice(device.id, complete: { (success) in
            if success {
                self.deviceModelArray.remove(at: index)
            }
            else {
                print("Error occurred while deleting a device.")
            }
            
            completed(success)
        })
    }
    
    
    
    // MARK: - Core Data methods
    
    ///
    /// Syncronize data that was updated during offline use
    ///
    /// * Case 1: To initialize Local Data for the first time use
    /// * Case 2: Syncronize any locally saved data to Server using offlineOperation field
    /// * Case 3: With multi-user scenario
    ///           When server has updates from other users, this should be syncronized to the local data.
    ///
    private func syncronizeOfflineData() {
        //print("total local data count = \(self.getLocalDataCount())")
        self.loadLocalData()
        
        do {
            // Update server records based on our local data information
            for d in deviceModelArray {
                updateServerData(d, complete: {_ in})
            }
            
            try managedContext.save()
            print("All offline operations successfully synchronized.")
        }
        catch let error as NSError {
            print("Error while fetching data from local storage: \(error.localizedDescription)")
        }

        // Delete any item deleted during offline use
        let fetchRequestDel = NSFetchRequest<NSManagedObject>(entityName: Constants.entityDevice)
        fetchRequestDel.predicate = NSPredicate(format: "offlineOperation = %@", Constants.Operation.delete)
        do {
            let delDevices = try managedContext.fetch(fetchRequestDel)

            for delDevice in delDevices {
                print("Offline delete device \(delDevice.value(forKey: Constants.Fields.id) as! Int)")
                managedContext.delete(delDevice)
            }
            try managedContext.save()
        }
        catch let error as NSError {
            print("Error while deleteing data from local storage: \(error.localizedDescription)")
        }
        // Remove from the Array
        for i in (0 ... deviceModelArray.count - 1).reversed() {
            let dm = deviceModelArray[i]
            if dm.offlineOperation == Constants.Operation.delete {
                self.deviceModelArray.remove(at: i)
            }
        }
        
        // Update other offlineOperation
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Constants.entityDevice)
        fetchRequest.predicate = NSPredicate(format: "offlineOperation != \"\"")

        do {
            let devices = try managedContext.fetch(fetchRequest)
            for device in devices {
                device.setValue(Constants.Operation.synchronized, forKey: Constants.Fields.offlineOperation)
            }
            try managedContext.save()
            print("Offline data synchronized to server successfully.")
        }
        catch let error as NSError {
            print("Error while fetching data from local storage: \(error.localizedDescription)")
        }

    }
    
    
    ///
    /// Update server data based on local data's offline operation information.
    ///
    private func updateServerData(_ device: DeviceModel, complete: @escaping (Bool) -> ()) {
        guard let operation = device.offlineOperation else { return }
        
        let offlineRequest = DeviceOfflineRequest()

        switch operation {
        case Constants.Operation.add:
            offlineRequest.addNewDevice(device.device, withOS: device.os, byManufacturer: device.manufacturer, complete: {(completed) in
                complete(completed)
            })
        case Constants.Operation.checkin:
            offlineRequest.checkInDevice(device.id, complete: {(completed) in
                complete(completed)
            })
        case Constants.Operation.checkout:
            if let checkedOutBy = device.lastCheckedOutBy, let checkedOutDate = device.lastCheckedOutDate {
                offlineRequest.checkOutDevice(device.id, checkOutBy: checkedOutBy, checkOutDate: checkedOutDate, complete: {(completed) in
                    complete(completed)
                })
            }
        case Constants.Operation.delete:
            offlineRequest.deleteDevice(device.id, complete: {(completed) in
                complete(completed)
            })
        default:
            complete(false)
            break
        }
    }
    
    
    ///
    /// Initializes local data storgae with JSON data received from server.
    ///
    private func initializeLocalData(_ json:JSON) {
        let entity = NSEntityDescription.entity(forEntityName: Constants.entityDevice, in: managedContext)!
        
        for (_, item):(String, JSON) in json {
            let device = NSManagedObject(entity: entity, insertInto: managedContext) as! Device

            if let deviceModel = DeviceModel(withJSON: item) {
                device.id = Int64(deviceModel.id)
                device.device = deviceModel.device
                device.os = deviceModel.os
                device.manufacturer = deviceModel.manufacturer
                device.isCheckedOut = deviceModel.isCheckedOut
                device.lastCheckedOutDate = deviceModel.lastCheckedOutDate as NSDate?
                device.lastCheckedOutBy = deviceModel.lastCheckedOutBy
                device.offlineOperation = ""
            }
        }
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Error while initializing local data: \(error.localizedDescription)")
        }
    }
    
    
    
    ///
    /// Syncronize Data to Local Storage if it does not exist.
    /// If data exists in local storage, synchronize check out status and related data.
    ///
    private func synchronizeDataToLocalStorage(_ d: DeviceModel) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Constants.entityDevice)
        fetchRequest.predicate = NSPredicate(format: "id = \(d.id)")

        do {
            let devices = try managedContext.fetch(fetchRequest)
            
            if devices.count == 0 {
                let entity = NSEntityDescription.entity(forEntityName: Constants.entityDevice, in: managedContext)!
                let device = NSManagedObject(entity: entity, insertInto: managedContext) as! Device
    
                device.id = Int64(d.id)
                device.device = d.device
                device.os = d.os
                device.manufacturer = d.manufacturer
                device.isCheckedOut = d.isCheckedOut
                device.lastCheckedOutDate = d.lastCheckedOutDate as NSDate?
                device.lastCheckedOutBy = d.lastCheckedOutBy
                device.offlineOperation = ""

                try managedContext.save()
                print("Local data added for id = \(d.id)")
            }
            else {
                let localOperation = devices[0].value(forKey: Constants.Fields.offlineOperation) as! String
                if localOperation == Constants.Operation.synchronized {
                    devices[0].setValue(d.isCheckedOut, forKey: Constants.Fields.isCheckedOut)
                    devices[0].setValue(d.lastCheckedOutBy, forKey: Constants.Fields.lastCheckedOutBy)
                    devices[0].setValue(d.lastCheckedOutDate, forKey: Constants.Fields.lastCheckedOutDate)

                    try managedContext.save()
                    print("Local data synchronized for id = \(d.id)")
                }
            }
        }
        catch let error as NSError {
            print("Error while synchronizing data to local storage: \(error.localizedDescription)")
        }
    }
    
    
    ///
    /// Returns total number of entities in local data storage
    ///
    /// - returns: total number of entities. When error occurs, return -1 to prevent data initialization.
    ///
    private func getLocalDataCount() -> Int {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Constants.entityDevice)
        
        do {
            return try managedContext.count(for: fetchRequest)
        }
        catch let error as NSError {
            print("Error while fetching data from local storage: \(error.localizedDescription)")
            return -1
        }
    }

    
    ///
    /// This method is to reset local data, used only for Testing Purposes.
    ///
    private func deleteAllLocalData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.entityDevice)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedContext.execute(deleteRequest)
            try managedContext.save()
            
            print("All local data is deleted successfully.")
        }
        catch let error as NSError {
            print("Error while deleting all data from local storage: \(error.localizedDescription)")
        }
    }
    
}
