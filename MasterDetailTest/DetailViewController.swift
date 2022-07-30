//
//  DetailViewController.swift
//  MasterDetailTest
//
//  Created by Stevanovic, Sasa on 1/22/19.
//  Copyright © 2019 Stevanovic, Sasa. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    // [TableView] Warning once only: UITableView was told to layout its visible cells and other contents without being in the view hierarchy (the table view or one of its superviews has not been added to a window). This may cause bugs by forcing views inside the table view to load and perform layout without accurate information (e.g. table view bounds, trait collection, layout margins, safe area insets, etc), and will also cause unnecessary performance overhead due to extra layout passes. Make a symbolic breakpoint at UITableViewAlertForLayoutOutsideViewHierarchy to catch this in the debugger and see what caused this to occur, so you can avoid this action altogether if possible, or defer it until the table view has been added to a window.

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
        let currentViewController = pageViewController.viewControllers![0] as! OnePageController
        clearCache(except: currentViewController)
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
            let nextViewController = self.pageViewController(pageViewController, viewControllerAfter: currentViewController)
            viewControllers = [currentViewController, nextViewController!]
        } else {
            let previousViewController = self.pageViewController(pageViewController, viewControllerBefore: currentViewController)
            viewControllers = [previousViewController!, currentViewController]
        }
        pageViewController.setViewControllers(viewControllers, direction: .forward, animated: true, completion: {done in })
        return .mid
    }


    @IBOutlet weak var pageView: UIView!

    var pageController: UIPageViewController?
    var pages: [String] = []
    var episodeId: Int = -1
    var initialPageIndex: Int = 0
    static var lastLoadedEpisode: Int = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if episodeId == -1 {
            episodeId = UserDefaults.standard.integer(forKey: "lastEpisodeId")
            initialPageIndex = UserDefaults.standard.integer(forKey: "lastPageIndex")
        }

        if let onePageController = storyboard?.instantiateViewController(withIdentifier: "OnePageController") as? OnePageController {
            let pageViewController = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
            pages = Assets.pages(forEpisode: Assets.numbers[episodeId])
            pageViewController.dataSource = self
            pageViewController.delegate = self
            let firstController = storyboard?.instantiateViewController(withIdentifier: "OnePageController") as! OnePageController
            
            if initialPageIndex >= pages.count {
                initialPageIndex = 0
            }
            firstController.page = (initialPageIndex, pages[initialPageIndex])

            clearCache(except: firstController)
            pageViewController.setViewControllers([firstController], direction: .forward, animated: true)

            pageController = pageViewController

            // TODO: treba da ima samo jedan child, tako da ne "add"
            self.addChildViewController(pageController!)
            self.pageView.addSubview(pageController!.view)
            pageController!.view.frame = pageView.bounds
            pageController!.didMove(toParentViewController: self)
            
            DetailViewController.lastLoadedEpisode = episodeId
            self.title = Assets.titles[episodeId]
        }
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
    
    func clearCache(except viewController: OnePageController) {
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

