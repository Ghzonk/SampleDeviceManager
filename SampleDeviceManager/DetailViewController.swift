//
//  DetailViewController.swift
//  JnJCodingChallenge
//
//  Created by Justin Hur on 7/1/17.
//  Copyright © 2017 Jong Hur. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var osLabel: UILabel!
    @IBOutlet weak var manufacturerLabel: UILabel!
    @IBOutlet weak var lastCheckedOutLabel: UILabel!
    @IBOutlet weak var availableLabel: UILabel!
    
    
    @IBOutlet weak var checkInOutButton: UIButton!
    
    var viewModel: DetailViewModel?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Additional setup after loading the view.
        
        checkInOutButton.layer.cornerRadius = 5
        checkInOutButton.layer.borderWidth = 2
        checkInOutButton.layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        
        refreshView()
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        if let tableVC = self.navigationController?.viewControllers.last as? DeviceTableViewController {
            tableVC.tableView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    ///
    /// Refreshes view components based on view model.
    ///
    func refreshView () {
        if viewModel == nil {
            return
        }
        
        deviceLabel.text = viewModel!.deviceName
        osLabel.text = viewModel!.os
        manufacturerLabel.text = viewModel!.manufacturer
        lastCheckedOutLabel.text = viewModel!.lastCheckedOutInfo
        
        if viewModel!.isCheckedOut() {
            checkInOutButton.setTitle("Check In", for: .normal)
            checkInOutButton.setTitleColor(#colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1), for: .normal)
            
            checkInOutButton.layer.borderColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1).cgColor
            
            availableLabel.isHidden = true
        }
        else {
            checkInOutButton.setTitle("Check Out", for: .normal)
            checkInOutButton.setTitleColor(self.view.tintColor, for: .normal)
            
            checkInOutButton.layer.borderColor = self.view.tintColor.cgColor
            
            availableLabel.isHidden = false
        }
    }
    
    ///
    /// If device is checked out, Check In. Otherwise, check out.
    ///
    @IBAction func checkInOutDevice(_ sender: UIButton) {
        if viewModel == nil { return }
        
        if viewModel!.isCheckedOut() {
            checkInCurrentDevice()
        }
        else {
            checkOutCurrentDevice()
        }
    }
    
    
    ///
    /// Check in current device
    ///
    private func checkInCurrentDevice() {
        if self.viewModel == nil { return }

        let deviceRequest = DeviceSynchronizedRequest()
        deviceRequest.checkInDevice(self.viewModel!.id, complete: {(complete) in
            if complete {
                self.viewModel!.checkIn()
                self.refreshView()
            }
        })
    }
    
    
    ///
    /// Check out current device after entering name.
    ///
    private func checkOutCurrentDevice() {
        if self.viewModel == nil { return }
        
        let alertController = UIAlertController(title: "Enter Your Name", message: "Please enter your full name to check out this device.", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Check Out", style: .default, handler: { alert -> Void in
            let nameField = alertController.textFields![0] as UITextField
            let checkOutBy = nameField.text!
            
            // Check out device here.
            if checkOutBy.characters.count > 0 {
                let deviceRequest = DeviceSynchronizedRequest()
                deviceRequest.checkOutDevice(self.viewModel!.id, checkOutBy: checkOutBy, complete: {(complete, checkOutDate) in
                    if complete {
                        self.viewModel!.checkOut(checkedOutBy: checkOutBy, checkedOutDate: checkOutDate)
                        self.refreshView()
                    }
                })
            }
            else {
                let alertError = UIAlertController(title: "Error", message: "Name cannot be empty.", preferredStyle: .alert)
                alertError.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertError, animated: true, completion: nil)
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter Your Name"
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    

}
