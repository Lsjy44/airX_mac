//
//  CredentialType.swift
//  SwiftUIPractice
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation

/// 密码类型
enum CredentialType: String {
    case password       /** 明文密码 */
    case airxToken      /** AirX的token */
    case googleToken    /** Google token */
}
