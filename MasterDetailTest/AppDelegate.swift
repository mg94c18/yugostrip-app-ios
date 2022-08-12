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
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        if let detail = navigationController.topViewController as? DetailViewController {
            if detail.episodeId == forEpisode {
                detail.progress = changedTo
            }
        }
        if let masterNav = splitViewController.viewControllers[0] as? UINavigationController {
            if let master = masterNav.topViewController as? MasterViewController {
                master.tableView.reloadData()
            }
        }
    }
    
    func downloadComplete(forEpisode episode: Int) {
        let downloadedEpisodesOpt = UserDefaults.standard.array(forKey: "downloadedEpisodes") as? [Int]
        var downloadedEpisodes: [Int]
        if downloadedEpisodesOpt == nil {
            downloadedEpisodes = []
            UserDefaults.standard.set(downloadedEpisodes, forKey: "downloadedEpisodes")
        } else {
            downloadedEpisodes = downloadedEpisodesOpt!
        }
        if downloadedEpisodes.contains(episode) {
            // TODO: Log.wtf()
        } else {
            downloadedEpisodes.append(episode)
        }
        UserDefaults.standard.set(downloadedEpisodes, forKey: "downloadedEpisodes")
        progress(forEpisode: episode, changedTo: -1)
    }
    
    func downloadFailed(forEpisode e: Int) {
        progress(forEpisode: e, changedTo: -1)
    }

    var window: UIWindow?
    static var inBackground = false
    static var episodeDownloader = EpisodeDownloader()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        AppDelegate.episodeDownloader.delegate = self
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
        AppDelegate.episodeDownloader.cancelAllDownloads()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        AppDelegate.inBackground = false
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

