//
//  OnePageController.swift
//  UIKitAppTest
//
//  Created by Stevanovic, Sasa on 7/18/22.
//

import Foundation
import UIKit

class OnePageController : UIViewController {
    var page: (Int, String) = (-1, "")
    static var lastLoadedIndex: Int = -1

    @IBOutlet weak var imageView: UIImageView!
    
    // TODO: izgleda da je i ovde suviše kasno, treba učitavanje da krene još unapred
    override func viewDidLoad() {
        super.viewDidLoad()
        if page.0 == -1 {
            // TODO: nešto zanimljivije od prazne strane?
            return
        }
        let url = URL(string: page.1)!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
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
                    self.imageView.image = image
                }
            }
        }
        task.resume()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        OnePageController.lastLoadedIndex = page.0
    }
}
