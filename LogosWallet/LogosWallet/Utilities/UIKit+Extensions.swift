//
//  UIKit+Extensions.swift
//  LogosWallet
//
//  Created by Ben Kray on 12/22/17.
//  Copyright © 2017 Promethean Labs. All rights reserved.
//

import UIKit
import CoreGraphics

extension UIImage {
    // Note: original implementation from breadwallet's app:
    static func qrCode(data: Data?, color: CIColor) -> UIImage? {
        guard let data = data else { return nil }
        let qrFilter = CIFilter(name: "CIQRCodeGenerator")
        let maskFilter = CIFilter(name: "CIMaskToAlpha")
        let invertFilter = CIFilter(name: "CIColorInvert")
        let colorFilter = CIFilter(name: "CIFalseColor")
        var filter = colorFilter
        
        qrFilter?.setValue(data, forKey: "inputMessage")
        qrFilter?.setValue("L", forKey: "inputCorrectionLevel")
        
        let inputKey = "inputImage"
        if Double(color.alpha) > .ulpOfOne {
            invertFilter?.setValue(qrFilter?.outputImage, forKey: inputKey)
            maskFilter?.setValue(invertFilter?.outputImage, forKey: inputKey)
            invertFilter?.setValue(maskFilter?.outputImage, forKey: inputKey)
            colorFilter?.setValue(invertFilter?.outputImage, forKey: inputKey)
            colorFilter?.setValue(color, forKey: "inputColor0")
        } else {
            maskFilter?.setValue(qrFilter?.outputImage, forKey: inputKey)
            filter = maskFilter
        }
        
        let context = CIContext(options: [kCIContextUseSoftwareRenderer: true])
        objc_sync_enter(context)
        defer { objc_sync_exit(context) }
        guard let outputImage = filter?.outputImage else { return nil }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    func resize(_ size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        guard let cgImage = self.cgImage else { return nil }
        
        context.interpolationQuality = .none
        context.rotate(by: .pi)
        context.scaleBy(x: -1.0, y: 1.0)
        context.draw(cgImage, in: context.boundingBoxOfClipPath)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func maskWithColor(_ color: UIColor) -> UIImage? {
        guard let maskImage = cgImage else { return nil }
        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)
        
        if let cgImage = context.makeImage() {
            let coloredImage = UIImage(cgImage: cgImage)
            return coloredImage
        } else {
            return nil
        }
    }
}

extension UIColor {
    convenience init(rgb: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.init(red: rgb/255.0, green: green/255.0, blue: blue/255.0, alpha: alpha)
    }
}

extension UINavigationBar {
    func makeTransparent() {
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
        isTranslucent = true
    }
}

extension UITableView {
    func register<T: Identifiable>(_ cellType: T.Type) {
        let nib = UINib(nibName: cellType.identifier, bundle: nil)
        register(nib, forCellReuseIdentifier: cellType.identifier)
    }
    
    func register(_ reuseIdentifier: String) {
        let nib = UINib(nibName: reuseIdentifier, bundle: nil)
        register(nib, forCellReuseIdentifier: reuseIdentifier)
    }
    
    func dequeueReusableCell<T: Identifiable>(_ cellType: T.Type, for indexPath: IndexPath) -> T {
        let cell = dequeueReusableCell(withIdentifier: T.identifier, for: indexPath)
        
        if rowHeight == UITableViewAutomaticDimension {
            // resize frame
            cell.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            cell.layoutIfNeeded()
        }
        
        return cell as! T
    }
    
    func reloadData(completion handler: @escaping () -> Void) {
        UIView.animate(withDuration: 0, animations: {
            self.reloadData()
        }) { _ in
            // On complete
            handler()
        }
    }
}

extension UIViewController {
    
    static var topMost: UIViewController? {
        var top = UIApplication.shared.keyWindow?.rootViewController
        while top?.presentedViewController != nil {
            top = top?.presentedViewController
        }
        return top
    }
    
    func showTextDialogue(_ message: String, placeholder: String, keyboard: UIKeyboardType = .decimalPad, completion: @escaping (UITextField) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
            textField.autocapitalizationType = .words
            textField.placeholder = placeholder
            textField.keyboardType = keyboard
        })
        let enterAction = UIAlertAction(title: "Enter", style: .default) { _ in
            guard let textField = alertController.textFields?.first else { return }
            completion(textField)
        }
        let cancelAction = UIAlertAction(title: String.localize("cancel"), style: .cancel, handler: nil)
        alertController.addAction(enterAction)
        alertController.preferredAction = enterAction
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
}

extension UIDevice {
    static var isIPhoneX: Bool {
        return UIScreen.main.nativeBounds.height == 2436
    }
}

extension UITabBar {
    func orderedTabBarItemViews() -> [UIView] {
        let interactionViews = self.subviews.filter({$0.isUserInteractionEnabled})
        return interactionViews.sorted(by: {$0.frame.minX < $1.frame.minX})
    }
    
    func frame(forItemAt index: Int) -> CGRect {
        let views = orderedTabBarItemViews()
        guard index < views.count else { return .zero }
        return views[index].frame
    }
}

protocol FromNib {
    func viewFromNib() -> UIView
    func setupView(frame: CGRect?)
}

extension UIView: FromNib {
    func viewFromNib() -> UIView {
        return UINib(nibName: String(describing: type(of: self)), bundle: nil).instantiate(withOwner: self, options: nil).first as! UIView
    }
    
    func setupView(frame: CGRect? = nil) {
        let deviceView = viewFromNib()
        deviceView.autoresizingMask = [.flexibleWidth, .flexibleWidth]
        if let f = frame {
            deviceView.frame = f
        } else {
            deviceView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        }
        addSubview(deviceView)
    }
}

extension UIView {
    static func line(_ color: UIColor? = AppStyle.Color.superLightGrey) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.snp.makeConstraints { (make) in
            make.height.equalTo(1.0)
        }

        return view
    }

    func mask(viewToMask: UIView, maskRect: CGRect, invert: Bool = false, cornerRadius: CGFloat = 0.0) {
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        if (invert) {
            path.addRect(viewToMask.bounds)
        }
        if cornerRadius > 0.0 {
            let rounded = UIBezierPath(roundedRect: maskRect, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            path.addPath(rounded.cgPath)
        } else {
            path.addRect(maskRect)
        }
        
        maskLayer.path = path
        if (invert) {
            maskLayer.fillRule = kCAFillRuleEvenOdd
        }
        viewToMask.layer.mask = maskLayer;
    }
    
    func addShadow(_ intensity: Float = 0.2, radius: CGFloat = 3.0, offset: CGSize = CGSize(width: 0.0, height: 1.0)) {
        layer.masksToBounds = false
        layer.shadowRadius = radius
        layer.shadowOpacity = intensity
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = offset
    }
    
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }

    /// Finds a common superview between self and a specified view.
    ///
    /// - Parameter with: The view to find a common superview with.
    /// - Returns: A common superview if one is found, otherwise, self.
    func commonSuperview(with view: UIView) -> UIView? {
        var result: UIView? = self
        while let test = result, !view.isDescendant(of: test) {
            result = test.superview
        }

        return result
    }

    @discardableResult
    func constrain(_ view: UIView, attribute: NSLayoutConstraint.Attribute, toView: UIView, toAttribute: NSLayoutConstraint.Attribute, constant: CGFloat = 0.0, relatedBy: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1.0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        let constraint = NSLayoutConstraint(item: view, attribute: attribute, relatedBy: relatedBy, toItem: toView, attribute: toAttribute, multiplier: multiplier, constant: constant)

        if let priority = priority {
            constraint.priority = priority
        }
        self.addConstraint(constraint)

        return constraint
    }

    /// Pins the top edges to the top edges of a specified view.
    ///
    /// - Parameter to: The view to pin top edges to.
    /// - Parameter offset: An offset between edges, defaults to `0.0`.
    /// - Parameter priority: An optional layout priority.
    /// - Returns: An activated `NSLayoutConstraint` if one is created.
    @discardableResult
    func pinTopEdges(to view: UIView, offset: CGFloat = 0.0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint? {
        return self.commonSuperview(with: view)?.constrain(self, attribute: .top, toView: view, toAttribute: .top, constant: offset, priority: priority)
    }

    /// Pins the bottom edges to the bottom edges of a specified view.
    ///
    /// - Parameter to: The view to pin bottom edges to.
    /// - Parameter offset: An offset between edges, defaults to `0.0`.
    /// - Parameter priority: An optional layout priority.
    /// - Returns: An activated `NSLayoutConstraint` if one is created.
    @discardableResult
    func pinBottomEdges(to view: UIView, offset: CGFloat = 0.0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint? {
        return self.commonSuperview(with: view)?.constrain(self, attribute: .bottom, toView: view, toAttribute: .bottom, constant: offset, priority: priority)
    }

    /// Pins the left edges to the left edges of a specified view.
    ///
    /// - Parameter to: The view to pin left edges to.
    /// - Parameter offset: An offset between edges, defaults to `0.0`.
    /// - Parameter priority: An optional layout priority.
    /// - Returns: An activated `NSLayoutConstraint` if one is created.
    @discardableResult
    func pinLeftEdges(to view: UIView, offset: CGFloat = 0.0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint? {
        return self.commonSuperview(with: view)?.constrain(self, attribute: .left, toView: view, toAttribute: .left, constant: offset, priority: priority)
    }

    /// Pins the right edges to the right edges of a specified view.
    ///
    /// - Parameter to: The view to pin right edges to.
    /// - Parameter offset: An offset between edges, defaults to `0.0`.
    /// - Parameter priority: An optional layout priority.
    /// - Returns: An activated `NSLayoutConstraint` if one is created.
    @discardableResult
    func pinRightEdges(to view: UIView, offset: CGFloat = 0.0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint? {
        return self.commonSuperview(with: view)?.constrain(self, attribute: .right, toView: view, toAttribute: .right, constant: -offset, priority: priority)
    }


    /// Pins this view above a specified view.
    ///
    /// - Parameter above: The view to pin above.
    /// - Parameter offset: An offset between views, defaults to `0.0`.
    /// - Parameter priority: An optional layout priority.
    /// - Returns: An activated `NSLayoutConstraint` if one is created.
    @discardableResult
    func pin(above view: UIView, offset: CGFloat = 0.0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint? {
        return self.commonSuperview(with: view)?.constrain(self, attribute: .bottom, toView: view, toAttribute: .top, constant: offset, priority: priority)
    }

    /// Pins this view below a specified view.
    ///
    /// - Parameter below: The view to pin below.
    /// - Parameter offset: An offset between views, defaults to `0.0`.
    /// - Parameter priority: An optional layout priority.
    /// - Returns: An activated `NSLayoutConstraint` if one is created.
    @discardableResult
    func pin(below view: UIView, offset: CGFloat = 0.0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint? {
        return self.commonSuperview(with: view)?.constrain(self, attribute: .top, toView: view, toAttribute: .bottom, constant: offset, priority: priority)
    }

    /// Pins any specified attributes to the superview.
    ///
    /// - Parameter attributes: A variadic list of `NSLayoutConstraint.Attribute` to pin.
    /// - Parameter offset: An offset between attributes, defaults to `0.0`. All attributes would share the same offset.
    /// - Parameter priority: An optional layout priority.
    /// - Returns: A list of activated constraints in the same order they're specified as params.
    @discardableResult
    func pinToSuperview(_ attributes: NSLayoutConstraint.Attribute..., offset: CGFloat = 0.0, priority: UILayoutPriority? = nil) -> [NSLayoutConstraint] {
        guard let superview = self.superview else {
            return []
        }

        self.translatesAutoresizingMaskIntoConstraints = false
        let constraints = attributes.map {
            NSLayoutConstraint(item: self, attribute: $0, relatedBy: .equal, toItem: superview, attribute: $0, multiplier: 1.0, constant: $0 == .right ? -offset : offset)
        }
        superview.addConstraints(constraints)

        return constraints
    }

    /// Horizontally and vertically centers the view within its superview.
    ///
    /// - Parameter offset: An offset from both centers, defaults to `0.0`.
    /// - Parameter priority: An optional layout priority.
    /// - Returns: A tuple of activated constraints if they're created.
    @discardableResult
    func centerInSuperview(_ offset: CGFloat = 0.0, priority: UILayoutPriority? = nil) -> (x: NSLayoutConstraint?, y: NSLayoutConstraint?) {
        let xConstraint = self.centerHorizontally(offset, priority: priority)
        let yConstraint = self.centerVertically(offset, priority: priority)
        return (xConstraint, yConstraint)
    }

    /// Horizontally centers the view within its superview.
    ///
    /// - Parameter offset: An offset from the horizontal center, defaults to `0.0`.
    /// - Parameter priority: An optional layout priority.
    /// - Returns: An activated `NSLayoutConstraint` if one is created.
    @discardableResult
    func centerHorizontally(_ offset: CGFloat = 0.0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint? {
        guard let superview = self.superview else {
            return nil
        }
        return superview.constrain(self, attribute: .centerX, toView: superview, toAttribute: .centerX, constant: offset, priority: priority)
    }

    /// Vertically centers the view within its superview.
    ///
    /// - Parameter offset: An offset from the vertical center, defaults to `0.0`.
    /// - Parameter priority: An optional layout priority.
    /// - Returns: An activated `NSLayoutConstraint` if one is created.
    @discardableResult
    func centerVertically(_ offset: CGFloat = 0.0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint? {
        guard let superview = self.superview else {
            return nil
        }
        return superview.constrain(self, attribute: .centerY, toView: superview, toAttribute: .centerY, constant: offset, priority: priority)
    }


    /// Sizes a view to the specified height and width.
    ///
    /// - Parameter height: The height value to set.
    /// - Parameter width: The width value to set.
    /// - Returns: A tuple of activated constraints.
    @discardableResult
    func size(height: CGFloat, width: CGFloat) -> (height: NSLayoutConstraint, width: NSLayoutConstraint) {
        self.translatesAutoresizingMaskIntoConstraints = false
        let height = self.heightAnchor.constraint(equalToConstant: height)
        let width = self.widthAnchor.constraint(equalToConstant: width)
        self.addConstraints([height, width])

        return (height, width)
    }

    /// Sizes a view to the specified height.
    ///
    /// - Parameter height: The height value to set.
    /// - Returns: An activated `NSLayoutConstraint` if one is created.
    @discardableResult
    func size(height: CGFloat) -> NSLayoutConstraint {
        let height = self.heightAnchor.constraint(equalToConstant: height)
        height.isActive = true
        self.translatesAutoresizingMaskIntoConstraints = false

        return height
    }

    /// Sizes a view to the specified width.
    ///
    /// - Parameter width: The width value to set.
    //// - Returns: An activated `NSLayoutConstraint` if one is created.
    @discardableResult
    func size(width: CGFloat) -> NSLayoutConstraint {
        let width = self.widthAnchor.constraint(equalToConstant: width)
        width.isActive = true
        self.translatesAutoresizingMaskIntoConstraints = false

        return width
    }

}

extension UIEdgeInsets {
    static let noSeparator: UIEdgeInsets = UIEdgeInsetsMake(0, 10000, 0, 0)
}

extension UIButton {
    func toggle(_ shouldEnable: Bool, enableColor: UIColor, disableColor: UIColor) {
        isEnabled = shouldEnable
        backgroundColor = shouldEnable ? enableColor : disableColor
    }
    
    // Switching the title with animation will cause the UIButton to flash. To avoid the flash, set animated to false.
    func changeTitle(to value: String, animated: Bool = false) {
        if animated {
            setTitle(value, for: .normal)
        } else {
            UIView.performWithoutAnimation {
                setTitle(value, for: .normal)
                layoutIfNeeded()
            }
        }
    }
}

// MARK: - Identifier

protocol Identifiable {
    static var identifier: String { get }
}

extension Identifiable {
    static var identifier: String { return String(describing: self) }
}

extension Identifiable where Self: UIView {
    static func instantiate() -> Self {
        let view = Bundle.main.loadNibNamed(self.identifier, owner: self, options: nil)!.first
        return view as! Self
    }
}

extension UITableViewCell: Identifiable { }

extension UINib {
    convenience init<T: Identifiable>(_ type: T.Type, bundle: Bundle? = nil) {
        self.init(nibName: type.identifier, bundle: bundle)
    }
}
