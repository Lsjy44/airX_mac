//
//  Peer.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-28.
//

import Foundation

/// 一个Peer，代表局域网中，另一个使用AirX的靓仔。自己不是自己的Peer。
/// 继承自Identifiable，不继承会导致SwiftUI报错...原因先不查
// TODO:
class Peer: Identifiable {
    let hostName: String
    let host: String
    let port: UInt16
    
    /// 定义一个随时可取用的sample peer，预览时候用
    public static let sample = Peer(hostName: "Shijunyi", host: "192.168.0.2", port: 9819)
    
    /// 定义description格式为 `Shijunyi@10.0.0.1:9819`
    public var description: String {
        return "\(hostName)@\(host):\(port)"
    }
    
    /// 很多语言都有的模式，构造函数接收参数来填充成员变量，十分的啰嗦
    public init(hostName: String, host: String, port: UInt16) {
        self.hostName = hostName
        self.host = host
        self.port = port
    }
    
    /// 上面`description`的逆向操作，从description解析出Peer对象
    /// Optional是什么意思？一个Optional数据有 some（有） 和 none（冇） 两种状态
    /// 其实就是比较优雅的空值处理
    /// Peer format: <hostname>@<host>:<port>
    public static func parse(_ s: String) -> Optional<Peer> {
        // Incomplete peer string?
        var peerString = s;
        
        /// 有时候description会简化成不带`@`的形式，这里特殊处理一下
        if !peerString.contains("@") {
            peerString = "<empty>@" + s;
        }
        
        /// part1 = ["Shijunyi", "10.0.0.1:9819"]
        let part1 = peerString.split(separator: "@")
        guard part1.count == 2 else {
            /// 若part1不是恰好2个成员，说明数据有问题
            return .none
        }
        
        /// part2 = ["10.0.0.1", "9819"]
        let part2 = part1[1].split(separator: ":")
        guard part2.count == 2 else {
            /// 若part2不是恰好2个成员，说明数据有问题
            return .none
        }
        
        let hostname = part1[0]
        let host = part2[0]
        let port = UInt16(part2[1])
        return .some(Peer(hostName: String(hostname), host: String(host), port: port!))
    }
}
