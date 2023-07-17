//
//  UIUtil.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation
import AppKit
import SwiftUI

/// UI相关工具函数
class UIUtils {
    /// 隐藏本app在Dock栏的图标
    public static func hideDockIcons() {
        NSApplication.shared.setActivationPolicy(.prohibited)
    }
    
    /// 显示本app在Dock栏的图标
    public static func showDockIcons() {
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    /// 创建窗口，需要传入openWindowAction能力，详见 `AirXApp.swift`
    public static func createWindow(_ openWindowAction: OpenWindowAction, windowId: WindowIds) {
        showDockIcons()
        openWindowAction(id: windowId.rawValue)
        
        /// `.activate`返回的是一个函数，导致了这里有些怪异的语法
        NSApplication.activate(NSApplication.shared)
            .self(ignoringOtherApps: true)
    }
    
    /// 显示一个NSWindow
    public static func showNSWindow(_ window: NSWindow) {
        let controller = NSWindowController()
        controller.contentViewController = window.contentViewController
        controller.window = window
        controller.showWindow(self)
    }
    
    /// 弹出信息框让用户选择
    public static func alertBox(
        title: String,
        message: String,
        primaryButtonText: String,            /** 第一个按钮的内容 */
        secondaryButtonText: String? = nil,   /** 第二个按钮内容。可以不要第二个按钮 */
        thirdButtonText: String? = nil        /** 第三个按钮内容。可以不要第三个按钮 */
    ) -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: primaryButtonText)
        
        if let secondaryButtonText {
            alert.addButton(withTitle: secondaryButtonText)
        }
        
        if let thirdButtonText {
            alert.addButton(withTitle: thirdButtonText)
        }
        
        alert.alertStyle = .informational
        return alert.runModal()
    }
    
    /// 选择文件的窗口，如果用户选了，返回URL，如果用户没选，返回none
    public static func pickFile() -> Optional<URL> {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else {
            return .none
        }
        return panel.url
    }
}
