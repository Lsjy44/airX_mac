//
//  ClipboardMonitor.swift
//  SwiftUIPractice
//
//  Created by 刘世俊懿 on 2023-05-21.
//

import Foundation
import SwiftUI
import AppKit

/// 另一个全局状态
class TextNoticeViewModel: ObservableObject {
    /// 是否显示新文本弹窗，好像没用了
    @Published var showTextNotice: Bool = false
    
    /// 收到了什么文本
    @Published var receivedText: String = "你好"
    
    /// 发送者
    @Published var from: Peer = .sample
    
    /// 单例，参见`GlobalState.swift`相同位置
    static let shared = TextNoticeViewModel()
}
