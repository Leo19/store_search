//
//  SearchResultCell.swift
//  StoreSearch
//
//  Created by liushun on 16/1/21.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    
    // 保存下载小图片那个任务
    var downloadTask: NSURLSessionDownloadTask?
    
    // 这个方法是从nib中加载完成cell后，到在TableView上显示他们前来执行
    override func awakeFromNib() {
        // 这是必调的方法
        super.awakeFromNib()
        
        // 用这个zero的原因是，有些控件这里设置了也没用(比如SliderBar)，还要在外面再设置一次
        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 0.5)
        selectedBackgroundView = selectedView
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // 覆盖父类的方法，取消下载任务(比如用户没等图片下载完就点到别的模块了)的时候调用
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // 取消任务
        downloadTask?.cancel()
        downloadTask = nil
        
        // 取消之后顺便置空一下别的标签
        nameLabel.text = nil
        artistNameLabel.text = nil
        artworkImageView.image = nil
    }

    func configureForSearchResult(searchResult: SearchResult) {
        nameLabel.text = searchResult.name
        
        // 作者做过测试有些没有artisName，所以为了防止崩溃给一个Unknown
        if searchResult.artistName.isEmpty {
            artistNameLabel.text = "Unknown"
        } else {
            // kindForDisplay就是本地化一些显示内容比如ebook翻译成E-Book
            artistNameLabel.text = String(format: "%@ (%@)", searchResult.artistName, searchResult.kindForDisplay())
        }
        
        // 加载图片，没出来的时候用Placeholder这个图暂时代替
        artworkImageView.image = UIImage(named: "Placeholder")
        if let url = NSURL(string: searchResult.artworkURL60) {
            downloadTask = artworkImageView.loadImageWithURL(url)
        }
    }
}
