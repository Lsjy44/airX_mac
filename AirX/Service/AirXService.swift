//
//  AirXService.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation
import AppKit

/// AirX服务的封装类

// Global interrupt flag.
/// 是否停服？
private var interrupt = false

/// 剪贴板对象
private var pasteboard = NSPasteboard.general

/// 上次复制的文本
private var lastIncomingString = ""

/// 所有subscribers，概念参见 `AirXApp.swift`
private var textChangeSubscribers = Dictionary<String, (String, Peer) -> Void>()
private var fileSendingProgressSubscribers = Dictionary<String, (UInt8, UInt64, UInt64, FileSendingStatus) -> Void>();
private var fileComingSubscribers = Dictionary<String, (UInt64, String, Peer) -> Void>();
private var filePartSubscribers = Dictionary<String, (UInt8, UInt64, UInt64, Data) -> Bool>();

/// 是否应该停服，交给libairx去调用的
private func shouldInterrupt() -> Bool {
    return interrupt
}

/// 函数意义参见 `AirXApp.swift` 的同名函数
/// 为什么这里又有一个OnFilePart？
/// 因为首先由libairx通知到这里这个OnFilePart，然后这里再通知所有Subscribers
/// Return true to interrupt the transmission.
private func onFilePart(
    fileId: UInt8,
    offset: UInt64,
    length: UInt64,
    data: UnsafePointer<UInt8>?
) -> Bool {
    /// Data为空？
    guard let data else {
        return false
    }
    
    /// 将数据从指针包装为Swift的Data
    let dataManaged = Data(bytes: data, count: Int(length))

    /// 通知每个subscriber
    for subscriber in filePartSubscribers.values {
        /// 某个subscriber要求关闭连接，就关闭，后续的subscribers没有通知必要了
        /// 为什么要关闭，如何关闭的，参见`AirXApp.swift`
        if subscriber(fileId, offset, length, dataManaged) {
            return true
        }
    }
    return false
}

/// 函数意义参见 `AirXApp.swift` 的同名函数
private func onFileSendingProgress(
    fileId: UInt8,
    progress: UInt64,
    total: UInt64,
    status: UInt8
) {
    for subscriber in fileSendingProgressSubscribers.values {
        subscriber(fileId, progress, total, .init(rawValue: status) ?? .requested)
    }
}

/// 函数意义参见 `AirXApp.swift` 的同名函数
private func onFileComing(
    fileSize: UInt64,
    fileNameStringPointer: UnsafePointer<CChar>?,
    fileNameStringLength: UInt32,
    sourceIpAddressStringPointer: UnsafePointer<CChar>?,
    sourceIpAddressStringLength: UInt32
) {
    guard let fileNameStringPointer, let sourceIpAddressStringPointer else {
        return
    }
    
    /// 将文本从指针读入Swift的String
    let fileName = String(cString: fileNameStringPointer, length: Int(fileNameStringLength))
    let sourceIpAddressString = String(cString: sourceIpAddressStringPointer, length: Int(sourceIpAddressStringLength))
    
    /// 读入失败？
    guard let fileName, let sourceIpAddressString else {
        return
    }
    
    /// 解析出peer数据。Peer的概念参见 `Peer.swift`
    let peer = Peer.parse(sourceIpAddressString)
    
    /// 解析失败？
    guard let peer else {
        print("Peer parsing failed.")
        return
    }
    
    for subscriber in fileComingSubscribers.values {
        subscriber(fileSize, fileName, peer)
    }
}

/// 函数意义参见 `AirXApp.swift` 的同名函数
private func onTextReceived(
    incomingStringPointer: UnsafePointer<CChar>?,
    incomingStringLength: UInt32,
    sourceIpAddressStringPointer: UnsafePointer<CChar>?,
    sourceIpAddressStringLength: UInt32
) {
    guard let incomingStringPointer, let sourceIpAddressStringPointer else {
        return
    }
    
    /// 将文本从指针读入Swift的String
    let incomingString = String(cString: incomingStringPointer, length: Int(incomingStringLength))
    let sourceIpAddressString = String(cString: sourceIpAddressStringPointer, length: Int(sourceIpAddressStringLength))
    
    /// 读入失败？
    guard let incomingString, let sourceIpAddressString else {
        return
    }
    
    /// 解析出peer数据。Peer的概念参见 `Peer.swift`
    let peer = Peer.parse(sourceIpAddressString)
    
    /// 解析失败？
    guard let peer else {
        print("Peer parsing failed.")
        return
    }

    // Copy string to pasteboard.
    pasteboard.declareTypes([.string], owner: nil)
    lastIncomingString = incomingString
    guard pasteboard.setString(incomingString, forType: .string) else {
        /// 复制失败？
        return
    }
    
    for subscriber in textChangeSubscribers.values {
        subscriber(incomingString, peer)
    }
}

class AirXService {
    // AirX service opaque structure.
    private static var airxPointer: OpaquePointer?  = .none

    // Pasteboard last change count and content.
    private static var lastPasteboardChangeCount    = NSPasteboard.general.changeCount
    private static var lastPasteboardContent        = NSPasteboard.general.string(forType: .string) ?? ""
    
    // Timer for monitoring the clipboard.
    private static var timer: Timer?                = .none
    
    /// 其实就两个成员，分别承担Data Service和Discovery Service
    // Workers.
    private static var threads: Array<Thread>       = .init()
    
    // Configurations.
    public static let discoveryServiceServerPort   = Defaults.int(.discoveryServiceServerPort)
    public static let discoveryServiceClientPort   = Defaults.int(.discoveryServiceClientPort)
    public static let textServiceListenPort        = Defaults.int(.textServiceListenPort)
    public static let groupIdentity                = Defaults.int(.groupIdentity)
    public static let host                         = "0.0.0.0"

    
    /// 这四个subscribe参见 `AirXApp.swift`
    public static func subscribeToTextChange(id: String, handler: @escaping (String, Peer) -> Void) {
        textChangeSubscribers[id] = handler
    }
    
    public static func subscribeToFileSendingProgress(id: String, handler: @escaping (UInt8, UInt64, UInt64, FileSendingStatus) -> Void) {
        fileSendingProgressSubscribers[id] = handler
    }
    
    public static func subscribeToFilePart(id: String, handler: @escaping (UInt8, UInt64, UInt64, Data) -> Bool) {
        filePartSubscribers[id] = handler
    }
    
    public static func subscribeToFileComing(id: String, handler: @escaping (UInt64, String, Peer) -> Void) {
        fileComingSubscribers[id] = handler
    }
    
    /// 开服！
    public static func startAsync() {
        /// 判断是否已经开了
        guard threads.isEmpty else {
            return
        }
        
        /// 调用libairx，凡是字符串这种复杂类型都要先退化为指针
        /// 也就是toBuffer
        let hostBuffer = host.toBuffer()
        
        airxPointer = airx_create(
            UInt16(discoveryServiceServerPort),
            UInt16(discoveryServiceClientPort),
            hostBuffer,
            host.utf8Size(),
            UInt16(textServiceListenPort),
            UInt32(groupIdentity)
        )
        
        /// 指针用完记得手动释放
        hostBuffer.deallocate()
        
        // Run text and lan discovery service in seperate threads.
        threads.append(Thread(block: {
            airx_data_service(
                airxPointer,
                onTextReceived,
                onFileComing,
                onFileSendingProgress,
                onFilePart,
                shouldInterrupt
            )
        }))
        threads.append(Thread(block: {
            airx_lan_discovery_service(airxPointer, shouldInterrupt)
        }))
        
        // Reset interrupt flag and start the services!
        interrupt = false
        for t in threads {
            t.start()
        }
        
        /// 开始监听剪贴板
        startMonitoringClipboard()
        
        /// 更新全局状态，全局状态参见 `GlobalState.swift`
        GlobalState.shared.isServiceOnline = true
    }

    // Services stop at their next ticks.
    public static func initiateStopAsync() {
        interrupt = true
        
        /// Stop all threads
        for t in threads {
            t.cancel()
        }
        threads.removeAll()
        
        /// 停止监听剪贴板
        stopMonitoringClipboard()

        /// 更新状态
        GlobalState.shared.isServiceOnline = false
    }
    
    /// 读取当前Peers列表
    public static func readCurrentPeers() -> [Peer] {
        /// 准备好足够的内存空间
        let buffer = UnsafeMutablePointer<CChar>
            .allocate(capacity: 4096)
        
        /// 调用libairx读取Peers，同时得到数据的字节数
        let len = Int(airx_get_peers(airxPointer, buffer))

        /// 字符串封口，形成 zero-terminated string，
        /// 概念参见 https://zh.wikipedia.org/wiki/C风格字符串
        buffer.advanced(by: len).update(repeating: 0, count: 1)
        
        /// defer的作用是在函数结束后（return后）做收尾工作
        /// 这里是需要把buffer内存释放掉
        defer { buffer.deallocate() }
        
        /// 将buffer的内容先读入Swift的String，
        /// 然后用逗号分隔，
        /// 最后逐个解析成Peer对象，形成Peer数组，返回
        return String(cString: buffer)
            .split(separator: .init(unicodeScalarLiteral: ","))
            .map({ substring in Peer.parse(String(substring))! })
    }
    
    /// 发送文件的封装
    public static func trySendFile(host: String, filePath: String) {
        /// 逆转UrlEncode，概念详见 `AirXApp.swift`
        let filePathUrlDecoded = filePath.removingPercentEncoding ?? filePath
        
        let hostBuffer = host.toBuffer()
        let pathBuffer = filePathUrlDecoded.toBuffer()
        
        airx_try_send_file(
            airxPointer!,
            hostBuffer,
            host.utf8Size(),
            pathBuffer,
            filePathUrlDecoded.utf8Size()
        )
    }
    
    /// 响应一个文件是否要接收
    public static func respondToFile(host: String, fileId: UInt8, fileSize: UInt64, remoteFullPath: String, accept: Bool) {
        let hostBuffer = host.toBuffer()
        let remoteFullPathBuffer = remoteFullPath.toBuffer()
        
        airx_respond_to_file(
            airxPointer!,
            hostBuffer,
            host.utf8Size(),
            fileId,
            fileSize,
            remoteFullPathBuffer,
            remoteFullPath.utf8Size(),
            accept
        )
    }
    
    /// 读取字符串形式的libairx版本信息
    public static func readVersionString() -> String {
        /// 准备buffer
        let buffer = UnsafeMutablePointer<CChar>
            .allocate(capacity: 128)
        
        /// 读取，顺便获得读取的字节数
        let len = Int(airx_version_string(buffer))
        
        // Ensure zero terminated
        /// 字符串封口
        buffer.advanced(by: len).update(repeating: 0, count: 1)
        
        /// 适当时刻释放刚刚allocate的内存
        defer { buffer.deallocate() }
        
        /// 内存读入Swift的String
        return String(cString: buffer)
    }
    
    /// 监听剪贴板变化的简易措施
    private static func startMonitoringClipboard() {
        /// 开始之前先停止，防止重复开始
        stopMonitoringClipboard()
        
        /// 每0.5秒，做：
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            /// 如果0.5秒前和现在的剪贴板内容对比，发现内容改变
            if self.lastPasteboardChangeCount != pasteboard.changeCount {
                self.lastPasteboardChangeCount = pasteboard.changeCount
                
                /// 则进行复制，并更新 last 信息，这样下一个0.5秒的时候，现在的信息会成为届时的 last
                if let newContent = pasteboard.string(forType: .string), newContent != self.lastPasteboardContent {
                    self.lastPasteboardContent = newContent
                    self.onPasteboardChanged(newContent: newContent)
                }
            }
        }
    }
    
    /// 停止监听剪贴板
    private static func stopMonitoringClipboard() {
        timer?.invalidate()
        timer = nil
    }
    
    /// 当本机剪贴板内容变化
    private static func onPasteboardChanged(newContent: String) {
        /// 判断是不是别人发给自己才导致的变化
        guard newContent != lastIncomingString else {
            /// 如果是，不要又把它发出去一遍，不然就循环了
            // Prevent recursive copy-send.
            print("Prevented recursive copy-send.")
            return
        }

        print("Clipboard changed, broadcasting new text.")
        let buffer = newContent.toBuffer()
        airx_broadcast_text(airxPointer!, buffer, newContent.utf8Size())
        buffer.deallocate()
    }
}
