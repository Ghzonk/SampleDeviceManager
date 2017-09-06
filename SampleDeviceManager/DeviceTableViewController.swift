//
//  DeviceTableViewController.swift
//  JnJCodingChallenge
//
//  Created by Justin Hur on 6/27/17.
//  Copyright © 2017 Jong Hur. All rights reserved.
//

import UIKit

class DeviceTableViewController: UITableViewController {

    
    var viewModel: DeviceTableViewModel = DeviceTableViewModel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.requestGet(completion: {
            self.tableView.reloadData()
        })        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.deviceModelArray.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath) as! DeviceTableViewCell

        cell.viewModel = viewModel.getDeviceCellViewModel(atIndex: indexPath.row)
        return cell
    }


    ///
    /// Override to support editing the table view for deletion and insertion.
    ///
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Confirmation Alert
            let alert = UIAlertController(title: "Delete Device", message: "Are you sure you want to delete?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action: UIAlertAction!) in
                
                self.viewModel.deleteDevice(at: indexPath.row, completed: {(success) in
                    if success {
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                    else {
                        print("Error while removing a Device from the list.")
                    }
                })
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            self.present(alert, animated: true, completion: nil)
        }
        else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            print("editing style = insert")
        }
    }

    
    ///
    /// Insert newly added device into the table
    ///
    func appendDevice(device: DeviceModel) {
        self.viewModel.deviceModelArray.append(device)
        
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: self.viewModel.deviceModelArray.count-1, section: 0)], with: .automatic)
        tableView.endUpdates()
    }
    
    
    // MARK: - Navigation

    ///
    /// In a storyboard-based application, you will often want to do a little preparation before navigation
    ///
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetailSegue" {
            guard let detailVC = segue.destination as? DetailViewController else { return }
            guard let index = tableView.indexPathForSelectedRow?.row else { return }
            
            detailVC.viewModel = DetailViewModel(withDeviceModel: self.viewModel.deviceModelArray[index])
        }
    }
    

}
