//
//  UIUtil.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation
import AppKit
import SwiftUI

class UIUtil {
    public static func hideDockIcons() {
        NSApplication.shared.setActivationPolicy(.prohibited)
    }
    
    public static func showDockIcons() {
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    public static func createWindow(_ openWindowAction: OpenWindowAction, windowId: WindowIds) {
        showDockIcons()
        openWindowAction(id: windowId.rawValue)
        
        // 啊？
        NSApplication.activate(NSApplication.shared)
            .self(ignoringOtherApps: true)
    }
}
