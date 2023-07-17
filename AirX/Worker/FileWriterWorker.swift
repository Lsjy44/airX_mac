//
//  FileWriterWorker.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-07-14.
//

import Foundation

/// 负责写入文件的后台worker
class FileWriterWorker {
    /// 文件块的队列
    private let queue = BlockingQueue<FilePartWorkload>()
    
    /// 工作线程
    private var workerThread: Thread?
    
    /// 是否停止线程
    private var shouldInterrupt = false
    
    /// 添加一份工作内容，即：哪个文件、写哪里、写什么
    public func addWorkload(_ workload: FilePartWorkload) {
        queue.enqueue(item: workload)
    }
    
    /// 开始不断等待工作的到来、处理工作
    public func start() {
        /// 判断是否已经在工作了
        guard workerThread == nil else {
            return
        }

        /// 捕捉self，这样在线程内部可以访问到queue
        workerThread = Thread { [self] in
            while !shouldInterrupt {
                let workload = queue.dequeue()
                handleSingleWorkload(workload)
            }
        }
        workerThread?.start()
    }
    
    /// 停止工作
    public func stop() {
        shouldInterrupt = true
        workerThread = nil
    }
    
    /// 处理单件任务
    private func handleSingleWorkload(_ workload: FilePartWorkload) {
        /// 判断对应文件是否不存在
        guard let file = GlobalState.shared.receiveFiles[workload.fileId] else {
            return
        }
        
        /// 判断这个文件用户还要不要
        guard file.status != .cancelledByReceiver else {
            debugPrint("File cancelled!")

            /// fileHandle也是流式写入的，所以用完也要记得关闭
            try? file.fileHandle.close()

            /// 从全局状态中移除这个文件
            GlobalState.shared.receiveFiles.removeValue(forKey: workload.fileId)
            return
        }
        
        // In progress.
        do {
            /// 跳到文件对应位置，写入对应数据
            try file.fileHandle.seek(toOffset: workload.offset)
            try file.fileHandle.write(contentsOf: workload.data)
        }
        catch {
            // 以上两步都可能出错，一旦出错，更新文件状态
            // 为什么明明没更新UI，也要用UI线程执行？因为file是ObservableObject，改变status会自动更新UI的
            DispatchQueue.main.async {
                file.status = .error
            }
            return
        }
    
        /// 更新总进度
        DispatchQueue.main.async {
            file.progress += workload.length
            file.status = .inProgress
        }
        
        /// 总进度达到文件总大小，视为传输+保存成功
        // Finished?
        if file.progress == file.totalSize {
            /// 更新状态
            DispatchQueue.main.async {
                file.status = .completed
            }
            
            /// 关闭水龙头
            try? file.fileHandle.close()
            debugPrint("File receive completed!")
        }
    }
    
    public struct FilePartWorkload {
        public let fileId: UInt8
        public let offset: UInt64
        public let length: UInt64
        public let data: Data
        
        init(fileId: UInt8, offset: UInt64, length: UInt64, data: Data) {
            self.fileId = fileId
            self.offset = offset
            self.length = length
            self.data = data
        }
    }
}
