//
//  ReceiveFile.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-07-14.
//

import Foundation

/// 正接收中的文件的数据模型
/// `ObservableObject`首次亮相，配合`@Published`，让使用这个值的SwiftUI的控件能够及时感知到值的变化、从而更新UI
class ReceiveFile: ObservableObject {
    @Published var remoteFullPath: String       /** 这个文件在发送端的绝对路径 */
    @Published var fileHandle: FileHandle       /** 本地存入文件的文件句柄，用于写入数据 */
    @Published var localSaveFullPath: URL       /** 本地存入文件的绝对路径 */
    @Published var totalSize: UInt64            /** 文件总字节数 */
    @Published var fileId: UInt8                /** 前端分配的FileId，确保在前端这里是唯一的即可 */
    @Published var from: Peer                   /** 发送者 */
    @Published var progress: UInt64             /** 已经传输了多少字节 */
    @Published var status: FileSendingStatus    /** 传输状态 */
    
    /// 把字节数转换为对应的，最合适的单位
    /// 10240 -> 10 KB
    public var sizeRepresentation: String {
        let units = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "啊？", "nb"]
        var unitIndex = 0
        var size = Double(totalSize)
        
        while size > 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }

        // Use %.2f to keep two decimal places
        return String(format: "%.2f \(units[unitIndex])", size)
    }
    
    init(remoteFullPath: String, fileHandle: FileHandle, localSaveFullPath: URL, totalSize: UInt64, fileId: UInt8, from: Peer, progress: UInt64, status: FileSendingStatus) {
        self.remoteFullPath = remoteFullPath
        self.fileHandle = fileHandle
        self.localSaveFullPath = localSaveFullPath
        self.totalSize = totalSize
        self.fileId = fileId
        self.from = from
        self.progress = progress
        self.status = status
    }
    
    /// 一个sample file用于在SwiftUI演示页面用的
    public static let sample = ReceiveFile(
        remoteFullPath: "D:\\test files\\中文 测试\\sample.pdf",
        fileHandle: FileHandle(),
        localSaveFullPath: .downloadsDirectory,
        totalSize: 11451419198106660, // 11.45 PB
        fileId: 255,
        from: .sample,
        progress: 80000,
        status: .inProgress
    )
}
