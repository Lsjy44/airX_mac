//
//  FileHandleEnsureLength.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-07-14.
//

import Foundation

/// 为FileHandle赋予提前占据硬盘空间的能力
extension FileHandle {
    func ensureSize(_ size: UInt64) -> Bool {
        /// 移动游标失败？
        guard let _ = try? seekToEnd() else {
            return false
        }

        var bytesWritten = 0
        while bytesWritten < size {
            /// 用若干块32768 Bytes的空数据填充某个文件
            /// 最后一块儿大小小于等于32768
            let chunkSize = min(32768, Int(size) - bytesWritten)
            let chunk = Data(count: chunkSize)
            guard let _ = try? write(contentsOf: chunk) else {
                return false
            }
            bytesWritten += chunkSize
        }
        
        /// 把游标重新移回起始位置，方便从头写数据
        guard let _ = try? seek(toOffset: 0) else {
            return false
        }
        return true
    }
}
