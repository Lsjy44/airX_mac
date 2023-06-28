//
//  FileNotice.swift
//  SwiftUIPractice
//
//  Created by 刘世俊懿 on 2023-05-12.
//

import Foundation
import SwiftUI
import Combine

struct FileNotice: View {
    @State private var text: String = ""
    @State private var progress: Double = 0.65
    @State private var isSyncing: Bool = false
    
    @State private var filename: String = "你怎么知道我这段文字已经超过了最大限制.pdf"
    @State private var fileSizeRepresentation: String = "12.2 MB"
    @State private var fileFrom: String = "File from " + String(airx_version())
    @State private var theme: Theme = DarkMode()
    
    var body: some View {
        ZStack {
            VStack (spacing: 0){
                theme.gray
                    .frame(height: 126)
                theme.blue
                    .frame(height: 42)
            }
            .frame(width: 317, height: 168)
            
                        Spacer() // 将文本推向左侧
            
            VStack (spacing: 0){
                // 上半部分
                VStack(alignment: .leading) {
                    Spacer().frame(width: 27) //间隔
                    
                    HStack {
                        Text(truncatedFilename(filename, maxLength: 10))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.textColor)
                        
                    }
                    HStack {
                        Text(fileSizeRepresentation).font(.system(size: 16))
                            .foregroundColor(theme.textColor)
                        Spacer() // 将文本推向左侧
                    }
                    
                    Spacer().frame(width: 21) //间隔
                    
                    HStack {
                        Text(fileFrom).font(.system(size: 13))
                            .foregroundColor(theme.textColor)
                        Spacer() // 将文本推向左侧
                    }
                    
                    Spacer().frame(height: 10)
                }
                .frame(height: 126)
                .padding(.leading) // 在左侧添加一些间距
                
                // 下半部分
                HStack {
                    if progress < 1.0 {
                        // 进度条
                        ProgressView(value: progress)
                            .frame(width: 75, height: 7)
                            .progressViewStyle(ColoredProgressViewStyle(color: theme.progressColor)) // 进度条颜色
                            .background(theme.progressTrack) // 设置进度条未完成部分的背景色
                            .padding(.leading, 17) // 在左侧添加一些间距
                            .padding(.vertical) // 在顶部和底部添加垂直填充
                        
                        Text("\(Int(progress * 100))%")
                            .foregroundColor(theme.progressTrack) // 设置数字颜色
                            .font(.system(size: 13, weight: .bold)) // 设置字体大小为13并加粗
                            .padding(.leading, 5) // 在左侧添加一些间距
                        
                        Spacer()
                        
                        // STOP 按钮
                        Button(action: {
                            // 处理 STOP 按钮点击事件
                        }) {
                            Text("STOP")
                                .font(.system(size: 13, weight: .bold)) // 设置字体大小为13并加粗
                                .foregroundColor(theme.buttonText) // 按钮颜色
                                .frame(width: 37, height: 16) // 设置按钮大小
                                .background(theme.blue) // 设置按钮背景颜色
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical) // 在顶部和底部添加垂直填充
                        
                        Spacer()
                            .frame(width: 26) // 在两个按钮之间创建空间
                        
                        // Block 按钮
                        Button(action: {
                            // 处理 Block 按钮点击事件
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
                        
                    } else {
                        Spacer()
                            .frame(width: 17)//间距
                        
                        // OPEN FOLDER 按钮
                        Button(action: {
                            // 处理 OPEN FOLDER 按钮点击事件
                        }) {
                            Text("OPEN FOLDER")
                                .font(.system(size: 13, weight: .bold)) // 设置字体大小为13并加粗
                                .foregroundColor(theme.buttonText) // 按钮颜色
                                .frame(width: 100, height: 16) // 设置按钮大小
                                .background(theme.blue) // 设置按钮背景颜色
                                .cornerRadius(8) // 添加圆角
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.clear, lineWidth: 1) // 移除按钮的边框
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical) // 在顶部和底部添加垂直填充
                        
                        Spacer()// 在两个按钮之间创建空间
                        
                        // Block 按钮
                        Button(action: {
                            // 处理 Block 按钮点击事件
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
                }
                .frame(height: 42)
                
            }
        }
        .frame(width: 317, height: 168)
    }
}

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
        FileNotice()
    }
}

