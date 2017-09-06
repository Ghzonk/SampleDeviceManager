//
//  DeviceTableViewCell.swift
//  JnJCodingChallenge
//
//  Created by Justin Hur on 6/27/17.
//  Copyright © 2017 Jong Hur. All rights reserved.
//

import UIKit

class DeviceTableViewCell: UITableViewCell {

    
    @IBOutlet weak var deviceDescLabel: UILabel!
    @IBOutlet weak var checkOutStatusLabel: UILabel!
    
    
    var viewModel: DeviceCellViewModel? {
        didSet {
            if viewModel == nil {
                return
            }
            
            deviceDescLabel.text = viewModel?.deviceDescription
            checkOutStatusLabel.text = viewModel?.checkOutStatus
            checkOutStatusLabel.textColor = viewModel?.checkOutStatusColor
        }
    }
    
    ///
    /// Changes background color based on network availability
    ///
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        
        if Reachability.isConnectedToNetwork() {
            self.backgroundColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.1)
        }
        else {
            self.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.1)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
