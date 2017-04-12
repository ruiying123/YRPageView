//
//  YRPageViewLayoutAttributes.swift
//  YRPageView
//
//  Created by kilrae on 2017/4/12.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

open class YRPageViewLayoutAttributes: UICollectionViewLayoutAttributes {
    open var position: CGFloat = 0
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? YRPageViewLayoutAttributes else {
            return false
        }
        var isEqual = super.isEqual(object)
        isEqual = isEqual && (self.position == object.position)
        return isEqual
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! YRPageViewLayoutAttributes
        copy.position = self.position
        return copy
    }

}
