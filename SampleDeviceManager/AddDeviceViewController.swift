//
//  AddDeviceViewController.swift
//  JnJCodingChallenge
//
//  Created by Justin Hur on 7/1/17.
//  Copyright © 2017 Jong Hur. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON


class AddDeviceViewController: UIViewController {

    @IBOutlet weak var deviceText: UITextField!
    @IBOutlet weak var osText: UITextField!
    @IBOutlet weak var manufacturerText: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    ///
    /// Saves a new device to sever and local storage, then return to previous view.
    /// If there is missing information, it will notify user.
    ///
    @IBAction func saveNewDevice(_ sender: UIBarButtonItem) {
        // Validate entries and show alert if information is missing
        if !deviceText.hasText || !osText.hasText || !manufacturerText.hasText {
            let alert = UIAlertController(title: "Incomplete", message: "Please enter all information.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

            self.present(alert, animated: true, completion: nil)
            return
        }
        
        // Save a new device, and go back to previous view.
        let deviceRequest = DeviceSynchronizedRequest()
        deviceRequest.addNewDevice(forDevice: deviceText.text!, withOS: osText.text!, byManufacturer: manufacturerText.text!, complete: {(complete, device) in
            _ = self.navigationController?.popViewController(animated: true)
            
            if let tableVC = self.navigationController?.viewControllers.last as? DeviceTableViewController {
                tableVC.appendDevice(device: device)
            }
            
        })
    }
    
    
    ///
    /// Cancels adding new device, and go back to previous view.
    /// If there is any information entered, it shows a confirmation alert.
    ///
    @IBAction func cancelAddDevice(_ sender: UIBarButtonItem) {
        if deviceText.hasText || osText.hasText || manufacturerText.hasText {
            // Confirmation Alert
            let alert = UIAlertController(title: "Go Back", message: "All data will be lost. Are you sure?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                _ = self.navigationController?.popViewController(animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    

}
