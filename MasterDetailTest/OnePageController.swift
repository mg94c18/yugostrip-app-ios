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
            fileNameSuffix = OnePageController.lastChunk(from: page.1, startingWith: "/")
            preload()
        }
    }

    static var lastLoadedIndex: Int = -1
    var task: URLSessionDataTask?
    var image: UIImage?
    var fileNameSuffix: String = ""
    var didLoad: Bool = false // možda je ovo isto kao isViewLoaded a možda i nije, pa za svaki slučaj
    static let cacheDir: URL? = {
        let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        if dir != nil && !FileManager.default.fileExists(atPath: dir!.path) {
            try? FileManager.default.createDirectory(at: dir!, withIntermediateDirectories: true)
        }
        return dir
    }()

    static func lastChunk(from s: String, startingWith c: Character) -> String {
        guard let pos = s.lastIndex(of: c) else {
            return ""
        }
        return String(s[pos...])
    }

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if page.0 == -1 {
            self.activityIndicator.stopAnimating()
            return
        }
        didLoad = true
        if let image = image {
            self.imageView.image = image
            self.activityIndicator.stopAnimating()
        }
    }
    
    func preload() {
        if page.0 == -1 {
            return
        }
        guard !fileNameSuffix.isEmpty else {
            return
        }
        guard let cacheDir = OnePageController.cacheDir else {
            startDownloading()
            return
        }

        let file = cacheDir.path + fileNameSuffix
        if !FileManager.default.fileExists(atPath: file) {
            startDownloading()
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = UIImage(contentsOfFile: file) {
                self.updateView(with: image)
            } else {
                // Should never happen
                self.startDownloading()
                try? FileManager.default.removeItem(atPath: file)
            }
        }
    }
    
    func startDownloading() {
        let urlRequest = URLRequest(url: URL(string: page.1)!)
        task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                // self.handleClientError(error)
                if self.didLoad {
                    self.activityIndicator.stopAnimating()
                }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                // self.handleServerError(response)
                if self.didLoad {
                    self.activityIndicator.stopAnimating()
                }
                return
            }
            if let data = data,
               let image = UIImage(data: data) {
                self.updateView(with: image)
                if let cacheDir = OnePageController.cacheDir {
                    let file = cacheDir.path + self.fileNameSuffix
                    let tmpFile = file + ".tmp"
                    DispatchQueue.global(qos: .utility).async {
                        if FileManager.default.createFile(atPath: tmpFile, contents: data) {
                            try? FileManager.default.moveItem(atPath: tmpFile, toPath: file)
                        }
                    }
                }
            }
        }
        task!.resume()
    }

    func updateView(with image: UIImage) {
        DispatchQueue.main.async {
            if self.didLoad {
                self.imageView.image = image
                self.activityIndicator.stopAnimating()
            } else {
                self.image = image
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        OnePageController.lastLoadedIndex = page.0
    }
    
    func cancel() {
        task?.cancel()
    }
}
