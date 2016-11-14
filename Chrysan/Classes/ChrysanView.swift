//
//  ChrysanView.swift
//  Chrysan
//
//  Created by Harley on 2016/11/11.
//
//

import UIKit

public class ChrysanView: UIView {
    /// 菊花的状态，不同的状态显示不同的icon
    public enum Status {
        /// 无状态，显示纯文字
        case plain
        /// 执行中，显示菊花
        case running
        /// 进度，环形进度条
        case progress
        /// 成功，显示勾
        case succeed
        /// 错误，显示叉
        case error
        /// 自定义，显示自定义的 icon
        case custom
    }
    
    /// 菊花在视图中水平方向上的偏移，默认为正中
    public var offsetX: CGFloat = 0
    /// 菊花在视图中竖直方向上的偏移，默认为正中
    public var offsetY: CGFloat = 0
    
    /// 遮罩颜色，遮挡 UI 的视图层的颜色，默认透明
    public var maskColor = UIColor.clear
    
    /// 菊花背景样式，使用系统自带的毛玻璃特效，默认为黑色样式
    public var hudStyle = UIBlurEffectStyle.dark {
        didSet {
            effectView.effect = UIBlurEffect(style: hudStyle)
        }
    }
    
    /// 菊花的样式，默认为 white large
    public var chrysanStyle = UIActivityIndicatorViewStyle.whiteLarge
    
    /// icon 及文字颜色，默认为白色
    public var color = UIColor.white
    
    /// 自定义的 icon 图片
    public var customIcon: UIImage? = nil
    
    
    // MARK: - APIs
    
    /// 显示菊花
    ///
    /// - Parameters:
    ///   - status: 显示的状态，默认为 running
    ///   - message: 状态说明文字，默认为 nil
    ///   - delay: 一段时间后自动隐藏，默认0，此时不会自动隐藏
    public func show(_ status: Status = .running, message: String? = nil, hideAfterSeconds delay: Double = 0) {

        self.status = status
        self.message = message

        updateAndShow()
        
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                self.hide()
            })
        }
    }
    
    
    /// 显示处理进度
    ///
    /// - Parameters:
    ///   - progress: 进度值，范围 0 - 1
    ///   - message: 状态文字，默认为nil
    public func show(progress: CGFloat, message: String? = nil) {
        
        self.progress = progress
        show(.progress, message: message, hideAfterSeconds: 0)
    }
    
    
    /// 显示自定义图标
    ///
    /// - Parameters:
    ///   - customIcon: 自定义图标，会被转换为 Template 模式
    ///   - message: 状态文字，默认为 nil
    ///   - delay: 一段时间后自动隐藏，默认0，此时不会自动隐藏
    public func show(customIcon: UIImage, message: String? = nil, hideAfterSeconds delay: Double = 0) {
        
        self.customIcon = customIcon
        show(.custom, message: message, hideAfterSeconds: delay)
    }
    
    public func hide() {
        
        if !isShown {
            return
        }
        
        isShown = false
        
        layer.removeAllAnimations()
        
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }, completion: { finished in
            self.isHidden = true
            self.reset()
        })
    }
    
    // MARK: - Private
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var hudView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var progressView: RingProgressView!
    @IBOutlet weak var effectView: UIVisualEffectView!
    
    @IBOutlet weak var positionX: NSLayoutConstraint!
    @IBOutlet weak var positionY: NSLayoutConstraint!
    @IBOutlet weak var labelSpace: NSLayoutConstraint!
    @IBOutlet weak var messageMinWidth: NSLayoutConstraint!
    @IBOutlet weak var messageToTop: NSLayoutConstraint!
    
    private var isShown = false
    
    private var parent: UIView!
    private var status: Status = .plain
    private var message: String?
    private var progress: CGFloat = 0

    internal class func chrysan(withView parent: UIView) -> ChrysanView? {
        
        if let views = bundle.loadNibNamed("Chrysan", owner: nil, options: nil) as? [ChrysanView], views.count > 0 {
            let chrysan = views[0]
            chrysan.setup(withView: parent)
            return chrysan
        }
        return nil
    }
    
    private class var bundle: Bundle {
        
        var bundle: Bundle = Bundle.main
        let framework = Bundle(for: ChrysanView.classForCoder())
        if let resource = framework.path(forResource: "Chrysan", ofType: "bundle") {
            bundle = Bundle(path: resource) ?? Bundle.main
        }
        
        return bundle
    }
    
    private func setup(withView view: UIView) {
        view.addSubview(self)

        parent = view
        pinEdgesToParent()
        isHidden = true
        
        hudView.layer.cornerRadius = 8
        hudView.clipsToBounds = true
    }
    
    private func pinEdgesToParent() {
        
        self.translatesAutoresizingMaskIntoConstraints = false;

        let top = pinToParent(withEdge: .top)
        let bottom = pinToParent(withEdge: .bottom)
        let left = pinToParent(withEdge: .leading)
        let right = pinToParent(withEdge: .trailing)
        
        parent.addConstraints([top, bottom, left, right])
        
        DispatchQueue.main.async {
            self.parent.layoutIfNeeded()
        }
    }
    
    private func pinToParent(withEdge edge: NSLayoutAttribute) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: parent, attribute: edge, relatedBy: .equal, toItem: self, attribute: edge, multiplier: 1, constant: 0)
    }
    
    private func updateAndShow() {
        
        messageLabel.text = message;
        
        positionX.constant = offsetX
        positionY.constant = offsetY
        
        backgroundView.backgroundColor = maskColor
        
        iconView.tintColor = color
        activityView.tintColor = color
        progressView.tintColor = color
        messageLabel.textColor = color
        
        if message != nil && message!.characters.count > 0 {
            labelSpace.constant = 8;
            messageMinWidth.constant = 70;
        }else {
            labelSpace.constant = 4;
            messageMinWidth.constant = 50;
        }

        messageToTop.constant = 64
        activityView.isHidden = true
        progressView.isHidden = true
        iconView.isHidden = true

        switch status {
        case .plain:
            messageToTop.constant = 16
        case .running:
            activityView.isHidden = false
            activityView.activityIndicatorViewStyle = chrysanStyle
        case .progress:
            progressView.isHidden = false
            progressView.progress = progress
        case .succeed:
            iconView.isHidden = false
            iconView.image = image(name: "check")
        case .error:
            iconView.isHidden = false
            iconView.image = image(name: "cross")
        case .custom:
            iconView.isHidden = false
            iconView.image = customIcon
        }
        
        layoutIfNeeded()
        showHUD()
    }
    
    private func image(name: String) -> UIImage? {
        return UIImage(named: "chrysan_\(name).png", in: ChrysanView.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    }
    
    private func showHUD() {
        
        if isShown {
            return
        }
        
        isShown = true
        isHidden = false
        alpha = 0
        
        parent.bringSubview(toFront: self)
        parent.layoutIfNeeded()
        layer.removeAllAnimations()
        
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }
    
    private func reset() {
        iconView.image = nil
        customIcon = nil
        message = nil
        progress = 0
        progressView.progress = 0
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
