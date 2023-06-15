//
//  TextNotice.swift
//  SwiftUIPractice
//
//  Created by 刘世俊懿 on 2023-05-12.
//

import Foundation
import SwiftUI
import Combine


struct TextNoticeView: View {
    @ObservedObject var viewModel = TextNoticeViewModel.shared
    @State private var text: String = ""
    @State private var isSyncing: Bool = false
    @Binding var theme: Theme
    
    var body: some View {
        let truncatedText = truncatedText(text, maxLength: 10)
        
        ZStack {
            VStack (spacing: 0){
                theme.gray
                    .frame(height: 126)
                theme.blue
                    .frame(height: 42)
            }
            .frame(width: 317, height: 168)
            
            
            VStack (spacing: 0){
                // 上半部分
                VStack(alignment: .leading) {
                    Spacer().frame(height: 27) //间隔
                    
                    HStack {
                        Text(truncatedText).font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.textColor)
                            .onReceive(viewModel.$receivedText) { newText in text = newText}
                        
                        Spacer() // 将文本推向左侧
                    }
                    
                    Spacer() //间隔
                    
                    HStack {
                        Text("From \(viewModel.from)").font(.system(size: 13))
                            .foregroundColor(theme.textColor)
                        Spacer() // 将文本推向左侧
                    }
                    
                    Spacer().frame(height: 10)
                }
                .frame(height: 126)
                .padding(.leading) // 在左侧添加一些间距
                
                // 下半部分
                HStack {
                    Text("COPIED.")
                        .foregroundColor(theme.progressTrack) // 设置数字颜色
                        .font(.system(size: 13, weight: .bold)) // 设置字体大小为13并加粗
                        .padding(.leading, 17) // 在左侧添加一些间距
                        .padding(.vertical) // 在顶部和底部添加垂直填充
                    
                    Spacer()
                    
                    // Block 按钮
                    Button(action: {
                        // 处理 Block 按钮点击事件
                        viewModel.showTextNotice = false
                    }) {
                        Text("BLOCK")
                            .font(.system(size: 13, weight: .bold)) // 设置字体大小为13并加粗
                            .foregroundColor(theme.buttonText) // 按钮颜色
                            .frame(width: 46, height: 16) // 设置按钮大小
                            .background(theme.blue) // 设置按钮背景颜色
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical) // 在顶部和底部添加垂直填充
                    
                    Spacer().frame(width: 15)
                    
                }
                .frame(height: 42)
            }
        }
        .frame(width: 317, height: 168)
    }
}

func truncatedText(_ message: String, maxLength: Int) -> String {
    if message.count <= maxLength {
        return message
    }
    let prefix = message.prefix(5)
    let suffix = message.suffix(4)
    return "\(prefix)...\(suffix)"
}

struct TextNotice_Previews: PreviewProvider {
    static var previews: some View {
        // TextNotice 弹窗
        TextNoticeView(theme: .constant(LightMode()))
    }
}

