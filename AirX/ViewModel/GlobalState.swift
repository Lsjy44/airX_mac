//
//  GlobalState.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-15.
//

import Foundation

/// 全局状态
class GlobalState: ObservableObject {
    /// AirX服务是否启动了
    @Published var isServiceOnline: Bool = false
    
    /// 是否登录
    @Published var isSignedIn: Bool = false
    
    /// 程序是否正在退出中
    @Published var isApplicationExiting: Bool = false
    
    /// 所有正接收中的文件，其中fileId=255固定为sample
    @Published var receiveFiles: Dictionary<UInt8, ReceiveFile> = [255: .sample];
    
    /// 单一实例。有关单例模式，参见 https://zh.wikipedia.org/wiki/单例模式
    static let shared = GlobalState()
}
