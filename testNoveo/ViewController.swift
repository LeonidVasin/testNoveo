//
//  ViewController.swift
//  testNoveo
//
//  Created by user on 20.04.17.
//  Copyright © 2017 Leonid. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.revealViewController() != nil {
            self.revealViewController().delegate = self
            self.menuBarButton.target = self.revealViewController()
            self.menuBarButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            self.revealViewController().rearViewRevealOverdraw = 0
        }
    }
}

extension ViewController: SWRevealViewControllerDelegate {
    
}

