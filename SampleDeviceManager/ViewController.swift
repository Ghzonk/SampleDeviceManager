//
//  ViewController.swift
//  SampleDeviceManager
//
//  Created by Justin Hur on 9/5/17.
//  Copyright © 2017 jonghur. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        startButton.layer.cornerRadius = 5
        startButton.layer.borderWidth = 2
        startButton.layer.borderColor = self.view.tintColor.cgColor

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

