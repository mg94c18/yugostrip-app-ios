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
    
    // MARK: - UIPageViewControllerDataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let onePageController = viewController as? OnePageController,
           onePageController.page.0 > 0,
           let neighbor = storyboard?.instantiateViewController(withIdentifier: "OnePageController") as? OnePageController {
            let index = onePageController.page.0 - 1
            neighbor.page = (index, pages[index])
            return neighbor
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let onePageController = viewController as! OnePageController
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
        if (orientation == .portrait) || (orientation == .portraitUpsideDown) || (UIDevice.current.userInterfaceIdiom == .phone) {
            // In portrait orientation or on iPhone: Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to true, so set it to false here.
            let currentViewController = pageViewController.viewControllers![0]
            let viewControllers = [currentViewController]
            pageViewController.setViewControllers(viewControllers, direction: .forward, animated: true, completion: {done in })
            pageViewController.isDoubleSided = false
            return .min
        }

        // In landscape orientation: Set set the spine location to "mid" and the page view controller's view controllers array to contain two view controllers. If the current page is even, set it to contain the current and next view controllers; if it is odd, set the array to contain the previous and current view controllers.
        let currentViewController = pageViewController.viewControllers![0] as! OnePageController
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

    var pageController: UIViewController?
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
            pageViewController.setViewControllers([firstController], direction: .forward, animated: true)

            //pageController = onePageController
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

