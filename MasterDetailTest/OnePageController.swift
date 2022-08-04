//
//  OnePageController.swift
//  UIKitAppTest
//
//  Created by Stevanovic, Sasa on 7/18/22.
//

import Foundation
import UIKit

class OnePageController : UIViewController {
    var page: (Int, String) = (-1, "") {
        didSet {
            preload()
        }
    }

    static var lastLoadedIndex: Int = -1
    var task: URLSessionDataTask?
    var image: UIImage?
    var didLoad: Bool = false // možda je ovo isto kao isViewLoaded a možda i nije, pa za svaki slučaj

    static let urlSession: URLSession = {
        // let fileManagerUrl = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: .none, create: true)
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 6*1024*1024, diskCapacity: 100*1024*1024, diskPath: "pages")
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if page.0 == -1 {
            return
        }
        didLoad = true
        if let image = image {
            self.imageView.image = image
        }
    }
    
    func preload() {
        if page.0 == -1 {
            return
        }
        let urlRequest = URLRequest(url: URL(string: page.1)!, cachePolicy: .returnCacheDataElseLoad)
        task = OnePageController.urlSession.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                // self.handleClientError(error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                // self.handleServerError(response)
                return
            }
            if let response = response,
               let data = data,
               let image = UIImage(data: data) {
                if let urlCache = OnePageController.urlSession.configuration.urlCache,
                   urlCache.cachedResponse(for: urlRequest) == nil {
                    urlCache.storeCachedResponse(CachedURLResponse(response: response, data: data, storagePolicy: .allowed), for: urlRequest)
                }
                DispatchQueue.main.async {
                    if self.didLoad {
                        self.imageView.image = image
                    } else {
                        self.image = image
                    }
                }
            }
        }
        task!.resume()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        OnePageController.lastLoadedIndex = page.0
    }
    
    func cancel() {
        task?.cancel()
    }
}
