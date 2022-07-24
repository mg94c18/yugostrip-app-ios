//
//  DetailViewController.swift
//  MasterDetailTest
//
//  Created by Stevanovic, Sasa on 1/22/19.
//  Copyright © 2019 Stevanovic, Sasa. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var pageView: UIView!

    var color: UIColor?
    var pageController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        pageView.backgroundColor = .black
        
        if let onePageController = storyboard?.instantiateViewController(withIdentifier: "OnePageController") as? OnePageController {
            onePageController.color = color
            // TODO: treba da ima samo jedan child, tako da ne "add"
            self.addChildViewController(onePageController)
            self.pageView.addSubview(onePageController.view)
            onePageController.view.frame = pageView.bounds
            onePageController.didMove(toParentViewController: self)
            
            pageController = onePageController
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

