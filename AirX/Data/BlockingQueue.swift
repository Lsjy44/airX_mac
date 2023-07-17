//
//  BlockingQueue.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-07-14.
//

import Foundation

/// 信号量实现的阻塞队列，dequeue操作将会阻塞直到队内有成员了为止，它是线程安全的
/// 此外和普通队列没有区别
class BlockingQueue<T> {
    private let semaphore = DispatchSemaphore(value: 0)
    private var queue = [T]()
    
    func enqueue(item: T) {
        queue.append(item)
        semaphore.signal()
    }
    
    func dequeue() -> T {
        semaphore.wait()
        return queue.removeFirst()
    }
}
