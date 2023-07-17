//
//  StringHash.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation
import CryptoKit

/// Digest一般代表哈希计算的结果，这里赋予Digest把结果转为16进制文本的能力
extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }

    var hexString: String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }
}

/// 为String赋予把当前String内容进行SHA-256哈希的能力
extension String {
    func sha256() -> String? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        return SHA256.hash(data: data).hexString
    }
}
