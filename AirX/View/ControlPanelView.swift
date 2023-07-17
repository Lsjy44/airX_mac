//
//  PanelView.swift
//  SwiftUIPractice
//
//  Created by Hatsune Miku on 2023-忘了.
//

import SwiftUI

/// 控制面板类
/// 这个类的代码相对陈旧，还没来得及施工
struct ControlPanelView: View {
    /// 存放所有Peers
    @State var peers: [Peer] = []

    /// 用于刷新Peers的周期时钟
    @State var timer: Timer?

    /// 主题，默认亮色
    @State private var selectedMode: ThemeMode = .light

    /// 全局的新文本数据和全局状态
    @ObservedObject var clipboardMonitor = TextNoticeViewModel.shared
    @ObservedObject var globalState = GlobalState.shared
    
    /// 这个变量没用到，到时候删去
    var buffer = UnsafeMutablePointer<CChar>
        .allocate(capacity: 4096)
    
    /// 创建时钟，开始周期性的（每0.5s）刷新一次peers
    func startRefreshingPeerList() {
        timer = .scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true,
            block: { _ in
                peers = AirXService.readCurrentPeers()
            }
        )
    }
    
    /// 停止时钟
    func stopRefreshingPeerList() {
        timer?.invalidate()
        timer = .none
    }
    
    /// 应该是当控制面板里的开服按钮点击之后
    func onButtonClicked() {
        if globalState.isServiceOnline {
            /// 如果服务正在运行，则停服
            globalState.isServiceOnline = false
            AirXService.initiateStopAsync()
            stopRefreshingPeerList()
        }
        else {
            /// 如果服务没有运行，则开服
            globalState.isServiceOnline = true
            AirXService.startAsync()
            startRefreshingPeerList()
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Image("AppIconBoldTransparent")
                Text("AirX Developer Control Panel").bold()
            }
            
            Divider()
            
            Group {
                Text("- Peer List -")

                if peers.isEmpty {
                    Text("(Empty)").bold()
                }
                else {
                    // Note: Items in foreach arrays should implement Identifiable
                    ForEach(peers) { peer in
                        Text(peer.description)
                    }
                }
            }
            
            Divider()
            
            Button(
                globalState.isServiceOnline ? "Stop Service" : "Start Service"
                   , action: onButtonClicked)
                .foregroundColor(selectedMode.theme.buttonText)
            
            Spacer().frame(height: 20)
            
            HStack {
                Text("Mode")
                    .font(.footnote)
                    .foregroundColor(selectedMode.theme.textColor) // 设置颜色
                
                Spacer().frame(width: 5)
                
                Picker("", selection: $selectedMode) {
                    ForEach(ThemeMode.allCases, id: \.self) {
                        Text($0.rawValue).font(.footnote)
                    }
                }
                //.pickerStyle(RadioGroupPickerStyle())
                .foregroundColor(selectedMode.theme.textColor)
                .background(selectedMode.theme.gray)
                .frame(width: 130, height: 30)
            }
        }
        .frame(width: 245, height: 400)
        .padding()
        .background(selectedMode.theme.gray)
    }
}

struct PanelView_Previews: PreviewProvider {
    static var previews: some View {
        ControlPanelView()
    }
}
