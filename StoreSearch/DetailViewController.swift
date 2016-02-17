//
//  DetailViewController.swift
//  StoreSearch
//
//  Created by liushun on 16/1/26.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var kindLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var priceButton: UIButton!
    
    // 从列表页过来的数据
    var searchResult: SearchResult!

    // 加载图片的任务
    var downloadTask: NSURLSessionDownloadTask?
    
    // 定义了一个enum它的名字应该是DetailViewController.AnimationStyle
    // 一定程度上也避免了，naming conflicts
    enum AnimationStyle {
        case Slide
        case Fade
    }
    
    var dismissAnimationStyle = AnimationStyle.Fade
    
    @IBAction func close() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func openInStore() {
        if let url = NSURL(string: searchResult.storeURL) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    // 自定制一个可失败构造器
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .Custom
        transitioningDelegate = self
    }
    
    // 我们提前把按钮的背景图片reader as 改成了Template Image 所以UIKit渲染图片的时候
    // 会找tint color，我们自己定义一下tint color
    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 1)
        
        // UIViews 画控件会用CALayer 对象，是让iPhone做动画更容易的一个对象，每个view都有一个
        popupView.layer.cornerRadius = 10
        
        // 只有点Popupview之外的部分才会隐藏这个Popupview
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("close"))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        
        // 从列表也过来，如果searchResult不为空，把它的值填到页面上
        if searchResult != nil {
            updateUI()
        }
        
        // 是为了给detail做渐变动画的时候将最下层的dimmingView颜色设置成全透明
        view.backgroundColor = UIColor.clearColor()
    }
    
    // 列表页带过来的数据，填到Popupview上
    func updateUI() {
        nameLabel.text = searchResult.name
        
        if searchResult.artistName.isEmpty {
            artistNameLabel.text = "Unknown"
        } else {
            artistNameLabel.text = searchResult.artistName
        }
        
        kindLabel.text = searchResult.kindForDisplay()
        genreLabel.text = searchResult.genre
        
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.currencySymbol = "￥"
        formatter.currencyCode = searchResult.currency
        
        // 价格从字符串转化成number
        let priceText: String
        if searchResult.price == 0 {
            priceText = "Free"
        } else if let text = formatter.stringFromNumber(searchResult.price) {
            priceText = text
        } else {
            priceText = ""
        }
        
        priceButton.setTitle(priceText, forState: .Normal)
        
        if let url = NSURL(string: searchResult.artworkURL100) {
            downloadTask = artworkImageView.loadImageWithURL(url)
        }
    }
    
    deinit {
        print("deinit \(self)")
        // 因为Optional的原因又可以少写一个if
        downloadTask?.cancel()
    }
}

// 一个页面跳转包括这三大部分：presentations transitions animations
extension DetailViewController: UIViewControllerTransitioningDelegate {
    
    // 这个方法是告诉UIKit去用哪个transition到DetailViewController
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        // 返回咱们自定制的一个presentation
        return DimmingPresentationController(presentedViewController: presented, presentingViewController: presenting)
    }
    
    // 在BounceAnimationController中自定义了动画
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BounceAnimationController()
    }
    
    // DetailView消失的时候触发的动画
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch dismissAnimationStyle {
        case .Slide:
            return SlideOutAnimationController()
        case .Fade:
            // MARK: FadeOut.......
            return nil
        }
    }
}


// 设置手势的方式多种多样，没啥规律，发挥大家的聪明才智自己做吧
extension DetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        // 三个等号是比较引用
        return (touch.view === self.view)
    }
}
