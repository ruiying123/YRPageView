//
//  YRPageView.swift
//  YRPageView
//
//  Created by kilrae on 2017/4/12.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

@objc public protocol YRPageViewDataSource: NSObjectProtocol {
    
    @objc(numberOfItemsInPageView:)
    func numberOfItems(pageView: YRPageView) -> Int
    
    @objc(pageView:cellForItemAtIndex:)
    func pageView(_ pageView: YRPageView, cellForItemAt index: Int) -> YRPageViewCell
}


@objc public protocol YRPageViewDelegate: NSObjectProtocol {
    
    @objc(pageView:didSelectItemAtIndex:)
    optional func pageView(_ pageView: YRPageView, didSelectItemAtIndex index: Int)
    
    @objc(pageView:shouldHighlightItemAtIndex:)
    optional func pageView(_ pageView: YRPageView, shouldHighlightItemAt index: Int) -> Bool
    
    @objc(pageView:didHighlightItemAtIndex:)
    optional func pageView(_ pageView: YRPageView, didHighlightItemAt index: Int)
    
    @objc(pageView:shouldSelectItemAtIndex:)
    optional func pageView(_ pageView: YRPageView, shouldSelectItemAt index: Int) -> Bool
    
    @objc(pageView:willDisplayCell:forItemAtIndex:)
    optional func pageView(_ pageView: YRPageView, willDisplay cell: YRPageViewCell, forItemAt index: Int)
    
    @objc(pageView:didEndDisplayingCell:forItemAtIndex:)
    optional func pageView(_ pageView: YRPageView, didEndDisplaying cell: YRPageViewCell, forItemAt index: Int)
    
    @objc(pageViewWillBeginDragging:)
    optional func pageViewWillBeginDragging(_ pageView: YRPageView)
    
    @objc(pageViewWillEndDragging:targetIndex:)
    optional func pageViewWillEndDragging(_ pageView: YRPageView, targetIndex: Int)
    
    @objc(pageViewDidScroll:)
    optional func pageViewDidScroll(_ pageView: YRPageView)
    
    @objc(pageViewDidEndScrollAnimation:)
    optional func pageViewDidEndScrollAnimation(_ pageView: YRPageView)
    
    @objc(pageViewDidEndDecelerating:)
    optional func pageViewDidEndDecelerating(_ pageView: YRPageView)
}

public enum YRPageViewScrollDirection: Int {
    case horizontal
    case vertical
}


open class YRPageView: UIView {
    
    // MARK: - Public properties
    
    open weak var dataSource: YRPageViewDataSource?
    
    open weak var delegate: YRPageViewDelegate?
    
    open var scrollDirection: YRPageViewScrollDirection = .horizontal {
        didSet {
            self.collectionViewLayout.forceInvalidate()
        }
    }
    
    open var automaticSlidingInterval: CGFloat = 0 {
        didSet {
            self.cancelTimer()
            if self.automaticSlidingInterval > 0 {
                self.startTimer()
            }
        }
    }
    
    open var interItemSpacing: CGFloat = 0 {
        didSet {
            self.collectionViewLayout.forceInvalidate()
        }
    }
    
    open var itemSize: CGSize = .zero {
        didSet {
            self.collectionViewLayout.forceInvalidate()
        }
    }
    
    open var isInfinite: Bool = false {
        didSet {
            self.collectionViewLayout.needsReprepare = true
            self.collectionView.reloadData()
        }
    }
    
    open var backgroundView: UIView? {
        didSet {
            if let backgroundView = self.backgroundView {
                if backgroundView.superview != nil {
                    backgroundView.removeFromSuperview()
                }
                self.insertSubview(backgroundView, at: 0)
                self.setNeedsLayout()
            }
        }
    }
    
    open var transformer: YRPageViewTransformer? {
        didSet {
            self.transformer?.pagerView = self
            self.collectionViewLayout.forceInvalidate()
        }
    }
    
    // MARK: - Public readonly properties
    
    open var isTracking: Bool {
        return self.collectionView.isTracking
    }
    
    open var scrollOffset: CGFloat {
        let contentOffset = max(self.collectionView.contentOffset.x, self.collectionView.contentOffset.y)
        let scrollOffset = Double(contentOffset.divided(by: self.collectionViewLayout.itemSpacing))
        return fmod(CGFloat(scrollOffset), CGFloat(Double(numberOfItems)))
    }
    
    open var panGestureRecongizer: UIPanGestureRecognizer {
        return self.collectionView.panGestureRecognizer
    }
    
    open fileprivate(set) dynamic var currentIndex: Int = 0
    
    // MARK: - Private propertuies
    
    internal weak var collectionViewLayout: YRPageViewLayout!
    internal weak var collectionView: YRPageCollectionView!
    internal weak var contentView: UIView!
    
    internal var timer: Timer?
    internal var numberOfItems: Int = 0
    internal var numberOfSections: Int = 0
    
    fileprivate var dequeingSection = 0
    fileprivate var centermostIndexPath: IndexPath {
        guard self.numberOfItems > 0, self.collectionView.contentSize != .zero else {
            return IndexPath(item: 0, section: 0)
        }
        let sortedIndexPaths = self.collectionView.indexPathsForVisibleItems.sorted() { (l, r) -> Bool in
            let leftFrame = self.collectionViewLayout.frame(for: l)
            let rightFrame = self.collectionViewLayout.frame(for: r)
            var leftCenter: CGFloat, rightCenter: CGFloat, ruler: CGFloat
            switch self.scrollDirection {
            case .horizontal:
                leftCenter = leftFrame.midX
                rightCenter = rightFrame.midX
                ruler = self.collectionView.bounds.midX
            case .vertical:
                leftCenter = leftFrame.midY
                rightCenter = rightFrame.midY
                ruler = self.collectionView.bounds.midY
            }
            return abs(ruler - leftCenter) < abs(ruler - rightCenter)
        }
        let indexPath = sortedIndexPaths.first
        if let indexPath = indexPath {
            return indexPath
        }
        return IndexPath(item: 0, section: 0)
    }
    
    fileprivate var possibleTargetingIndexPaht: IndexPath?

    // MARK: - OVerride function
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundView?.frame = self.bounds
        self.contentView.frame = self.bounds
        self.collectionView.frame = self.contentView.bounds
    }
    
    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow != nil {
            self.startTimer()
        } else {
            self.cancelTimer()
        }
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.cornerRadius = 5
        self.contentView.layer.masksToBounds = true
        let label = UILabel(frame: contentView.bounds)
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.text = "YRPageView"
        self.contentView.addSubview(label)
    }
    
    deinit {
        self.collectionView.dataSource = nil
        self.collectionView.delegate = nil
    }
    
    // MARK: - Public functions
    
    open func register(_ cellClass: Swift.AnyClass?, forCellWithReuseIdentifier identifier: String) {
        self.collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }
    
    open func regitser(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        self.collectionView.register(nib, forCellWithReuseIdentifier: identifier)
    }
    
    open func dequeueReusableCell(withReuseIdentifier identifier: String, at index: Int) -> YRPageViewCell {
        let indexPath = IndexPath(item: index, section: dequeingSection)
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        guard cell.isKind(of: YRPageViewCell.self) else {
            fatalError("Cell class must be subClass of YRPageViewCell")
        }
        return cell as! YRPageViewCell
    }
    
    open func reloadData() {
        self.collectionViewLayout.needsReprepare = true
        self.collectionView.reloadData()
    }
    
    open func selectItem(at index: Int, animation: Bool) {
        let indexPath = self.nearbyIndexPath(for: index)
        let scrollPosition: UICollectionViewScrollPosition = self.scrollDirection == .horizontal ? .centeredHorizontally : .centeredVertically
        self.collectionView.selectItem(at: indexPath, animated: animation, scrollPosition: scrollPosition)
    }
    
    open func deselectItem(at index: Int, animation: Bool) {
        let indexPath = self.nearbyIndexPath(for: index)
        self.collectionView.deselectItem(at: indexPath, animated: animation)
    }
    
    open func scrollToitem(at index: Int, animated: Bool) {
        guard index < numberOfItems else {
            fatalError("index \(index) is out of range [0..\(numberOfItems-1)]")
        }
        let indexPath = { () -> IndexPath in
            if let indexPath = self.possibleTargetingIndexPaht, indexPath.item == index {
                defer {
                    self.possibleTargetingIndexPaht = nil
                }
                return indexPath
            }
            return self.isInfinite ? self.nearbyIndexPath(for: index) : IndexPath(item: index, section: 0)
        }()
        let contentOffset = collectionViewLayout.contentOffset(for: indexPath)
        collectionView.setContentOffset(contentOffset, animated: animated)
    }
    
    open func index(for cell: YRPageViewCell) -> Int {
        guard let indexPath = self.collectionView.indexPath(for: cell) else {
            return NSNotFound
        }
        return indexPath.item
    }
    
    // MARK: - Private functions
    
    fileprivate func commonInit() {
        let contentView = UIView(frame: CGRect.zero)
        contentView.backgroundColor = .clear
        addSubview(contentView)
        self.contentView = contentView
        
        //UICollectionView
        let collectionViewLayout = YRPageViewLayout()
        let collectionView = YRPageCollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        self.contentView.addSubview(collectionView)
        self.collectionView = collectionView
        self.collectionViewLayout = collectionViewLayout
    }
    
    fileprivate func startTimer() {
        guard self.automaticSlidingInterval > 0 && self.timer == nil else {
            return
        }
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(automaticSlidingInterval), target: self, selector: #selector(self.flipNext(sender:)), userInfo: nil, repeats: true)
    }
    
    @objc fileprivate func flipNext(sender: Timer?) {
        guard let _ = self.superview, let _ = self.window, self.numberOfItems > 0, !self.isTracking else {
            return
        }
        self.scrollToitem(at: (self.currentIndex+1)%self.numberOfItems, animated: true)
    }
    
    fileprivate func cancelTimer() {
        guard self.timer != nil else {
            return
        }
        self.timer?.invalidate()
        self.timer = nil
    }
    
    fileprivate func nearbyIndexPath(for index: Int) -> IndexPath {
        let currentIndex = self.currentIndex
        let currentSection = self.centermostIndexPath.section
        if abs(currentIndex-index) <= self.numberOfItems {
            return IndexPath(item: index, section: currentSection)
        } else if (index-currentIndex >= 0) {
            return IndexPath(item: index, section: currentSection-1)
        }else {
            return IndexPath(item: index, section: currentSection + 1)
        }
    }

}

extension YRPageView: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let dataSource = self.dataSource else {
            return 1
        }
        self.numberOfItems = dataSource.numberOfItems(pageView: self)
        guard self.numberOfItems > 0 else {
            return 0
        }
        self.numberOfSections = self.isInfinite ? Int(Int16.max)/self.numberOfItems : 1
        return self.numberOfItems
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItems
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        self.dequeingSection = indexPath.section
        guard let cell = self.dataSource?.pageView(self, cellForItemAt: index) else {
            return UICollectionViewCell()
        }
        return cell
    }
}

extension YRPageView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let function = self.delegate?.pageView(_: shouldHighlightItemAt:) else {
            return true
        }
        let index = indexPath.item % self.numberOfItems
        return function(self, index)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let function = self.delegate?.pageView(_: didHighlightItemAt:) else {
            return
        }
        let index = indexPath.item % self.numberOfItems
        function(self, index)
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let function = self.delegate?.pageView(_: shouldSelectItemAt:) else {
            return true
        }
        let index = indexPath.item % self.numberOfItems
        return function(self, index)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let function = self.delegate?.pageView(_: didSelectItemAtIndex:) else {
            return
        }
        self.possibleTargetingIndexPaht = indexPath
        defer {
            self.possibleTargetingIndexPaht = nil
        }
        let index = indexPath.item % self.numberOfItems
        function(self, index)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let function = self.delegate?.pageView(_: willDisplay: forItemAt:) else {
            return
        }
        let index = indexPath.item % self.numberOfItems
        function(self, cell as! YRPageViewCell, index)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let function = self.delegate?.pageView(_: didEndDisplaying: forItemAt:) else {
            return
        }
        let index = indexPath.item % numberOfItems
        function(self, cell as!YRPageViewCell, index)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if numberOfItems > 0 {
            let currentIndex = lround(Double(self.scrollOffset)) % numberOfItems
            if currentIndex != self.currentIndex {
                self.currentIndex = currentIndex
            }
        }
        guard  let function = self.delegate?.pageViewDidScroll(_:) else {
            return
        }
        function(self)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let function = self.delegate?.pageViewWillBeginDragging(_:) {
            function(self)
        }
        if self.automaticSlidingInterval > 0 {
            self.cancelTimer()
        }
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if let function = self.delegate?.pageViewWillEndDragging(_: targetIndex:) {
            let contnetOffset = self.scrollDirection == .horizontal ? targetContentOffset.pointee.x :
            targetContentOffset.pointee.y
            let targetItem = lround(Double(contnetOffset/self.collectionViewLayout.itemSpacing))
            function(self, targetItem % self.numberOfItems)
        }
        if self.automaticSlidingInterval > 0 {
            self.startTimer()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let function = self.delegate?.pageViewDidEndDecelerating(_:) {
            function(self)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if let function = self.delegate?.pageViewDidEndScrollAnimation(_:) {
            function(self)
        }
    }
    
}
