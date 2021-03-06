//
//  YRPageControl.swift
//  YRPageView
//
//  Created by kilrae on 2017/4/12.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

open class YRPageControl: UIControl {

    /// The number of page indicators of the page control. Default is 0.
    @IBInspectable
    open var numberOfPages: Int = 0 {
        didSet {
            self.setNeedsCreateIndicators()
        }
    }
    
    /// The current page, highlighted by the page control. Default is 0.
    @IBInspectable
    open var currentPage: Int = 0 {
        didSet {
            self.setNeedsUpdateIndicators()
        }
    }
    
    /// The spacing to use of page indicators in the page control.
    @IBInspectable
    open var itemSpacing: CGFloat = 6 {
        didSet {
            self.setNeedsUpdateIndicators()
        }
    }
    
    /// The spacing to use between page indicators in the page control.
    @IBInspectable
    open var interitemSpacing: CGFloat = 6 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    /// The distance that the page indicators is inset from the enclosing page control.
    @IBInspectable
    open var contentInsets: UIEdgeInsets = .zero {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    /// The horizontal alignment of content within the control’s bounds. Default is center.
    open override var contentHorizontalAlignment: UIControlContentHorizontalAlignment {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    internal var strokeColors: [UIControlState: UIColor] = [:]
    internal var fillColors: [UIControlState: UIColor] = [:]
    internal var paths: [UIControlState: UIBezierPath] = [:]
    internal var images: [UIControlState: UIImage] = [:]
    internal var alphas: [UIControlState: CGFloat] = [:]
    internal var transforms: [UIControlState: CGAffineTransform] = [:]
    
    fileprivate weak var contentView: UIView!
    
    fileprivate var needsUpdateIndicators = false
    fileprivate var needsCreateIndicators = false
    fileprivate var indicatorLayers = [CAShapeLayer]()
    
    fileprivate var runLoopObserver: CFRunLoopObserver?
    fileprivate var runLoopCallback: CFRunLoopObserverCallBack = {
        (observer: CFRunLoopObserver?, activity: CFRunLoopActivity, info: UnsafeMutableRawPointer?) -> Void in
        guard let info = info else {
            return
        }
        let pageControl = Unmanaged<YRPageControl>.fromOpaque(info).takeUnretainedValue()
        pageControl.createIndicatorsIfNecessary()
        pageControl.updateIndicatorsIfNecessary()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), self.runLoopObserver, .commonModes);
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.frame = {
            let x = self.contentInsets.left
            let y = self.contentInsets.top
            let width = self.frame.width - self.contentInsets.left - self.contentInsets.right
            let height = self.frame.height - self.contentInsets.top - self.contentInsets.bottom
            let frame = CGRect(x: x, y: y, width: width, height: height)
            return frame
        }()
    }
    
    open override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        
        let diameter = self.itemSpacing
        let spacing = self.interitemSpacing
        var x: CGFloat = {
            switch self.contentHorizontalAlignment {
            case .left:
                return 0
            case .center, .fill:
                let midX = self.contentView.bounds.midX
                let amplitude = CGFloat(self.numberOfPages/2) * diameter + spacing*CGFloat((self.numberOfPages-1)/2)
                return midX - amplitude
            case .right:
                let contentWidth = diameter*CGFloat(self.numberOfPages) + CGFloat(self.numberOfPages-1)*spacing
                return contentView.frame.width - contentWidth
            }
        }()
        for (index,value) in self.indicatorLayers.enumerated() {
            let state: UIControlState = (index == self.currentPage) ? .selected : .normal
            let image = self.images[state]
            let size = image?.size ?? CGSize(width: diameter, height: diameter)
            let origin = CGPoint(x: x - (size.width-diameter)*0.5, y: self.contentView.bounds.midY-size.height*0.5)
            value.frame = CGRect(origin: origin, size: size)
            x = x + spacing + diameter
        }
        
    }
    
    /// Sets the stroke color for page indicators to use for the specified state. (selected/normal).
    ///
    /// - Parameters:
    ///   - strokeColor: The stroke color to use for the specified state.
    ///   - state: The state that uses the specified stroke color.
    @objc(setStrokeColor:forState:)
    open func setStrokeColor(_ strokeColor: UIColor?, for state: UIControlState) {
        guard self.strokeColors[state] != strokeColor else {
            return
        }
        self.strokeColors[state] = strokeColor
        self.setNeedsUpdateIndicators()
    }
    
    /// Sets the fill color for page indicators to use for the specified state. (selected/normal).
    ///
    /// - Parameters:
    ///   - fillColor: The fill color to use for the specified state.
    ///   - state: The state that uses the specified fill color.
    @objc(setFillColor:forState:)
    open func setFillColor(_ fillColor: UIColor?, for state: UIControlState) {
        guard self.fillColors[state] != fillColor else {
            return
        }
        self.fillColors[state] = fillColor
        self.setNeedsUpdateIndicators()
    }
    
    /// Sets the image for page indicators to use for the specified state. (selected/normal).
    ///
    /// - Parameters:
    ///   - image: The image to use for the specified state.
    ///   - state: The state that uses the specified image.
    @objc(setImage:forState:)
    open func setImage(_ image: UIImage?, for state: UIControlState) {
        guard self.images[state] != image else {
            return
        }
        self.images[state] = image
        self.setNeedsUpdateIndicators()
    }
    
    @objc(setAlpha:forState:)
    
    /// Sets the alpha value for page indicators to use for the specified state. (selected/normal).
    ///
    /// - Parameters:
    ///   - alpha: The alpha value to use for the specified state.
    ///   - state: The state that uses the specified alpha.
    open func setAlpha(_ alpha: CGFloat, for state: UIControlState) {
        guard self.alphas[state] != alpha else {
            return
        }
        self.alphas[state] = alpha
        self.setNeedsUpdateIndicators()
    }
    
    /// Sets the path for page indicators to use for the specified state. (selected/normal).
    ///
    /// - Parameters:
    ///   - path: The path to use for the specified state.
    ///   - state: The state that uses the specified path.
    @objc(setPath:forState:)
    open func setPath(_ path: UIBezierPath?, for state: UIControlState) {
        guard self.paths[state] != path else {
            return
        }
        self.paths[state] = path
        self.setNeedsUpdateIndicators()
    }
    
    // MARK: - Private functions
    
    fileprivate func commonInit() {
        
        // Content View
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.clear
        self.addSubview(view)
        self.contentView = view
        
        // RunLoop
        let runLoop = CFRunLoopGetCurrent()
        let activities: CFRunLoopActivity = [.entry,.afterWaiting]
        var context = CFRunLoopObserverContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        self.runLoopObserver = CFRunLoopObserverCreate(nil, activities.rawValue, true, Int.max, self.runLoopCallback, &context)
        CFRunLoopAddObserver(runLoop, self.runLoopObserver, .commonModes)
        
    }
    
    fileprivate func setNeedsUpdateIndicators() {
        self.needsUpdateIndicators = true
        self.setNeedsLayout()
    }
    
    fileprivate func updateIndicatorsIfNecessary() {
        guard self.needsUpdateIndicators else {
            return
        }
        guard self.indicatorLayers.count > 0 else {
            return
        }
        self.needsUpdateIndicators = false
        self.indicatorLayers.forEach { (layer) in
            self.updateIndicatorAttributes(for: layer)
        }
    }
    
    fileprivate func updateIndicatorAttributes(for layer: CAShapeLayer) {
        let index = self.indicatorLayers.index(of: layer)
        let state: UIControlState = index == self.currentPage ? .selected : .normal
        if let image = self.images[state] {
            layer.strokeColor = nil
            layer.fillColor = nil
            layer.path = nil
            layer.contents = image.cgImage
        } else {
            layer.contents = nil
            let strokeColor = self.strokeColors[state]
            let fillColor = self.fillColors[state]
            if strokeColor == nil && fillColor == nil {
                layer.fillColor = (state == .selected ? UIColor.white : UIColor.gray).cgColor
                layer.strokeColor = nil
            } else {
                layer.strokeColor = strokeColor?.cgColor
                layer.fillColor = fillColor?.cgColor
            }
            layer.path = self.paths[state]?.cgPath ?? UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: self.itemSpacing, height: self.itemSpacing)).cgPath
        }
        if let transform = self.transforms[state] {
            layer.transform = CATransform3DMakeAffineTransform(transform)
        }
        layer.opacity = Float(self.alphas[state] ?? 1.0)
    }
    
    fileprivate func setNeedsCreateIndicators() {
        self.needsCreateIndicators = true
    }
    
    fileprivate func createIndicatorsIfNecessary() {
        guard self.needsCreateIndicators else {
            return
        }
        self.needsCreateIndicators = false
        self.indicatorLayers.forEach { (layer) in
            layer.removeFromSuperlayer()
        }
        self.indicatorLayers.removeAll()
        for _ in 0..<self.numberOfPages {
            let layer = CAShapeLayer()
            layer.actions = ["bounds": NSNull()]
            self.contentView.layer.addSublayer(layer)
            self.indicatorLayers.append(layer)
        }
        self.setNeedsUpdateIndicators()
        self.updateIndicatorsIfNecessary()
    }


}

extension UIControlState: Hashable {
    public var hashValue: Int {
        return Int((6777*self.rawValue+3777)%UInt(UInt16.max))
    }
}
