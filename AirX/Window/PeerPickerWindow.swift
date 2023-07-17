//
//  PeerPickerWindow.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-07-14.
//

import Foundation
import AppKit
import SwiftUI

/// 选人窗口
class PeerPickerWindow: NSWindow {
    /// 传入所有Peer，用户接下来要选一个
    init(callback: Binding<(Peer) -> Void>) {
        /// 窗口大小等，详见 `FileNoticeWindow.swift`
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 328, height: 328),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        center()
        makeKeyAndOrderFront(nil)
        title = "Peer Picker"
        
        /// 详见 `FileNoticeWindow.swift`
        contentView = NSHostingView(
            rootView: PeerPickerView(callback: callback))
    }
}
