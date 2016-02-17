//
//  BounceAnimationController.swift
//  StoreSearch
//
//  Created by liushun on 16/1/27.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit

class BounceAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    // 动画持续时间是0.4秒
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.4
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey),
        let containerView = transitionContext.containerView() {
            toView.frame = transitionContext.finalFrameForViewController(toViewController)
            containerView.addSubview(toView)
            toView.frame = transitionContext.finalFrameForViewController(toViewController)
            containerView.addSubview(toView)
            toView.transform = CGAffineTransformMakeScale(0.7, 0.7)
            
            // 弹出的时间总共是0.4秒，在这段时间内做动画
            UIView.animateKeyframesWithDuration(
                transitionDuration(transitionContext),
                delay: 0,
                options: .CalculationModeCubic,
                // 所有的动画必须放在闭包里
                animations: {
                    // 第一次先将detailView放大1.2倍
                    UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.334, animations: {
                        toView.transform = CGAffineTransformMakeScale(1.2, 1.2)
                    })
                    // 再讲detailView缩小
                    UIView.addKeyframeWithRelativeStartTime(0.334, relativeDuration: 0.333, animations: {
                        toView.transform = CGAffineTransformMakeScale(0.9, 0.9)
                    })
                    // 之后再恢复，这个CGAffineTransformMakeScale里存有原始大小
                    UIView.addKeyframeWithRelativeStartTime(0.666, relativeDuration: 0.333, animations: {
                        toView.transform = CGAffineTransformMakeScale(1.0, 1.0)
                    })
                }, completion: {
                    finished in
                    transitionContext.completeTransition(finished)
            })
        }
    }
}
