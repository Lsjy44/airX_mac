//
//  FileNotice.swift
//  SwiftUIPractice
//
//  Created by 刘世俊懿 on 2023-05-12.
//

import Foundation
import SwiftUI

/// 正式来到SwiftUI！
/// 新文件窗口
struct FileNoticeView: View {
    /// 要求使用`presentationMode`能力
    /// 其实就是用来主动关闭当前窗口的...
    @Environment(\.presentationMode) var presentationMode

    /// 暂时主题锁定为亮色
    @State private var theme: Theme = LightMode()
    
    /// 本View绑定着的对应的`ReceivingFile`
    @ObservedObject var receivingFile: ReceiveFile
    
    /// 加入黑名单按钮
    func onBlock() {
        /// 确认弹窗
        guard UIUtils.alertBox(
            title: "Stop",
            message: "Are you sure to block \(receivingFile.from.description)?",
            primaryButtonText: "Block",
            secondaryButtonText: "Don't Block"
        ) == .alertFirstButtonReturn else {
            return
        }
        
        /// 进行加黑名单操作
        AccountUtils.blockUser(peer: receivingFile.from)
    }
    
    /// 停止传输
    func onStop() {
        /// 确认弹窗
        guard UIUtils.alertBox(
            title: "Stop",
            message: "Are you sure to stop receiving the file?",
            primaryButtonText: "Stop",
            secondaryButtonText: "Don't Stop"
        ) == .alertFirstButtonReturn else {
            return
        }

        /// 更新文件状态为已经停止
        receivingFile.status = .cancelledByReceiver
        
        /// 关闭本窗口，写法有点怪，网上查的最好办法
        presentationMode.wrappedValue.dismiss()
    }
    
    /// 打开所在文件夹
    func onOpenFolder() {
        FileUtils.showInFinder(
            fullPath: receivingFile.localSaveFullPath.path(percentEncoded: false))
    }
    
    /// 界面布局
    var body: some View {
        /// 计算出传输进度百分比
        let progressPercent = Double(receivingFile.progress) / Double(receivingFile.totalSize)
        
        ZStack {
            // 背景
            VStack (spacing: 0) {
                theme.gray.frame(height: 126)
                theme.blue.frame(height: 42)
            }
            .frame(width: 317, height: 168)
            
            Spacer()
            
            VStack (spacing: 0) {
                VStack(alignment: .leading) {
                    Spacer().frame(width: 27)
                    
                    HStack {
                        // 文件名
                        Text(
                            truncatedFilename(
                                FileUtils.getFileName(
                                    fullPath: receivingFile.localSaveFullPath.path(percentEncoded: false)),
                                maxLength: 10)
                        )
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.textColor)
                    }
                    
                    // 大小
                    HStack {
                        Text(receivingFile.sizeRepresentation)
                            .font(.system(size: 16))
                            .foregroundColor(theme.textColor)
                        Spacer() // 将文本推向左侧
                    }
                    
                    Spacer().frame(width: 21)
                    
                    // 来自
                    HStack {
                        Text("From \(receivingFile.from.description)")
                            .font(.system(size: 13))
                            .foregroundColor(theme.textColor)
                        Spacer() // 将文本推向左侧
                    }
                    
                    Spacer().frame(height: 10)
                }
                .frame(height: 126)
                .padding(.leading) // 在左侧添加一些间距
                
                // 下半部分
                HStack {
                    // 进度条
                    ProgressView(value: progressPercent)
                        .frame(width: 75, height: 7)
                        .progressViewStyle(ColoredProgressViewStyle(color: theme.progressColor))
                        .background(theme.progressTrack) // 设置进度条未完成部分的背景色
                        .padding(.leading, 17)
                        .padding(.vertical)
                    
                    Text(String(format: "%.2f%%", progressPercent * 100))
                        .foregroundColor(theme.textColor)
                        .font(.system(size: 9, weight: .bold))
                    
                    Spacer()
                    
                    if progressPercent == 1 {
                        // 传输完成，显示Open Folder
                        Button("OPEN FOLDER", action: onOpenFolder)
                            .buttonStyle(.plain)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(theme.buttonText)
                            .padding(.vertical)
                            .focusable(false)
                    }
                    else {
                        // 传输没完成，显示Stop
                        Button("STOP", action: onStop)
                            .buttonStyle(.plain)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(theme.buttonText)
                            .padding(.vertical)
                            .focusable(false)
                    }
                    
                    Spacer().frame(width: 26)
                    
                    Button("BLOCK", action: onBlock)
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(theme.buttonText)
                        .padding(.vertical)
                        .focusable(false)

                    Spacer().frame(width: 15)
                }
                .frame(height: 42)
            } // VStack
        }.frame(width: 317, height: 168) // ZStack
    } // some View
}

/// 能够给进度条上色的自定义进度条
struct ColoredProgressViewStyle: ProgressViewStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
            .padding(.vertical)
            .progressViewStyle(LinearProgressViewStyle(tint: color))
    }
}

func truncatedFilename(_ filename: String, maxLength: Int) -> String {
    if filename.count <= maxLength {
        return filename
    }
    
    let suffix = filename.split(separator: ".").last ?? ""
    let basename = filename.prefix(while: { $0 != "." })
    
    if basename.count > maxLength {
        let startIndex = filename.startIndex
        let truncatedIndex = filename.index(startIndex, offsetBy: maxLength - suffix.count - 1)
        return "\(filename[startIndex...truncatedIndex])….\(suffix)"
    }
    
    let truncatedIndex = basename.index(basename.startIndex, offsetBy: maxLength - suffix.count - 1)
    return "\(basename[basename.startIndex...truncatedIndex])….\(suffix)"
}

struct FileNotice_Previews: PreviewProvider {
    static var previews: some View {
        FileNoticeView(
            receivingFile: GlobalState.shared.receiveFiles[255]!)
    }
}
