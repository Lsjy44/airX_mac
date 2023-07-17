//
//  ViewWrapContent.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-07-14.
//

import Foundation
import SwiftUI

/// 参见 `README.md`
extension View {
    func wrapContent() -> some View {
        return frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity
        )
    }
}
