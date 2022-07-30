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
    var task: URLSessionTask?
    var image: UIImage?
    var didLoad: Bool = false // možda je ovo isto kao isViewLoaded a možda i nije, pa za svaki slučaj

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
        let url = URL(string: page.1)!
        task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                // self.handleClientError(error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                // self.handleServerError(response)
                return
            }
            if let mimeType = httpResponse.mimeType, mimeType.hasPrefix("image/"),
                let data = data,
                let image = UIImage(data: data) {
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
