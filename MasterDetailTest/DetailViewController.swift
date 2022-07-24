//
//  DetailViewController.swift
//  MasterDetailTest
//
//  Created by Stevanovic, Sasa on 1/22/19.
//  Copyright © 2019 Stevanovic, Sasa. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
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

    // TODO: use lambda? but it's not just -1/+1, there is also checking for limits before calling
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let onePageController = viewController as? OnePageController,
           onePageController.page.0 + 1 < pages.count,
           let neighbor = storyboard?.instantiateViewController(withIdentifier: "OnePageController") as? OnePageController {
            let index = onePageController.page.0 + 1
            neighbor.page = (index, pages[index])
            return neighbor
        }
        return nil
    }

    // MARK: - UIPageViewControllerDelegate
    func pageViewController(_: UIPageViewController, spineLocationFor: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        return .min
    }
    
    @IBOutlet weak var pageView: UIView!

    var color: UIColor?
    var pageController: UIViewController?
    
    var pages: [String] = []
    var episodeId: Int = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        pageView.backgroundColor = .black
        
        if let onePageController = storyboard?.instantiateViewController(withIdentifier: "OnePageController") as? OnePageController,
           let color = color {
            let pageViewController = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
            switch color {
                case .red:
                    onePageController.page = (0, "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_006.jpg")
                    episodeId = 1
                case .green:
                    onePageController.page = (0, "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_010.jpg")
                    episodeId = 2
                case .blue:
                    onePageController.page = (0, "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_021.jpg")
                    episodeId = 3
                default: return
            }

            pages = getPages(forEpisode: "\(episodeId)")
            pageViewController.dataSource = self
            pageViewController.delegate = self
            let firstController = storyboard?.instantiateViewController(withIdentifier: "OnePageController") as! OnePageController
            firstController.page = (0, pages[0])
            pageViewController.setViewControllers([firstController], direction: .forward, animated: true)

            //pageController = onePageController
            pageController = pageViewController

            // TODO: treba da ima samo jedan child, tako da ne "add"
            self.addChildViewController(pageController!)
            self.pageView.addSubview(pageController!.view)
            pageController!.view.frame = pageView.bounds
            pageController!.didMove(toParentViewController: self)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.standard.set(OnePageController.lastLoadedIndex, forKey: "lastPageIndex")
    }

    func getPages(forEpisode: String) -> [String] {
        // TODO: read assets for this episode
        switch forEpisode {
        case "1": return [
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_005.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_006.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_007.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_008.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_009.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_010.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_011.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_012.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_013.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_014.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_015.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_016.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_017.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_018.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_019.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_020.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_021.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_022.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_023.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/1/1_024.jpg",
        ]
        case "2": return [
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_007.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_008.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_009.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_010.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_018.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_019.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_020.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_021.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_022.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_023.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_024.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_025.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_026.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_027.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_028.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_029.jpg",
        ]
        case "3": return [
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_011.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_012.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_013.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_014.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_015.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_016.jpg",
            "https://yugostripalanford.fra1.digitaloceanspaces.com/2/2_017.jpg",
        ]
        default: return []
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

