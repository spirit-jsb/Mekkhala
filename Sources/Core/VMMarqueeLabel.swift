//
//  VMMarqueeLabel.swift
//  Mekkhala
//
//  Created by max on 2020/12/15.
//

#if canImport(UIKit)

import UIKit

@IBDesignable public class VMMarqueeLabel: UILabel {
  
  /// 是否无限滚动，默认值为 false
  @IBInspectable public var isInfinite: Bool = false
  
  /// 控制滚动的速度，1 表示一帧滚动 1pt，10 表示一帧滚动 10pt，默认为 0.5
  @IBInspectable public var speed: CGFloat = 0.5
  
  /// 当文字第一次显示在界面上，以及重复滚动到开头时停顿时长，默认为 2.5 秒
  @IBInspectable public var pauseDurationWhenMoveToEdge: TimeInterval = 2.5
  
  /// 首尾链接的间距，默认为 40pt
  @IBInspectable public var spaceBetweenHeadToTail: CGFloat = 40.0
  
  /// 自动判断 label 的 frame 是否超出当前 UIWindow 的显示范围，超出则自动停止动画，默认为 true
  @IBInspectable public var automaticallyValidateVisibleFrame: Bool = true
  
  /// 在文字左右边缘是否显示一个渐变的阴影遮罩，默认为 true
  @IBInspectable public  var shouldFadeAtEdge: Bool {
    get {
      return self._shouldFadeAtEdge
    }
    set {
      self._shouldFadeAtEdge = newValue
      
      self.checkIfShouldShowGradientLayer()
      
      self.setNeedsLayout()
    }
  }
  
  /// 控制左右两端渐隐区域百分比，默认为 20%
  @IBInspectable public var fadeWidthPercent: CGFloat {
    get {
      return self._fadeWidthPercent
    }
    set {
      guard newValue >= 0.0 && newValue <= 1.0 else {
        return
      }
      self._fadeWidthPercent = newValue
      self.fadeEndPercent = newValue
    }
  }
  
  /// 是否从渐隐区域后开始显示，默认为 false
  ///
  /// 当为 true 时，表示文字会从渐隐区域后进行展示，当为 false 时，文字会从边缘进行展示。
  ///
  /// - NOTE
  /// 当文字宽度未超过 label 的宽度时，不会显示渐隐区域，同时也不会影响文字的显示位置。
  @IBInspectable public var textStartAfterFade: Bool = false
  
  public override var text: String? {
    get {
      return super.text
    }
    set {
      super.text = newValue
      
      self.offsetX = 0.0
      self.textSize = self.sizeThatFits(CGSize(width: .max, height: .max))
      
      self.displayLink?.isPaused = !self.shouldPlayDisplayLink()
      
      self.checkIfShouldShowGradientLayer()
      
      self.setNeedsLayout()
    }
  }
  public override var attributedText: NSAttributedString? {
    get {
      return super.attributedText
    }
    set {
      super.attributedText = newValue
      
      self.offsetX = 0.0
      self.textSize = self.sizeThatFits(CGSize(width: .max, height: .max))
      
      self.displayLink?.isPaused = !self.shouldPlayDisplayLink()
      
      self.checkIfShouldShowGradientLayer()
      
      self.setNeedsLayout()
    }
  }
  public override var numberOfLines: Int {
    get {
      return super.numberOfLines
    }
    set {
      super.numberOfLines = 1
    }
  }
  
  private var _fadeWidthPercent: CGFloat = 0.2
  private var _shouldFadeAtEdge: Bool = true
  
  private var displayLink: CADisplayLink?
  
  private var offsetX: CGFloat = .zero
  private var textSize: CGSize = .zero
  
  /// 渐变开始的百分比，默认值为 0%
  private var fadeStartPercent: CGFloat = 0.0
  /// 渐变结束的百分比，默认值为 20%
  private var fadeEndPercent: CGFloat = 0.2
  
  private var isFirstDisplay: Bool = true
  
  private var fadeGradientLayer: CAGradientLayer?
  
  /// 绘制文本时重复绘制次数，用以实现首尾相连的动画效果，默认值为 2
  ///
  /// - NOTE
  /// 当该属性值为1时，表示不首尾相连，值大于1时，表示首尾相连
  private var textRepeatCount: Int = 2
  
  /// 记录上一次布局时的 bounds，如果布局发生变化，则重置动画
  private var prevBounds: CGRect = .zero
    
  private var textRepeatCountConsiderTextWidth: Int {
    return self.textSize.width < self.bounds.width ? 1 : self.textRepeatCount
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    self.didInitialize()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    self.didInitialize()
  }
  
  deinit {
    self.displayLink?.invalidate()
    self.displayLink = nil
  }
  
  public override func didMoveToWindow() {
    super.didMoveToWindow()
    
    if let _ = self.window {
      self.displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
      self.displayLink?.add(to: .current, forMode: .common)
    }
    else {
      self.displayLink?.invalidate()
      self.displayLink = nil
    }
  }
  
  public override func drawText(in rect: CGRect) {
    var textInitialX: CGFloat = 0.0
    
    switch self.textAlignment {
    case .left:
      textInitialX = 0.0
    case .center:
      textInitialX = max(0.0, (self.bounds.width - self.textSize.width) / 2.0)
    case .right:
      textInitialX = max(0.0, self.bounds.width - self.textSize.width)
    default:
      break
    }
    
    // 考虑渐变遮罩的偏移
    var textOffsetXByFade: CGFloat = 0.0
    let shouldTextStartAfterFade: Bool = self.shouldFadeAtEdge && self.textStartAfterFade && self.textSize.width > self.bounds.width
    let fadeWidth = self.bounds.width * 0.5 * max(0.0, self.fadeEndPercent - self.fadeStartPercent)
    
    if shouldTextStartAfterFade && textInitialX < fadeWidth {
      textOffsetXByFade = fadeWidth
    }
    textInitialX += textOffsetXByFade
    
    for index in 0 ..< self.textRepeatCountConsiderTextWidth {
      self.attributedText?.draw(in:CGRect(x: self.offsetX + (self.textSize.width + self.spaceBetweenHeadToTail) * CGFloat(index) + textInitialX, y: rect.minY + (rect.height - self.textSize.height) / 2.0, width: self.textSize.width, height: self.textSize.height))
    }
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    
    if let fadeGradientLayer = self.fadeGradientLayer {
      fadeGradientLayer.frame = self.bounds
    }
    
    if self.prevBounds.size != self.bounds.size {
      self.offsetX = 0.0
      
      self.displayLink?.isPaused = !self.shouldPlayDisplayLink()
      
      self.prevBounds = self.bounds
      
      self.checkIfShouldShowGradientLayer()
    }
  }

  /// 尝试开启滚动动画
  @discardableResult public func startAnimation() -> Bool {
    self.automaticallyValidateVisibleFrame = false
    
    let shouldPlayDisplayLink = self.shouldPlayDisplayLink()
    if shouldPlayDisplayLink {
      self.displayLink?.isPaused = false
    }
    
    return shouldPlayDisplayLink
  }
  
  /// 尝试停止滚动动画
  @discardableResult public func stopAnimation() -> Bool {
    self.displayLink?.isPaused = true
    return true
  }
  
  private func didInitialize() {
    self.lineBreakMode = .byClipping
    self.clipsToBounds = true
    
    self.isUserInteractionEnabled = true
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapMarquee))
    self.addGestureRecognizer(tapGesture)
  }
  
  private func shouldPlayDisplayLink() -> Bool {
    let result = self.window != nil && self.bounds.width > 0.0 && self.textSize.width > self.bounds.width
    
    // 如果 label.frame 在 window 可视区域之外，也视为不可见，暂停掉 displayLink
    if result && self.automaticallyValidateVisibleFrame {
      let rectInWindow = self.window!.convert(self.frame, from: self.superview)
      if !self.window!.bounds.intersects(rectInWindow) {
        return false
      }
    }
    
    return result
  }
  
  private func checkIfShouldShowGradientLayer() {
    let shouldShowFadeLayer = self.window != nil && self.shouldFadeAtEdge && self.bounds.width > 0.0 && self.textSize.width > self.bounds.width
    
    if shouldShowFadeLayer {
      self.fadeGradientLayer = CAGradientLayer()
      self.fadeGradientLayer?.locations = [NSNumber(value: Float(self.fadeStartPercent)), NSNumber(value: Float(self.fadeEndPercent)), NSNumber(value: Float(1.0 - self.fadeEndPercent)), NSNumber(value: Float(1 - self.fadeStartPercent))]
      self.fadeGradientLayer?.startPoint = CGPoint(x: 0.0, y: 0.5)
      self.fadeGradientLayer?.endPoint = CGPoint(x: 1.0, y: 0.5)
      self.fadeGradientLayer?.colors = [UIColor.white.withAlphaComponent(0.0).cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.0).cgColor]
      
      self.layer.mask = self.fadeGradientLayer
      self.setNeedsLayout()
    }
    else {
      if self.layer.mask == self.fadeGradientLayer {
        self.layer.mask = nil
      }
    }
  }
  
  @objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
    if self.offsetX == 0.0 {
      displayLink.isPaused = true
      self.setNeedsDisplay()
      
      let delay = (self.isFirstDisplay || self.textRepeatCount <= 1) ? self.pauseDurationWhenMoveToEdge : 0.0
      
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        displayLink.isPaused = !self.shouldPlayDisplayLink()
        if !displayLink.isPaused {
          self.offsetX -= self.speed
        }
      }
      
      if delay > 0.0 && self.textRepeatCount > 1 {
        self.isFirstDisplay = false
      }
      
      return
    }
    
    self.offsetX -= self.speed
    self.setNeedsDisplay()
    
    if (-self.offsetX >= self.textSize.width + (self.textRepeatCountConsiderTextWidth > 1 ? self.spaceBetweenHeadToTail : 0.0)) {
      displayLink.isPaused = true
      
      let delay = self.textRepeatCount > 1 ? self.pauseDurationWhenMoveToEdge : 0.0
      
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        self.offsetX = 0.0
        
        if self.isInfinite {
          self.handleDisplayLink(displayLink)
        }
      }
    }
  }
  
  @objc private func tapMarquee() {
    if self.displayLink?.isPaused == true {
      self.startAnimation()
    }
  }
}

#endif
