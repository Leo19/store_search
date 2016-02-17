//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by liushun on 16/1/27.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit

class LandscapeViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var searchResults = [SearchResult]()
    
    var search: Search!
    
    // viewWillLayoutSubviews会被调用多次的
    private var firstTime = true
    
    // 所有开启的任务都要放里面，本类deallocated的时候统一销毁
    private var downloadTasks = [NSURLSessionDownloadTask]()
    
    // 点页面底部的白点进行翻页的操作
    @IBAction func pageChanged(sender: UIPageControl) {
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: {
            self.scrollView.contentOffset = CGPoint(
                x: self.scrollView.bounds.size.width * CGFloat(sender.currentPage),
                y: 0)
            }, completion: nil)
        scrollView.contentOffset = CGPoint(
            x: scrollView.bounds.size.width * CGFloat(sender.currentPage) ,y: 0
        )
    }
    
    override func viewDidLoad() {
        // 下面三段都是禁用Auto Layout的，面板上也禁用的话整个工程都会禁用
        view.removeConstraints(view.constraints)
        
        // AutoLayout并没有真正被禁用，设置为true的时候才不会把手动布局翻译成约束
        // 否则的话会和automatic constraints有冲突
        view.translatesAutoresizingMaskIntoConstraints = true
        
        // 当Auto Layout可用的时候，不能通过frame改变位置只能用约束来确定位置，否则有冲突
        pageControl.removeConstraints(pageControl.constraints)
        pageControl.translatesAutoresizingMaskIntoConstraints = true
        
        // 禁用这些view的Auto Layout是为了后面画搜过结果的buttons用的
        scrollView.removeConstraints(scrollView.constraints)
        scrollView.translatesAutoresizingMaskIntoConstraints = true

        /* 把一小幅背景图片平铺成背景(UIColor has a cool trick 
        that lets you use a tile-able image for a color) UIImage是一个可失败构造器 */
        scrollView.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
        
        // 这句是设定scroll view有多大，不改bounds和frame而是改contentSize，且只能在代码里设定
        // scrollView.contentSize = CGSize(width: 100, height: 100)

        pageControl.numberOfPages = 0
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // bounds是描述矩形里的内容，frame是描述view外的内容
        scrollView.frame = view.bounds
        
        // pageControl scrollView 都是main view的子类所以他们的frame和mainView.bounds的坐标空间是一样的
        // mainView.bouds == pageControl/scrollView.frame 父类的内和子类的外坐标一样
        pageControl.frame = CGRect(
            x: 0,
            y: view.frame.size.height - pageControl.frame.size.height,
            width: view.frame.size.width,
            height: pageControl.frame.size.height
        )
        
        /* 这段是画搜索结果里的buttons，因为viewDidLoad()调用完成之后才会知道view的大小等信息
         * 而画buttons需要知道view的大小，然后计算每一页scrollView上放多少个button，而且
         * viewWillLayoutSubviews可能是要被调用多次的，只有第一次view出来的时候才应该画buttons
        */
        if firstTime {
            firstTime = false
            switch search.state {
            case .NotSearchedYet:
                break
            case .Loading:
                break
            case .NoResults:
                break
            case .Results(let list):
                tileButtons(list)
            }
        }
    }
    
    private func tileButtons(searchResults: [SearchResult]) {
        var columnsPerPage = 5
        var rowsPerPage = 3
        var itemWidth: CGFloat = 96
        var itemHeight: CGFloat = 88
        var marginX: CGFloat = 0
        var marginY: CGFloat = 20
        
        let scrollViewWidth = scrollView.bounds.size.width
        
        /* 480的(3.5-inch iphone4S)
         * 568的(4-inch all iPhone5)
         * 667的(4.7-inch iPhone6)
         * 736的(5.5-inch iPhone6+)
        */
        switch scrollViewWidth {
        case 568:
            columnsPerPage = 6
            itemWidth = 94
            marginX = 2
        case 667:
            columnsPerPage = 7
            itemWidth = 95
            itemHeight = 98
            marginX = 1
            marginY = 29
        case 736:
            columnsPerPage = 8
            rowsPerPage = 4
            itemWidth = 92
        default:
            break
        }
        
        // 没一个小图的宽度和高度，还有他们之间的间隔
        let buttonWidth: CGFloat = 82
        let buttonHeight: CGFloat = 82
        let paddingHorz = (itemWidth - buttonWidth)/2
        let paddingVert = (itemHeight - buttonHeight)/2
        
        var row = 0
        var column = 0
        var x = marginX
        for searchResult in searchResults {
            // 1、
            let button = UIButton(type: .Custom)
            button.setBackgroundImage(UIImage(named: "LandscapeButton"), forState: .Normal)
            
            //  给button填图片
            downloadImageForSearchResult(searchResult, andPlaceOnButton: button)
            
            // 2、
            button.frame = CGRect(
                x: x + paddingHorz,
                y: marginY + CGFloat(row) * itemHeight + paddingVert,
                width: buttonWidth,
                height: buttonHeight)
            
            // 3、
            scrollView.addSubview(button)
            
            // 4、
            ++row
            if row == rowsPerPage {
                row = 0; x += itemWidth; ++column
                
                if column == columnsPerPage {
                    column = 0; x += marginX * 2
                }
            }
        }
        
        let buttonsPerPage = columnsPerPage * rowsPerPage
        
        // 减一这种写法巧妙的规避了if else，如果不写的话需要判断是否能整除
        print(buttonsPerPage)
        print(searchResults.count)
        let numPages = 1 + (searchResults.count - 1) / buttonsPerPage
        
        scrollView.contentSize = CGSize(
            width: CGFloat(numPages) * scrollViewWidth,
            height: scrollView.bounds.size.height)
        print("Number of pages: \(numPages)")
        
        pageControl.numberOfPages = numPages
        pageControl.currentPage = 0
        
    }
    
    private func downloadImageForSearchResult(searchResult: SearchResult, andPlaceOnButton button: UIButton){
        if let url = NSURL(string: searchResult.artworkURL60) {
            let session = NSURLSession.sharedSession()
            let downloadTask = session.downloadTaskWithURL(url) {
                [weak button] url, response, error in
                if error == nil, let url = url, data = NSData(contentsOfURL: url),
                    image = UIImage(data: data) {
                        dispatch_async(dispatch_get_main_queue()) {
                            if let button = button {
                                button.setImage(image, forState: .Normal)
                            }
                        }
                }
            }
            downloadTask.resume()
            downloadTasks.append(downloadTask)
        }
    }
    
    deinit {
        print("deinit \(self)")
        for task in downloadTasks {
            task.cancel()
        }
    }
}

extension LandscapeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        
        // 下一屏，滑到一半的时候就到翻到下一页
        let currentPage = Int((scrollView.contentOffset.x + width/2)/width)
        pageControl.currentPage = currentPage
    }
}

















