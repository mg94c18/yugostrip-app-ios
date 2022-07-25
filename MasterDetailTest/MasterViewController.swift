//
//  MasterViewController.swift
//  MasterDetailTest
//
//  Created by Stevanovic, Sasa on 1/22/19.
//  Copyright © 2019 Stevanovic, Sasa. All rights reserved.
//

import UIKit

// https://stackoverflow.com/questions/27243158/hiding-the-master-view-controller-with-uisplitviewcontroller-in-ios8
extension UISplitViewController {
    func toggleMasterView() {
        let barButtonItem = self.displayModeButtonItem
        if let action = barButtonItem.action {
            UIApplication.shared.sendAction(action, to: barButtonItem.target, from: .none, for: .none)
        }
    }
}

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        if let split = splitViewController {
            // na starom iPad radi polovično: ugasi otvaranje, ali ne ugasi zatvaranje
            // kad je side panel otvoren a probam da mrdam po slici, ima crash
            split.presentsWithGesture = false
            // takođe ne radi
            // https://stackoverflow.com/questions/13715250/uisplitviewcontroller-presentswithgesture-not-working
            // navigationController?.interactivePopGestureRecognizer?.isEnabled = false

            split.preferredDisplayMode = .secondaryOnly

            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }

        // Ovo izgleda nekad radi, nekad ne
        //performSegue(withIdentifier: "showDetail", sender: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = false
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.episodeId = indexPath.row
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                
                if let split = splitViewController {
                    split.toggleMasterView()
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Assets.titles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel!.text = "\(Assets.numbers[indexPath.row]). \(Assets.titles[indexPath.row])"
        return cell
    }

}

