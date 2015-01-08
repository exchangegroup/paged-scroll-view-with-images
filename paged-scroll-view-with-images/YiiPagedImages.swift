//
//  PagedStoryboardObject.swift
//  paged-scroll-view-with-images
//
//  Created by Evgenii Neumerzhitckii on 24/11/2014.
//  Copyright (c) 2014 The Exchange Group Pty Ltd. All rights reserved.
//

import UIKit

class YiiPagedImages: NSObject, UIScrollViewDelegate {
  @IBOutlet weak var scrollView: UIScrollView!
  private let pageControl = UIPageControl()
  private let pagedControlContainer = TegPagedControlContainer()
  
  weak var delegate: TegPagedImagesCellViewDelegate?
  
  var settings = TegPagedImagesSettings()
  
  deinit {
    cancelImageDownloads()
  }
  
  func setup() {
    scrollView.pagingEnabled = true
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.delegate = self
    pageControl.backgroundColor = nil
    setupPageControl()
  }
  
  func add(image: UIImage) {
    TegPagedImages.loadImage(image, scrollView: scrollView,
      imageSize: imageSize, settings: settings, delegate: delegate)
    
    updateNumberOfPages()
  }
  
  func addRemote(url: String) {
    TegPagedImages.addUrl(url, scrollView: scrollView, imageSize: imageSize,
      placeholderImage: placeholderImage, settings: settings, delegate: delegate)
    
    updateNumberOfPages()
    notifyCellsAboutTheirVisibility()
  }
  
  func removeAllImagesWithAnimation(onFinished: (()->())? = nil) {
    if numberOfImages == 0 {
      onFinished?()
      return
    }
    
    UIView.animateWithDuration(settings.fadeInAnimationDuration,
      animations: {
        self.scrollView.alpha = 0
        self.pagedControlContainer.alpha = 0
      },
      completion: { finished in
        for subview in self.scrollView.subviews {
          subview.removeFromSuperview()
        }
        
        self.scrollView.alpha = 1
        self.pagedControlContainer.alpha = 1
        self.updateNumberOfPages()
        onFinished?()
      }
    )
  }
  
  var numberOfImages: Int {
    return scrollView.subviews.count
  }
  
  private func setupPageControl() {
    if let currentSuperview = scrollView.superview {
      currentSuperview.insertSubview(pagedControlContainer, aboveSubview: scrollView)
      pagedControlContainer.addSubview(pageControl)
      pagedControlContainer.backgroundColor = TegColors.Shade60.uiColor.colorWithAlphaComponent(0.2)
      pagedControlContainer.layer.cornerRadius = 10
      
      pagedControlContainer.setTranslatesAutoresizingMaskIntoConstraints(false)
      pageControl.setTranslatesAutoresizingMaskIntoConstraints(false)
      
      // Align page control container with the bottom of the scroll view
      TegAutolayoutConstraints.alignSameAttributes(pagedControlContainer, toItem: scrollView, constraintContainer: currentSuperview, attribute: NSLayoutAttribute.Bottom, margin: -5)
      
      // Horizontally center page control container with the scroll view
      TegAutolayoutConstraints.centerX(pagedControlContainer, viewTwo: scrollView, constraintContainer: currentSuperview)
      
      // Fill page control to the width of its container
      TegAutolayoutConstraints.fillParent(pageControl, parentView: pagedControlContainer, margin: 7,
        vertically: false)
      
      // Vertically align page control and its container
      TegAutolayoutConstraints.centerY(pageControl, viewTwo: pagedControlContainer,
        constraintContainer: currentSuperview)
      
      updateNumberOfPages()
    }
  }
  
  private var imageSize: CGSize {
    scrollView.layoutIfNeeded()
    return scrollView.bounds.size
  }
  
  private var placeholderImage: UIImage? {
    return UIImage(named: settings.placeholderImageName)
  }
  
  private func updateNumberOfPages() {
    let numberOfPages = numberOfImages
    pageControl.numberOfPages = numberOfPages
    pagedControlContainer.invalidateIntrinsicContentSize()
    pagedControlContainer.hidden = numberOfPages < 2
  }
  
  private func updateCurrentPage() {
    let xOffset = scrollView.contentOffset.x + scrollView.frame.size.width / 2
    let currentPage = Int(xOffset / scrollView.frame.size.width)
    pageControl.currentPage = currentPage
  }
  
  private func notifyCellsAboutTheirVisibility() {
    for cell in cellViews {
      if TegPagedImages.subviewVisible(scrollView, subview: cell) {
        cell.cellIsVisible()
      } else {
        if !TegPagedImages.isSubviewNearScreenEdge(scrollView, subview: cell) {
          // Do not send 'invisible' message to cell if it is still nearby
          // This prevents cancelling download for the cell that was shown for a moment
          // with spring animation
          cell.cellIsInvisible()
        }
      }
    }
  }
  
  private func cancelImageDownloads() {
    for cell in cellViews {
      cell.cancelImageDownload()
    }
  }
  
  private var cellViews: [TegPagedImagesCellView] {
    return scrollView.subviews.filter { return $0 is TegPagedImagesCellView }.map { $0 as TegPagedImagesCellView }
  }
}

// UIScrollViewDelegate
// --------------------------

typealias UIScrollViewDelegate_implementation = YiiPagedImages

extension UIScrollViewDelegate_implementation {
  func scrollViewDidScroll(scrollView: UIScrollView) {
    updateCurrentPage()
    notifyCellsAboutTheirVisibility()
  }
}