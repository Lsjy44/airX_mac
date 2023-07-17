//
//  FileNoticeWindow.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-07-14.
//

import Foundation
import AppKit
import SwiftUI

/// 新文件窗口
class FileNoticeWindow: NSWindow {
    /// 接收一个FileId，这个窗口和这个file绑定
    init(fileId: UInt8) {
        /// 设置窗口大小、有标题栏、可关闭
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 317, height: 196),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,   /** 可能是双缓冲吧，了解必要不大，参见 https://gpp.tkchu.me/double-buffer.html */
            defer: false   /** 不认识 */
        )
        
        /// 居中在屏幕中心
        center()
        
        /// 不认识
        makeKeyAndOrderFront(nil)
        
        /// 设置窗口标题
        title = "File Notice"
        
        if let receivingFile = GlobalState.shared.receiveFiles[fileId] {
            /// 设置本窗口实际内容为FileNoticeView
            /// `NSHostingView`用于把传统窗口和SwiftUI View之间建立关联
            contentView = NSHostingView(
                rootView: FileNoticeView(receivingFile: receivingFile))
        }
        else {
            /// FildId不存在？
            contentView = NSHostingView(rootView: Text("Error"))
        }
    }
}
