//
//  AboutView.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation
import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            Text("AirX - Text/File Sync Tool").bold()
            Text("macOS Frontend")
            
            Divider()
            
            Text("- Components -")
            Grid(alignment: .leading) {
                GridRow(alignment: .top) {
                    Text(Bundle.main.appName).bold()
                    VStack(alignment: .leading) {
                        Text(verbatim: "Version \(Bundle.main.appVersionLong)")
                        Text(verbatim: "Build \(Bundle.main.appBuild)")
                    }
                }
                GridRow(alignment: .top) {
                    Text("libairx").bold()
                    VStack(alignment: .leading) {
                        Text(verbatim: "Version \(airx_version())")
                    }
                }
            }

            Divider()
            
            Text("Memorial University")
            Text(Bundle.main.copyright)
        }
        .frame(width: 305, height: 245)
    }
}


struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

