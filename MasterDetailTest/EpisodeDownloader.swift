//
//  EpisodeDownloader.swift
//  MasterDetailTest
//
//  Created by Stevanovic, Sasa on 8/8/22.
//  Copyright © 2022 Stevanovic, Sasa. All rights reserved.
//

import Foundation
import UIKit

protocol EpisodeDownloaderDelegate {
    func progress(forEpisode: Int, changedTo: Int)
    func downloadComplete(forEpisode: Int)
    func downloadFailed(forEpisode: Int)
}

extension EpisodeDownloader: ImageDownloaderDelegate {
    func imageDownloadFailed(sender: ImageDownloader, error: Error) {
        handleError(forEpisode: sender.id)
    }
    
    func httpConnectionFailed(sender: ImageDownloader, statusCode: Int?) {
        handleError(forEpisode: sender.id)
    }

    func invalidImageData(sender: ImageDownloader) {
        handleError(forEpisode: sender.id)
    }
    
    func cantSaveFile(sender: ImageDownloader) {
        handleError(forEpisode: sender.id)
    }
    
    func dataSuccess(sender: ImageDownloader, image: UIImage) {
    }
    
    func storageSuccess(sender: ImageDownloader) {
        DispatchQueue.main.async {
            self.tasks[sender.id]?.removeValue(forKey: sender.url)
            guard let tasks = self.tasks[sender.id] else {
                return
            }
            if tasks.isEmpty {
                self.tasks.removeValue(forKey: sender.id)
                self.totalPages.removeValue(forKey: sender.id)
                self.delegate?.downloadComplete(forEpisode: sender.id)
            } else {
                let completed = self.totalPages[sender.id]! - tasks.count
                self.delegate?.progress(forEpisode: sender.id, changedTo: completed * 100 / self.totalPages[sender.id]!)
            }
            //DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int.random(in: 0..<15))) {
            DispatchQueue.main.async {
                if !self.notStartedTasks.isEmpty {
                    self.notStartedTasks.removeFirst().resume()
                }
            }
        }
    }
}

class EpisodeDownloader {
    var tasks: [Int:[String:URLSessionTask]] = [:]
    var notStartedTasks = Set<URLSessionTask>()
    var totalPages: [Int:Int] = [:]
    var delegate: EpisodeDownloaderDelegate?

    func handleError(forEpisode e: Int) {
            DispatchQueue.main.async {
            self.cancelDownload(forEpisode: e)
        }
        DispatchQueue.main.async {
            if !self.notStartedTasks.isEmpty {
                self.notStartedTasks.removeFirst().resume()
            }
        }
    }

    func startDownloading(episode: Int) -> Bool {
        let pages = Assets.pages(forEpisode: Assets.numbers[episode])
        guard let cacheDir = OnePageController.cacheDir else {
            return false
        }
        cancelDownload(forEpisode: episode)
        tasks[episode] = [:]
        totalPages[episode] = pages.count
        var tasksStarted: Int = 0
        var tasksNotStarted: Int = 0
        for i in 0..<pages.count {
            let fileNameSuffix = OnePageController.lastChunk(from: pages[i], startingWith: "/")
            guard !fileNameSuffix.isEmpty else {
                // TODO: ensure that there are no tasks running for this episode if false is returned
                return false
            }

            let file = cacheDir.path + fileNameSuffix
            if FileManager.default.fileExists(atPath: file) {
                continue
            }
            let url = pages[i]
            let downloader = ImageDownloader(id: episode, url: url, fileName: file, delegate: self, tmpSuffix: ".tmp.dl")
            let task = downloader.createTask()
            tasks[episode]![pages[i]] = task
            if tasksStarted < 4 && notStartedTasks.isEmpty {
                task.resume()
                tasksStarted += 1
            } else {
                notStartedTasks.insert(task)
                tasksNotStarted += 1
            }
        }
        if tasksStarted == 0 && tasksNotStarted != 0 {
            self.delegate?.progress(forEpisode: episode, changedTo: (totalPages[episode]! - tasksNotStarted) * 100 / totalPages[episode]!)
        }
        return true
    }
    
    func cancelAllDownloads() {
        for e in tasks {
            cancelDownload(forEpisode: e.key)
        }
    }

    func cancelDownload(forEpisode e: Int) {
        guard let episodeTasks = tasks[e] else {
            return
        }
        for task in episodeTasks {
            notStartedTasks.remove(task.value)
            task.value.cancel()
        }
        tasks[e] = nil
        totalPages[e] = nil
        self.delegate?.progress(forEpisode: e, changedTo: -1)
    }
    
    func progress(forEpisode e: Int) -> Int {
        guard let tasks = tasks[e], let total = totalPages[e] else {
            return -1
        }
        return (total - tasks.count) * 100 / total
    }
}
