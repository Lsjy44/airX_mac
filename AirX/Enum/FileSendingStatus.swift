//
//  FileSendingStatus.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-07-14.
//

import Foundation

/// 文件的发送状态
/// 这些数字对应是和libairx对应的
enum FileSendingStatus: UInt8 {
    case requested = 1              /** 准备发，接收方还没答复 */
    case rejected = 2               /** 接收方明确拒绝 */
    case accepted = 3               /** 接收方同意 */
    case inProgress = 4             /** 正在发 */
    case cancelledBySender = 5      /** 发送方发到一半停止 */
    case cancelledByReceiver = 6    /** 接收方收到一半停止 */
    case completed = 7              /** 发完了，同时接收方数据也处理完毕 */
    case error = 8                  /** 发送过程中发生了其他错误 */
}
