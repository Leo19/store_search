//
//  FadeOutAnimationController.swift
//  StoreSearch
//
//  Created by liushun on 16/1/28.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit

/* 这里是标准的创建用在dismissal的时候的动画，首先在DetailViewController.AnimationStyle里加一个值
 * 然后就类似这个类写一个新的controller实现以下这俩方法
*/
class FadeOutAnimationController: NSObject, UIViewControllerAnimatedTransitioning{
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.4
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey) {
            let duration = transitionDuration(transitionContext)
            UIView.animateWithDuration(duration, animations: {
                fromView.alpha = 0
                }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        }
    }
}
