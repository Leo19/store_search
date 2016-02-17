//
//  DimmingPresentationController.swift
//  StoreSearch
//
//  Created by liushun on 16/1/26.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit

class DimmingPresentationController: UIPresentationController {
    lazy var dimmingView = GradientView(frame: CGRect.zero)
    
    override func shouldRemovePresentersView() -> Bool {
        return false
    }
    
    override func presentationTransitionWillBegin() {
        dimmingView.frame = containerView!.bounds
        containerView!.insertSubview(dimmingView, atIndex: 0)
        
        dimmingView.alpha = 0
        if let transitionCoordinator = presentedViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({ _ in
                self.dimmingView.alpha = 1
                }, completion: nil)
        }
    }
    
    // 取消detailView的时候调用的方法
    override func dismissalTransitionDidEnd(completed: Bool) {
        if let transitionCoordinator = presentedViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({ _ in
                self.dimmingView.alpha = 0
                }, completion: nil)
        }
    }
}
