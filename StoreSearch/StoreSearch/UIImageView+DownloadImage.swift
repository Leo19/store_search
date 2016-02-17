//
//  UIImageView+DownloadImage.swift
//  StoreSearch
//
//  Created by liushun on 16/1/26.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit

extension UIImageView {
    func loadImageWithURL(url: NSURL) -> NSURLSessionDownloadTask {
        let session = NSURLSession.sharedSession()
        
        // 1、
        let downloadTask = session.downloadTaskWithURL(url,completionHandler: {
            [weak self] url, response, error in
            // 2、
            if error == nil, let url = url, data = NSData(contentsOfURL: url), image = UIImage(data: data) {
                // 3、
                dispatch_async(dispatch_get_main_queue()) {
                    if let strongSelf = self {
                        strongSelf.image = image
                    }
                }
            }
        })
        // 4、
        downloadTask.resume()
        return downloadTask
    }
}
