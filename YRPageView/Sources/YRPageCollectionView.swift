//
//  YRPageCollectionView.swift
//  YRPageView
//
//  Created by kilrae on 2017/4/12.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class YRPageCollectionView: UICollectionView {

    fileprivate var pagerView: YRPageView? {
        return self.superview?.superview as? YRPageView
    }
    
    override var scrollsToTop: Bool {
        set {
            super.scrollsToTop = false
        }
        get {
            return false
        }
    }
    
    override var contentInset: UIEdgeInsets {
        set {
            super.contentInset = .zero
            if (newValue.top > 0) {
                let contentOffset = CGPoint(x:self.contentOffset.x, y:self.contentOffset.y+newValue.top);
                self.contentOffset = contentOffset
            }
        }
        get {
            return super.contentInset
        }
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    fileprivate func commonInit() {
        self.contentInset = .zero
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.scrollsToTop = false
        self.isPagingEnabled = false
    }


}
