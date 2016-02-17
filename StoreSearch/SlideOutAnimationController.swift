//
//  SlideOutAnimationController.swift
//  StoreSearch
//
//  Created by liushun on 16/1/27.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit

class SlideOutAnimationController: NSObject, UIViewControllerAnimatedTransitioning{
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey),
        let containerView = transitionContext.containerView() {
            let duration = transitionDuration(transitionContext)
            
            // 将detailView往上移，同时缩小这个detailView 
            // 原文叫：making the Detail screen fly up-up-and-away
            UIView.animateWithDuration(duration, animations: {
                fromView.center.y -= containerView.bounds.size.height
                fromView.transform = CGAffineTransformMakeScale(0.5, 0.5)
                }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        }
    }
}
