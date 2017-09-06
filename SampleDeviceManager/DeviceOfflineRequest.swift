//
//  DeviceOfflineRequest.swift
//  JnJCodingChallenge
//
//  Created by Justin Hur on 7/3/17.
//  Copyright © 2017 Jong Hur. All rights reserved.
//

import Foundation
import CoreData
import Alamofire
import SwiftyJSON


/// This class handles all server request for Device object with synchronization logics.
/// Synchorization is done in local storage using CoreData.
class DeviceOfflineRequest {
    
    
    ///
    /// Adds a new device to Server and syncronize to local storage.
    /// If server is not available, just adds it to the local storage for future synchronization.
    /// Complete is True if it was successful either server or local storage. False if it fails to add in both locations.
    ///
    func addNewDevice(_ device: String,
                      withOS os: String,
                      byManufacturer manufacturer: String,
                      complete: @escaping (Bool) -> ())
    {
        if Reachability.isConnectedToNetwork() {
            let url = Constants.serverUrl + "/devices"
            let params: Parameters = [Constants.Fields.device : device,
                                      Constants.Fields.os : os,
                                      Constants.Fields.manufacturer : manufacturer]
            
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.default).responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("New Device saved to Server successfully. Synchonizing... \(value)")
                    complete(true)
                    
                case .failure(let error):
                    print("Failed to save a new device to Server. Saving offline... \(error.localizedDescription)")
                    complete(false)
                }
            }
        }        
    }

    
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
                if response.result.isSuccess {
                    print("New Device is checked in to Server successfully. Synchonizing...")
                    complete(true)
                }
                else {
                    print("Failed to check-in a device to Server. Saving offline... \(response.result.description)")
                    complete(false)
                }
            }
        }
    }

    
    ///
    /// If network is connected, check in to server, and update local data.
    /// If we are offline, mark the local data as checked in.
    /// Complete is True if it is successfully checked in to either server or local storage. False if both fails.
    ///
    func checkOutDevice(_ id: Int, checkOutBy: String, checkOutDate: Date, complete: @escaping (Bool) -> ()) {
        if Reachability.isConnectedToNetwork() {
            let url = Constants.serverUrl + "/devices/\(id)"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
            let dateString = dateFormatter.string(from: checkOutDate)
            
            let params: Parameters = [Constants.Fields.lastCheckedOutDate : dateString,
                                      Constants.Fields.lastCheckedOutBy : checkOutBy,
                                      Constants.Fields.isCheckedOut : true as Bool]
            
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.default).responseString { response in
                if response.result.isSuccess {
                    print("New Device is checked out from Server successfully. Synchonizing...")
                    complete(true)
                }
                else {
                    print("Failed to check-out a device from Server. Saving offline... \(response.result.description)")
                    complete(false)
                }
            }
            
        }
    }

    
    ///
    /// If network is connected, delete from Server, and delete local data
    /// If we are working offline, mark the local data as deleted.
    /// Complete is True if it successfully deleted from either server or local storage. False if both fails.
    ///
    func deleteDevice(_ id: Int, complete: @escaping RequestComplete) {
        if Reachability.isConnectedToNetwork() {
            let url = Constants.serverUrl + "/devices/\(id)"
            
            Alamofire.request(url, method: .delete).validate().responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("Data deleted from Server successfully. Synchronizing... \(value)")
                    complete(true)

                case .failure(let error):
                    print("Failed to delete data from Server. Deleting offline... \(error.localizedDescription)")
                    complete(false)
                }
            }
        }
    }

    
    
    
    
    
}
