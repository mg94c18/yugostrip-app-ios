//
//  AppDelegate.swift
//  MasterDetailTest
//
//  Created by Stevanovic, Sasa on 1/22/19.
//  Copyright © 2019 Stevanovic, Sasa. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, EpisodeDownloaderDelegate {
    func progress(forEpisode: Int, changedTo: Int) {
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count - 1] as! UINavigationController
        
        var detail: DetailViewController?
        if let top = navigationController.topViewController as? DetailViewController {
            detail = top
        }
        if let visible = navigationController.visibleViewController as? DetailViewController {
            detail = visible
        }
        if let detail = detail {
            if detail.episodeId == forEpisode {
                detail.progress = changedTo
            } else if changedTo == -1 {
                detail.postInitDownloadButton()
            }
        }

        if let masterNav = splitViewController.viewControllers[0] as? UINavigationController {
            var master: MasterViewController?
            if let top = masterNav.topViewController as? MasterViewController {
                master = top
            }
            if let visible = masterNav.visibleViewController as? MasterViewController {
                master = visible
            }
            if let master = master {
                let selection = master.tableView.indexPathForSelectedRow
                master.tableView.reloadData()
                master.tableView.selectRow(at: selection, animated: false, scrollPosition: .none)
            }
        }
    }
    
    func downloadComplete(forEpisode episode: Int) {
        var downloadedEpisodes = DetailViewController.downloadedEpisodes()
        if let index = downloadedEpisodes.firstIndex(of: episode) {
            // TODO: Log.wtf()
            downloadedEpisodes.remove(at: index)
        }
        downloadedEpisodes.append(episode)
        UserDefaults.standard.set(downloadedEpisodes, forKey: "downloadedEpisodes")
        progress(forEpisode: episode, changedTo: -1)
    }
    
    func downloadFailed(forEpisode e: Int) {
        progress(forEpisode: e, changedTo: -1)
    }

    var window: UIWindow?
    static var inBackground = false
    static var unseenCrashes = 0
    static var unseenCrashesKey = "unseenCrashes"
    static var episodeDownloader = EpisodeDownloader()
    static var canceledEpisodes: [Int] = []

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        AppDelegate.episodeDownloader.delegate = self
 
        AppDelegate.unseenCrashes = UserDefaults.standard.integer(forKey: AppDelegate.unseenCrashesKey)
        UserDefaults.standard.set(3, forKey: AppDelegate.unseenCrashesKey)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AppDelegate.inBackground = true
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if OnePageController.lastLoadedIndex != -1 {
            UserDefaults.standard.set(OnePageController.lastLoadedIndex, forKey: "lastPageIndex")
        }
        if DetailViewController.lastLoadedEpisode != -1 {
            UserDefaults.standard.set(DetailViewController.lastLoadedEpisode, forKey: "lastEpisodeId")
        }
        AppDelegate.canceledEpisodes = AppDelegate.episodeDownloader.cancelAllDownloads()
        DetailViewController.previouslyLoaded = nil
        DispatchQueue.global(qos: .utility).async {
            AppDelegate.cleanupStorage()
        }
        
        UserDefaults.standard.set(0, forKey: AppDelegate.unseenCrashesKey)
    }
    
    static func cleanupStorage() {
        var visited = DetailViewController.loadStoredArray("visitedEpisodes")
        let downloaded = DetailViewController.downloadedEpisodes()
        let paused = AppDelegate.canceledEpisodes
        // TODO: dodati i failed, to jest da ne briše prebzo kad download ne uspe
        
        var vnd: [Int] = [] // visited, not downloaded/downloading
        for v in visited {
            if !downloaded.contains(v) && !paused.contains(v) {
                vnd.append(v)
            }
        }
        if vnd.count <= 5 {
            return
        }
        for i in 0..<vnd.count - 5 {
            let e = vnd[i]
            guard let index = visited.firstIndex(of: e), let dir = EpisodeDownloader.getOrCreateDownloadDir(episode: e) else {
                // TODO: Log.wtf()
                continue
            }
            try? FileManager.default.removeItem(at: dir)
            visited.remove(at: index)
        }
        UserDefaults.standard.set(visited, forKey: "visitedEpisodes")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        AppDelegate.inBackground = false
        for e in AppDelegate.canceledEpisodes {
            DispatchQueue.main.async {
                AppDelegate.episodeDownloader.startDownloading(episode: e)
            }
        }
        AppDelegate.canceledEpisodes.removeAll()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Split view

    // TODO: čemu ovo služi?  a bez njega ne radi
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.episodeId == -1 {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }

}

