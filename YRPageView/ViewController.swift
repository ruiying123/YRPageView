//
//  ViewController.swift
//  YRPageView
//
//  Created by kilrae on 2017/4/12.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    fileprivate let imageNames: [String] = ["1.jpg", "2.jpg", "3.jpg", "4.jpg", "5.jpg", "6.jpg", "7.jpg"]
    
    lazy var pageView: YRPageView = {
        let pageView = YRPageView(frame: .zero)
        pageView.itemSize = .zero
        pageView.register(YRPageViewCell.self, forCellWithReuseIdentifier: "cell")
        return pageView
    }()
    
    lazy var pageControl: YRPageControl = {
        let pageControl = YRPageControl(frame: .zero)
        pageControl.numberOfPages = self.imageNames.count
        pageControl.contentHorizontalAlignment = .center
        pageControl.contentInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return pageControl
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(pageView)
        pageView.dataSource = self
        pageView.delegate = self
        view.addSubview(pageControl)
    }
    
    
    override func viewWillLayoutSubviews() {
        pageView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 350)
        pageControl.frame = CGRect(x: 0, y: 350-50, width: view.bounds.width, height: 50)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: YRPageViewDataSource {
    func numberOfItems(pageView: YRPageView) -> Int {
        return imageNames.count
    }
    
    func pageView(_ pageView: YRPageView, cellForItemAt index: Int) -> YRPageViewCell {
        let cell = pageView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        cell.imageView?.image = UIImage(named: imageNames[index])
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.clipsToBounds = true
//        cell.textLabel?.text = index.description
        return cell
    }
    
}

extension ViewController: YRPageViewDelegate {
    func pageView(_ pageView: YRPageView, didSelectItemAtIndex index: Int) {
        pageView.deselectItem(at: index, animation: true)
        pageView.scrollToitem(at: index, animated: true)
        pageControl.currentPage = index
    }
    
    func pageViewDidScroll(_ pageView: YRPageView) {
        guard self.pageControl.currentPage != pageView.currentIndex else {
            return
        }
        pageControl.currentPage = pageView.currentIndex
    }
}

