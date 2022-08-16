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
    var initialPageIndex: Int?
    @IBOutlet weak var searchBar: UISearchBar!
    var searchText: String = "" {
        didSet {
            if searchText.isEmpty {
                episodeMatches.removeAll()
                return
            }
            findEpisodeMatches()
        }
    }
    
    var episodeMatches: [Int] = []
    
    func findEpisodeMatches() {
        episodeMatches.removeAll()
        let searchFor = [searchText.lowercased()]
        for i in 0..<Assets.titles.count {
            for j in searchFor {
                if Assets.titles[i].lowercased().contains(j) || Assets.numbers[i].contains(j) || Assets.dates[i].contains(j) {
                    episodeMatches.append(i)
                    break
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = ""
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

        if DetailViewController.lastLoadedEpisode == -1 {
            let episodeId = UserDefaults.standard.integer(forKey: "lastEpisodeId")
            initialPageIndex = UserDefaults.standard.integer(forKey: "lastPageIndex")
            tableView.selectRow(at: IndexPath(indexes: [0, episodeId]), animated: false, scrollPosition: .middle)
            performSegue(withIdentifier: "showDetail", sender: navigationController)
        } else {
            tableView.selectRow(at: IndexPath(indexes: [0, DetailViewController.lastLoadedEpisode]), animated: false, scrollPosition: .middle)
            if let split = splitViewController {
                split.toggleMasterView()
            }
        }
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        navigationItem.leftBarButtonItem = nil // UIBarButtonItem(customView: searchBar)
        navigationItem.rightBarButtonItem = nil
        navigationItem.titleView = searchBar
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
                if searchText.isEmpty {
                    controller.episodeId = indexPath.row
                } else {
                    controller.episodeId = episodeMatches[indexPath.row]
                }
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                
                if let initialPageIndex = initialPageIndex {
                    controller.initialPageIndex = initialPageIndex
                    self.initialPageIndex = nil
                } else {
                    if controller.episodeId == DetailViewController.lastLoadedEpisode {
                        controller.initialPageIndex = OnePageController.lastLoadedIndex
                    } else if let previouslyLoaded = DetailViewController.previouslyLoaded,
                              controller.episodeId == previouslyLoaded.0 {
                        controller.initialPageIndex = previouslyLoaded.1
                    } else {
                        controller.initialPageIndex = 0
                    }
                    if let split = splitViewController {
                        split.toggleMasterView()
                    }
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchText.isEmpty {
            return Assets.titles.count
        } else {
            return episodeMatches.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let episodeId: Int
        if searchText.isEmpty {
            episodeId = indexPath.row
        } else {
            episodeId = episodeMatches[indexPath.row]
        }
        var title = "\(Assets.numbers[episodeId]). \(Assets.titles[episodeId])"
        let progress = AppDelegate.episodeDownloader.progress(forEpisode: episodeId)
        if progress != -1 {
            title += " (\(progress)%)"
        }
        cell.textLabel!.text = title
        
        return cell
    }

}

extension MasterViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        tableView.reloadData()
        updateRowSelection(self.searchText.isEmpty ? .middle : .none)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchText = ""
        tableView.reloadData()
        updateRowSelection(.middle)
    }
    
    func updateRowSelection(_ position: UITableView.ScrollPosition) {
        guard DetailViewController.lastLoadedEpisode != -1 else {
            return
        }
        let selectedId = DetailViewController.lastLoadedEpisode
        if searchText == "" {
            tableView.selectRow(at: IndexPath(indexes: [0, selectedId]), animated: true, scrollPosition: position)
        } else {
            for i in 0..<episodeMatches.count {
                if episodeMatches[i] == selectedId {
                    tableView.selectRow(at: IndexPath(indexes: [0, i]), animated: true, scrollPosition: position)
                }
            }
        }
    }
}
