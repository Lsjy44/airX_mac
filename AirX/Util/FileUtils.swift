//
//  FileUtil.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-07-14.
//

import Foundation
import AppKit

/// 文件工具类
class FileUtils {
    /// 转换Windows格式的路径为正常格式
    /// C:\\aaa\\1.txt -> C:/aaa/1.txt
    public static func pathToNormalFormat(_ path: String) -> String {
        return path.replacingOccurrences(of: "\\\\", with: "/")
            .replacingOccurrences(of: "\\", with: "/")
            .replacingOccurrences(of: "//", with: "/")
    }
    
    /// 得到一个绝对路径的目录部分
    /// /Users/miku/1.txt -> /Users/miku/
    public static func getPath(fullPath: String) -> String {
        let path = (pathToNormalFormat(fullPath) as NSString)
            .deletingLastPathComponent
        return path.removingPercentEncoding ?? path
    }
    
    /// 得到一个绝对路径的文件名部分
    /// /Users/miku/1.txt -> 1.txt
    /// C:\aaa\1.txt -> 1.txt
    public static func getFileName(fullPath: String) -> String {
        let path = (pathToNormalFormat(fullPath) as NSString)
            .lastPathComponent
        return path.removingPercentEncoding ?? path
    }
    
    /// 内置的FileId计数器
    private static var fileId: UInt8 = 0;
    
    /// 分配下一个不重复的FileId
    public static func getNextFileId() -> UInt8 {
        if fileId == UInt8.max {
            /// 用完了则从0开始重复利用，只要不出现同时有255个文件在传的场面就够用
            fileId = 0
        }
        defer { fileId += 1; }
        return fileId;
    }
    
    /// 得到`下载`这一目录在当前机器的实际位置
    public static func getDownloadDirectoryUrl() -> URL {
        FileManager.default
            .urls(for: .downloadsDirectory, in: .userDomainMask)
            .first!
    }
    
    /// 把某一文件在Finder中显示并选中
    public static func showInFinder(fullPath: String) {
        NSWorkspace.shared.selectFile(fullPath, inFileViewerRootedAtPath: "")
    }
}
