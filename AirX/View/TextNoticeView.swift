//
//  TextNotice.swift
//  SwiftUIPractice
//
//  Created by 刘世俊懿 on 2023-05-12.
//

import Foundation
import SwiftUI

/// 新文本窗口
struct TextNoticeView: View {
    /// 绑定文本窗口的状态
    @ObservedObject var viewModel = TextNoticeViewModel.shared
    
    /// 绑定外界传进来的，该用哪款主题
    @Binding var theme: Theme
    
    /// 笔记：
    /// `@State` 指本类内部的状态，其值的改变会自动触发更新UI
    /// `@Published` 也是状态，但不是自己用，是给别的类用
    /// `@ObservableObject` 包含了`@Published`的类，它就是一个`@ObservableObject`
    /// `@Binding` 指来自外部的`@State`
    
    /// 原来这里的拉黑功能还没做
    func onBlock() {
        
    }
    
    var body: some View {
        ZStack {
            /// 背景
            VStack (spacing: 0) {
                theme.gray.frame(height: 126)
                theme.blue.frame(height: 42)
            }
            .frame(width: 317, height: 168)
            
            VStack (spacing: 0) {
                VStack(alignment: .leading) {
                    Spacer().frame(height: 27)
                    
                    /// 文本内容
                    HStack {
                        Text(viewModel.receivedText)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.textColor)
                        Spacer()
                    }
                    
                    Spacer()
                    
                    /// 来自
                    HStack {
                        Text("From \(viewModel.from.description)")
                            .font(.system(size: 13))
                            .foregroundColor(theme.textColor)
                        Spacer()
                    }
                    
                    Spacer().frame(height: 10)
                }
                .frame(height: 126)
                .padding(.leading)
                
                HStack {
                    Text("Copied.")
                        .foregroundColor(theme.buttonText)
                        .font(.system(size: 13, weight: .bold))
                        .focusable(false)
                        .padding(.leading, 17)
                        .padding(.vertical)

                    Spacer()

                    Button("BLOCK", action: onBlock)
                        .foregroundColor(theme.buttonText)
                        .font(.system(size: 13, weight: .bold))
                        .focusable(false)
                        .frame(width: 46, height: 16)
                        .background(theme.blue)
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical)
                    
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
        TextNoticeView(theme: .constant(LightMode()))
    }
}
