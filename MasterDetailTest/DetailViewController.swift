//
//  DetailViewController.swift
//  MasterDetailTest
//
//  Created by Stevanovic, Sasa on 1/22/19.
//  Copyright © 2019 Stevanovic, Sasa. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var controllerCache: [OnePageController] = []
    let controllerCacheCapacity: Int = 6
    
    // MARK: - UIPageViewControllerDataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let onePageController = viewController as? OnePageController else {
            return nil
        }
        var pos: Int
        if let existingPos = controllerCache.firstIndex(of: onePageController) {
            pos = existingPos
        } else {
            for c in controllerCache {
                c.cancel()
            }
            controllerCache.removeAll()
            controllerCache.insert(onePageController, at: 0)
            pos = 0
        }
        let ret: OnePageController?
        defer {
            controllerPageReturned(ret)
        }
        if pos > 0 {
            ret = controllerCache[pos - 1]
        } else {
            ret = myPageViewController(pageViewController, viewControllerBefore: onePageController)
            if let ret = ret, ret.page.0 != -1 {
                controllerCache.insert(ret, at: 0)
                pos += 1
            }
        }
        while pos < 3 {
            expandCacheLeft(pageViewController)
            pos += 1
        }
        while controllerCache.count > controllerCacheCapacity {
            controllerCache.last!.cancel()
            controllerCache.removeLast()
        }
        return ret
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let onePageController = viewController as? OnePageController else {
            return nil
        }
        var pos: Int
        if let existingPos = controllerCache.firstIndex(of: onePageController) {
            pos = existingPos
        } else {
            for c in controllerCache {
                c.cancel()
            }
            controllerCache.removeAll()
            controllerCache.insert(onePageController, at: 0)
            pos = 0
        }
        let ret: OnePageController?
        defer {
            controllerPageReturned(ret)
        }
        if pos + 1 < controllerCache.count {
            ret = controllerCache[pos + 1]
        } else {
            ret = myPageViewController(pageViewController, viewControllerAfter: onePageController)
            if let ret = ret {
                controllerCache.append(ret)
            }
        }
        var newCount = controllerCache.count
        while pos + 3 >= newCount {
            expandCacheRight(pageViewController)
            newCount += 1
        }
        while controllerCache.count > controllerCacheCapacity {
            controllerCache.first!.cancel()
            controllerCache.removeFirst()
        }
        return ret
    }

    func controllerPageReturned(_ ret: OnePageController?) {
        guard let ret = ret else {
            return
        }
        learnNavigationBarPreference()
        if ret.page.0 != -1 {
            OnePageController.lastLoadedIndex = ret.page.0
        }
    }

    func myPageViewController(_ pageViewController: UIPageViewController, viewControllerBefore onePageController: OnePageController) -> OnePageController? {
        if onePageController.page.0 > 0,
           let neighbor = storyboard?.instantiateViewController(withIdentifier: "OnePageController") as? OnePageController {
            let index = onePageController.page.0 - 1
            neighbor.page = (index, pages[index])
            return neighbor
        }
        return nil
    }

    func myPageViewController(_ pageViewController: UIPageViewController, viewControllerAfter onePageController: OnePageController) -> OnePageController? {
        if onePageController.page.0 == -1 {
            return nil
        }
        if onePageController.page.0 + 1 == pages.count && pageViewController.spineLocation == .min {
            return nil
        }
        if let neighbor = storyboard?.instantiateViewController(withIdentifier: "OnePageController") as? OnePageController {
            if onePageController.page.0 + 1 < pages.count {
                let index = onePageController.page.0 + 1
                neighbor.page = (index, pages[index])
                return neighbor
            } else if onePageController.page.0 + 1 == pages.count && onePageController.page.0 % 2 == 0 {
                neighbor.page = (-1, "")
                return neighbor
            }
        }
        return nil
    }

    // MARK: - UIPageViewControllerDelegate
    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
        if AppDelegate.inBackground {
            return pageViewController.spineLocation
        }

        let currentViewController = pageViewController.viewControllers![0] as! OnePageController
        clearCache(exceptFor: currentViewController)
        expandCacheLeft(pageViewController)
        expandCacheRight(pageViewController)

        if (orientation == .portrait) || (orientation == .portraitUpsideDown) || (UIDevice.current.userInterfaceIdiom == .phone) {
            // In portrait orientation or on iPhone: Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to true, so set it to false here.
            pageViewController.setViewControllers([currentViewController], direction: .forward, animated: true, completion: {done in })
            pageViewController.isDoubleSided = false
            return .min
        }

        // In landscape orientation: Set set the spine location to "mid" and the page view controller's view controllers array to contain two view controllers. If the current page is even, set it to contain the current and next view controllers; if it is odd, set the array to contain the previous and current view controllers.
        var viewControllers: [UIViewController]
        if (currentViewController.page.0 % 2 == 0) {
            let nextViewController: UIViewController
            if let next = self.pageViewController(pageViewController, viewControllerAfter: currentViewController) {
                nextViewController = next
            } else {
                // Above will return nil when started for the very first time (because spine location is not yet set)
                // But we know we want to set to .mid so let's make sure page is valid
                let next = storyboard?.instantiateViewController(withIdentifier: "OnePageController") as! OnePageController
                next.page = (-1, "")
                nextViewController = next
            }
            viewControllers = [currentViewController, nextViewController]
        } else {
            let previousViewController = self.pageViewController(pageViewController, viewControllerBefore: currentViewController)
            viewControllers = [previousViewController!, currentViewController]
        }
        pageViewController.setViewControllers(viewControllers, direction: .forward, animated: true, completion: {done in })
        return .mid
    }

    var sameBarPreferenceCount: Int = -1
    var isNavigationBarHidden: Bool = false {
        didSet {
            sameBarPreferenceCount = -1
        }
    }
    let sameBarPreferenceLimit: Int = 10
    func learnNavigationBarPreference() {
        // TODO: if turned page 10 times with bar not hidden, then default is not hidden
        guard let navigationController = navigationController else {
            return
        }
        if navigationController.isNavigationBarHidden != isNavigationBarHidden {
            isNavigationBarHidden = navigationController.isNavigationBarHidden
            return
        }
        
        sameBarPreferenceCount += 1
        if sameBarPreferenceCount > sameBarPreferenceLimit {
            UserDefaults.standard.set(isNavigationBarHidden, forKey: "isNavigationBarHidden")
        }
    }

    @IBOutlet weak var pageView: UIView!

    var pageController: UIPageViewController?
    var pages: [String] = []
    var episodeId: Int = -1
    var initialPageIndex: Int = 0
    var titleOnly: String = ""
    var progress: Int = -1 {
        didSet {
            if oldValue == -1 && progress != -1 && progress != 100 {
                showCancelDownload()
            }
            if progress == 100 {
                progress = -1
            }
            title = titleOnly + (progress != -1 ? " (\(progress)%)" : "")
            if progress == -1 {
                navigationItem.rightBarButtonItem = nil
            }
        }
    }
    static var lastLoadedEpisode: Int = -1
    static var previouslyLoaded: (Int, Int)?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if episodeId == -1 {
            episodeId = UserDefaults.standard.integer(forKey: "lastEpisodeId")
            initialPageIndex = UserDefaults.standard.integer(forKey: "lastPageIndex")
        }

        let pageViewController = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
        pages = Assets.pages(forEpisode: Assets.numbers[episodeId])
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        let firstController = storyboard?.instantiateViewController(withIdentifier: "OnePageController") as! OnePageController
        
        if initialPageIndex >= pages.count {
            initialPageIndex = 0
        }
        firstController.page = (initialPageIndex, pages[initialPageIndex])

        clearCache(exceptFor: firstController)
        pageViewController.setViewControllers([firstController], direction: .forward, animated: true)

        pageController = pageViewController

        // TODO: treba da ima samo jedan child, tako da ne "add"
        self.addChildViewController(pageController!)
        self.pageView.addSubview(pageController!.view)
        pageController!.view.frame = pageView.bounds
        pageController!.didMove(toParentViewController: self)
        
        if DetailViewController.lastLoadedEpisode != -1 && OnePageController.lastLoadedIndex != -1 {
            DetailViewController.previouslyLoaded = (DetailViewController.lastLoadedEpisode, OnePageController.lastLoadedIndex)
        }
        DetailViewController.lastLoadedEpisode = episodeId
        titleOnly = Assets.titles[episodeId]
        progress = AppDelegate.episodeDownloader.progress(forEpisode: episodeId)
        isNavigationBarHidden = UserDefaults.standard.bool(forKey: "isNavigationBarHidden")
        navigationController?.isNavigationBarHidden = isNavigationBarHidden

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        recognizer.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(recognizer)
        
        postInitDownloadButton()
    }

    func postInitDownloadButton() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.initDownloadButton()
        }
    }

    func initDownloadButton() {
        let alreadyDownloaded: Bool
        if let downloadedEpisodes = UserDefaults.standard.array(forKey: "downloadedEpisodes") as? [Int] {
            alreadyDownloaded = downloadedEpisodes.contains(episodeId)
        } else {
            alreadyDownloaded = false
        }
        if alreadyDownloaded {
            navigationItem.rightBarButtonItem = nil
        } else {
            if progress == -1 && canDownload() {
                DispatchQueue.main.async {
                    self.showDownload()
                }
            } else if progress != -1 {
                DispatchQueue.main.async {
                    self.showCancelDownload()
                }
            }
        }
    }
    
    func canDownload() -> Bool {
        return startDownload(dryRun: true)
    }
    
    @objc func startDownloading() {
        if startDownload(dryRun: false) {
            navigationItem.rightBarButtonItem = nil
        }
    }

    func startDownload(dryRun: Bool) -> Bool {
        guard let _ = AppDelegate.episodeDownloader.getOrCreateDownloadDir(episode: episodeId, fallback: false) else {
            return false
        }
        guard let cacheDir = OnePageController.cacheDir,
           let attrs = try? FileManager.default.attributesOfFileSystem(forPath: cacheDir.path),
           let freeSize = attrs[.systemFreeSize] as? NSNumber else {
            return false
        }
        let buffer = (dryRun ? 350 : 350)
        if freeSize.int64Value / (1<<20) < Assets.averageEpisodeSizeMB + buffer {
            guard var downloadedEpisodes = UserDefaults.standard.array(forKey: "downloadedEpisodes") as? [Int], downloadedEpisodes.count > 0 else {
                return false
            }
            if dryRun {
                return true
            }
            let sacrifice = downloadedEpisodes.removeFirst()
            let confirmation = UIAlertController(title: "Upozorenje", message: "Trenutno image oko \(freeSize.int64Value / (1<<20))MB slobodno, a strip zauzima oko \(Assets.averageEpisodeSizeMB)MB.  Da bi download radio, morate da obrišete staru epizodu '\(Assets.titles[sacrifice])'", preferredStyle: .alert)
            confirmation.addAction(UIAlertAction(title: "Obriši", style: .destructive, handler: { _ in
                AppDelegate.episodeDownloader.removeDownload(forEpisode: sacrifice)
                UserDefaults.standard.set(downloadedEpisodes, forKey: "downloadedEpisodes")
                if AppDelegate.episodeDownloader.startDownloading(episode: self.episodeId) {
                    self.navigationItem.rightBarButtonItem = nil
                }
            }))
            confirmation.addAction(UIAlertAction(title: "Ne hvala", style: .default))
            self.present(confirmation, animated: true, completion: nil)
            return false
        } else if dryRun {
            return true
        } else {
            return AppDelegate.episodeDownloader.startDownloading(episode: episodeId)
        }
    }

    @objc func cancelDownload() {
        AppDelegate.episodeDownloader.cancelDownload(forEpisode: episodeId)
        postInitDownloadButton()
    }

    // "square.and.arrow.down" iz "SF Symbols" za download
    // "wifi.slash" kad nema interneta
    // "rectangle.and.pencil.and.ellipsis" ili prosto "square.and.pencil" za Appstore (jer može da se piše autoru ili da se napiše review)
    func showDownload() {
        if #available(iOS 13.0, *) {
            //navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"), style: .plain, target: self, action: #selector(startDownload))
        } else {
            // Ikonice za navigationBar dugme: bilo bi lepo, ali je proces komplikovan, a izgleda OK da iOS 12 i raniji imaju samo tekst.
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Download", style: .plain, target: self, action: #selector(startDownloading))
        }
    }
    
    func showCancelDownload() {
        if #available(iOS 13.0, *) {
            //navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "x.square"), style: .plain, target: self, action: #selector(cancelDownload))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Otkaži", style: .plain, target: self, action: #selector(cancelDownload))
        }
    }

    @objc func doubleTap() {
        guard let navigationController = navigationController else {
            return
        }
        navigationController.isNavigationBarHidden = !navigationController.isNavigationBarHidden
    }
    
    func expandCacheLeft(_ pageViewController: UIPageViewController) {
        if let prev = myPageViewController(pageViewController, viewControllerBefore: controllerCache.first!) {
            controllerCache.insert(prev, at: 0)
        }
    }
    
    func expandCacheRight(_ pageViewController: UIPageViewController) {
        if let next = myPageViewController(pageViewController, viewControllerAfter: controllerCache.last!) {
            if next.page.0 != -1 {
                controllerCache.append(next)
            }
        }
    }
    
    func clearCache(exceptFor viewController: OnePageController) {
        for c in controllerCache {
            if c != viewController {
                c.cancel()
            }
        }
        controllerCache = [viewController]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        // TODO: clear queues
    }

}

