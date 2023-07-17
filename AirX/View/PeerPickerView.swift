//
//  PeerPickerView.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-07-14.
//

import Foundation
import SwiftUI

/// 选人页面
struct PeerPickerView: View {
    /// 用于关闭当前窗口
    @Environment(\.presentationMode) var presentationMode
    
    /// 选完人的回调函数
    @Binding var callback: (Peer) -> Void
    
    /// 所有Peers
    let peers = AirXService.readCurrentPeers()

    var body: some View {
        VStack(spacing: 0) {
            Text("Select a peer")
                .bold()
                .padding()

            ForEach(peers) { peer in
                PeerPickerRow(peer: peer) {
                    /// 选择Peer后，先关闭自身窗口，然而调用回调函数
                    presentationMode.wrappedValue.dismiss()
                    callback(peer)
                }
            }
        }
        .frame(width: 328)
    }
}

/// 每个待选的Peer是列表中的一行
struct PeerPickerRow: View {
    var peer: Peer
    var onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            VStack(alignment: .leading) {
                Text(peer.hostName)
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                Text(peer.description)
            }.padding(4)
            Spacer()
        }
        .padding(8)
    }
}

struct PeerPickerView_Previews: PreviewProvider {
    static var previews: some View {
        PeerPickerView(callback: .constant({ _ in }))
    }
}
