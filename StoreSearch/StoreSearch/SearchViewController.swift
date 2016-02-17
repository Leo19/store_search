//
//  ViewController.swift
//  StoreSearch
//
//  Created by liushun on 16/1/20.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    // 页面上的输入和搜索控件
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    // 暂存搜索结果
    //var searchResults = [SearchResult]()
    
    // 标识是否搜索过的标志位
    //var hasSearched = false
    let search = Search()
    
    // 加载中的标志位
    //var isLoading = false
    
    // 用一个实例变量存储NSURLSessionDataTask做一些容错处理
//    var dataTask: NSURLSessionDataTask?
    
    // 可以用modal segue的方式做transition但是这里有另外一种方法
    // 顺便联系一下view controller containment
    var landscapeViewController: LandscapeViewController?
    
    // 用结构体当做一个constant
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell = "LoadingCell"
    }
    
    // segment值改变之后触发的事件
    @IBAction func segmentChanged(sender: UISegmentedControl) {
        print("Segment changed: \(sender.selectedSegmentIndex)")
        performSearch()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 0, right: 0)
        
        // nib中cell的高度
        tableView.rowHeight = 80
        
        // 加载这些nib文件
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 跳转到detail再把数据带过去
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowDetail" {
            if case .Results(let list) = search.state {
                let detailViewController = segue.destinationViewController as! DetailViewController
                let indexPath = sender as! NSIndexPath
                let searchResult = list[indexPath.row]
                detailViewController.searchResult = searchResult
            }
        }
    }
    
    // TraitCollection只要属于集合里的trait都执行该方法
    // trait是指屏幕旋转，还有缩放的时候UIKit都会调用此方法
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        switch newCollection.verticalSizeClass {
        case .Compact:
            showLandscapeViewWithCoordinator(coordinator)
        case .Regular, .Unspecified:
            hideLandscapeViewWithCoordinator(coordinator)
        }
    }
    
    // 处理网络请求异常
    func showNetworkError() {
        let alert = UIAlertController(
            title: "Whoops...",
            message: "There was an error reading from the itunes Please try again.", preferredStyle: .Alert)
        
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        
        // 也就是用Alert弹出框提示消息
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func showLandscapeViewWithCoordinator(coordinator: UIViewControllerTransitionCoordinator) {
        // 1、为了以防万一，如果不为true的话就是一屏幕显示两个以上的view了，决定不能粗线这种情况
        precondition(landscapeViewController == nil)
        // 2、从面板上创建，因为没有用segue
        landscapeViewController = storyboard!.instantiateViewControllerWithIdentifier("LandscapeViewController") as? LandscapeViewController
        if let controller = landscapeViewController {
            // 3、被嵌入的landscapeViewController要求要和SearchViewController大小一样
            // 顺便传值
            controller.search = search
            controller.view.frame = view.bounds
            controller.view.alpha = 0
            // 4、一下这三步保证landscapeViewController是嵌入进去的是SearchViewController的一部分
            view.addSubview(controller.view)
            addChildViewController(controller)
            coordinator.animateAlongsideTransition({ _ in
                controller.view.alpha = 1
                self.searchBar.resignFirstResponder()
                
                // 隐藏detailView
                if self.presentedViewController != nil {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                }, completion: { _ in
                controller.didMoveToParentViewController(self)
            })
        }
    }
    
    // 如果里面没有一系列的remove的代码，会触发上面的断言precondition(.....
    func hideLandscapeViewWithCoordinator(coordinator: UIViewControllerTransitionCoordinator) {
        if let controller = landscapeViewController {
            controller.willMoveToParentViewController(nil)
            
            coordinator.animateAlongsideTransition({ _ in
                    controller.view.alpha = 0
                },
                completion: { _ in
                    controller.view.removeFromSuperview()
                    controller.removeFromParentViewController()
                    self.landscapeViewController = nil
            })
        }
    }
    
    deinit {
        print("deinit \(self)")
    }
}

extension SearchViewController: UISearchBarDelegate {
    // 点了搜索按钮之后执行的方法
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        performSearch()
    }
    
    // 将执行的方法彻底抽出来
    func performSearch() {
        if let category = Search.Category(rawValue: segmentControl.selectedSegmentIndex) {
            search.performSearchForText(searchBar.text!, category: category,
                // 闭包总是在主线程执行的，所以可以在这里写UI相关的代码，并且比delegate要简单多了
                completion: { success in
                    if !success {
                        self.showNetworkError()
                    }
                    self.tableView.reloadData()
            })
            tableView.reloadData()
            searchBar.resignFirstResponder()
        }
/* 这是重构之前的代码，其实是把搜索结果和UIKit做的画图工作写在一起了 */
//        if !searchBar.text!.isEmpty {
//            searchBar.resignFirstResponder()
//            
//            // 防止用户点了多次搜索按钮后，因为延迟覆盖了上一次搜索结果
//            // 还有一个好处就是，如果用户只点了一次就不会cancel，因为是Optional直接是nil了
//            dataTask?.cancel()
//            
//            // 加载中
//            search.isLoading = true
//            tableView.reloadData()
//            
//            // 搜索过就置为true
//            search.hasSearched = true
//            search.searchResults = [SearchResult]()
//            
//            let url = urlWithSearchText(searchBar.text!,category: segmentControl.selectedSegmentIndex)
//            let session = NSURLSession.sharedSession()
//            dataTask = session.dataTaskWithURL(url,completionHandler: {
//                data, response, error in
//                if let error = error where error.code == -999 {
//                    return
//                } else if let httpResponse = response as? NSHTTPURLResponse where httpResponse.statusCode == 200 {
//                    // 两个隐式解包，避免写嵌套着写if else 了
//                    if let data = data, dictionary = self.parseJSON(data) {
//                        self.search.searchResults = self.parseDictionary(dictionary)
//                        self.search.searchResults.sortInPlace(<)
//                        
//                        dispatch_async(dispatch_get_main_queue()) {
//                            print("On the main thread? " + (NSThread.currentThread().isMainThread ? "YES" : "NO"))
//                            self.search.isLoading = false
//                            self.tableView.reloadData()
//                        }
//                    }
//                    return
//                } else {
//                    print("Failure! \(response!)")
//                }
//                
//                // 只有错误的时候才能执行到这，正常的话就在if里返回了
//                dispatch_async(dispatch_get_main_queue()) {
//                    self.search.hasSearched = false
//                    self.search.isLoading = false
//                    self.tableView.reloadData()
//                    self.showNetworkError()
//                }
//            })
//            
//            dataTask?.resume()
//        }
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    // 配合选中后的方法，给选中一个
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        switch search.state {
        case .NotSearchedYet, .Loading, .NoResults:
            return nil
        case .Results:
            return indexPath
        }
//        if search.searchResults.count == 0 || search.isLoading {
//            return nil
//        } else {
//            return indexPath
//        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // 选中的动画
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // 跳转到详情页
        performSegueWithIdentifier("ShowDetail", sender: indexPath)
    }
}

// 虽然是拓展，但是也要实现必要的方法(方法名前不带Optional的)
extension SearchViewController: UITableViewDataSource {
    // 和继承还是有区别的，就是不用写override
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch search.state {
        case .NotSearchedYet:
            return 0
        case .Loading:
            return 1
        case .NoResults:
            return 1
        case.Results(let list):
            return list.count
        }
    }
    
    // 还是老办法可重用的方式创建cell
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch search.state {
        case .NotSearchedYet:
            fatalError("Should never get here")
        case .Loading:
                let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.loadingCell, forIndexPath: indexPath)
                let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
                spinner.startAnimating()
                return cell
        case .NoResults:
            // 没有搜索结果时候的nib文件
            return tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.nothingFoundCell, forIndexPath: indexPath)
            // 就是给Results()括号里的变量取个别名，这个case里好调用
        case .Results(let list):
            // 加载展示搜索结果的nib文件
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.searchResultCell, forIndexPath: indexPath) as! SearchResultCell
            let searchResult = list[indexPath.row]
            
            // 自定制一下页面上展示的文字
            cell.configureForSearchResult(searchResult)
            return cell
        }
    }
}

extension SearchViewController: UITableViewDelegate {

}