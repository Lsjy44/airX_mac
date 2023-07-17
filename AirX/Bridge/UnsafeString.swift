//
//  UnsafeString.swift
//  SwiftUIPractice
//
//  Created by Hatsune Miku on 2023-01-29.
//

import Foundation

/// 对String的扩展
extension String {
    /// 把String的文本内容，写入一个指针所指向的内存处
    /// 返回写入了的byte数
    /// Write UTF8 representation of string to a raw buffer.
    func writeTo(buffer: UnsafeMutablePointer<UInt8>) -> Int {
        /// 确保UTF8编码
        let data = self.data(using: .utf8)!
        
        /// 打开对于buffer的输出流
        /// 什么是流？就是如流水一样源源不断的写入数据
        /// 为什么要用流？因为有的数据很多，不是一次性能够写完的，要慢慢流。和倒水一样
        let stream = OutputStream(toBuffer: buffer, capacity: data.count)
        stream.open()
        
        /// 开流
        do {
            /// 把data转换成字节数组，即数据的原始表现形式
            try data.withUnsafeBytes({ (p: UnsafeRawBufferPointer) throws -> Void in
                /// 写入
                stream.write(
                    p.bindMemory(to: UInt8.self).baseAddress!,  /** `bindMemory`一套操作，是为了得到真正的原始指针：一串长整数 */
                    maxLength: data.count
                )
            })
            /// 其实根本一口气就写入完成了，用不到流的
            /// 不过用了也没有副作用，而且不得不用
        }
        catch {
            /// 转换失败怎么办？官方代码说了`withUnsafeBytes`会出错，但是没说会出什么错
            /// 所以先空着
        }
        
        /// 水龙头用完要关闭
        stream.close()
        
        /// 返回写入了多少字节，方便调用方确定指针指向的内存长度
        return data.count
    }
    
    /// 上面那个函数是自备指针，这个是连指针也给准备好了
    /// 返回指针，用完记得调用`deallocate`释放这个指针，否则内存泄露
    func toBuffer() -> UnsafeMutablePointer<UInt8> {
        let data = self.data(using: .utf8)!
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        _ = self.writeTo(buffer: buffer)
        return buffer
    }
    
    /// 获得一个字符串的实际UTF8字节数
    /// 难道直接`.length`不可以吗？"中文测试" length=4，但是实际字节数=12
    func utf8Size() -> UInt32 {
        return UInt32(self.data(using: .utf8)!.count)
    }
}
