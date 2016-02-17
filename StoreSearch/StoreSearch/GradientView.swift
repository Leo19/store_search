//
//  GradientView.swift
//  StoreSearch
//
//  Created by liushun on 16/1/27.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit

class GradientView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
    }
    
    // 必须实现的可失败构造器
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clearColor()
        
        // 这个是当superview changes size的时候干什么，可以有很多选择
        // 比如：do nothing、粘住特定superview的边缘，或者改变比例
        // 本例的意思是总是盖住superview的区域，所以不会有一个白色的边了
        autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    }
    
    override func drawRect(rect: CGRect) {
        // 1、
        let components: [CGFloat] = [0,0,0,0.3, 0,0,0,0.7]
        let locations: [CGFloat] = [0,1]

        // 2、
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2)
        // 3、
        let x = CGRectGetMidX(bounds)
        let y = CGRectGetMidY(bounds)
        let point = CGPoint(x: x, y: y)
        let radius = max(x, y)
        // 4、
        let context = UIGraphicsGetCurrentContext()
        CGContextDrawRadialGradient(context, gradient, point, 0, point, radius, .DrawsAfterEndLocation)
    }
}
