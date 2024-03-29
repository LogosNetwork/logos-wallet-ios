//
//  Banner.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/30/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation
import NotificationBannerSwift

struct Banner {

    static var currentBanner: NotificationBanner?

    enum MessageType {
        case success
        case warning
        case error
    }
    
    static func show(_ message: String, title: String? = nil, style:  BannerStyle, in view: UIViewController? = nil) {
        self.currentBanner?.dismissDuration = 0.0
        self.currentBanner?.dismiss()

        let banner = NotificationBanner(title: message, subtitle: title, style: style)
        if let view = view {
            banner.show(on: view)
        } else {
            banner.show()
        }

        self.currentBanner = banner
    }
}
