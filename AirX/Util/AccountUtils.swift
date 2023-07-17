//
//  AccountUtil.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation
import SwiftUI

/// 用户账户工具类
class AccountUtils {
    /// 登录结果的订阅者们。概念参见 `AirXApp.swift`
    private static var subscribers = Dictionary<String, (Bool) -> Void>()

    /// 进行订阅
    public static func subscribeToAutomaticLoginResult(id: String, handler: @escaping (Bool) -> Void) {
        subscribers[id] = handler
    }
    
    /// 登出，清除登录信息
    public static func clearSavedUserInfoAndSignOut() {
        Defaults.delete(.savedCredential)
        Defaults.delete(.loggedInUid)
        Defaults.delete(.savedCredentialType)
    }
    
    /// 把是否成功成功的消息通知给每个suscriber
    private static func notifySubscribers(didLoginSuccess: Bool) {
        for subscriber in subscribers.values {
            subscriber(didLoginSuccess)
        }
    }
    
    /// 尝试自动登录
    /**
     * Return: true if successfully logged in, otherwise, false.
     */
    public static func tryAutomaticLogin() {
        GlobalState.shared.isSignedIn = false
        print("Trying automatic login...")

        // Check credentials!
        guard Defaults.credentialType() == .airxToken else {
            print("Failed: incorrect credential type")
            notifySubscribers(didLoginSuccess: false)
            return
        }
        
        let token = Defaults.string(.savedCredential, def: "")
        guard !token.isEmpty else {
            print("Failed: empty token")
            notifySubscribers(didLoginSuccess: false)
            return
        }
        
        let uid = Defaults.string(.savedUsername, def: "")
        guard !uid.isEmpty else {
            print("Failed: empty uid")
            notifySubscribers(didLoginSuccess: false)
            return
        }
        
        
        do {
            /// 尝试续期Token
            try AirXCloud.renew(uid: uid) { response in
                guard response.success else {
                    /// 续期失败
                    print("Failed: renew failed: \(response.message)")
                    notifySubscribers(didLoginSuccess: false)
                    return
                }
                
                /// 续期成功，更新新的token
                print("Success.")
                GlobalState.shared.isSignedIn = true
                Defaults.write(.loggedInUid, value: uid)
                Defaults.write(.savedCredential, value: response.token)
            }
        }
        catch {
            /// 如果发生任何错误，通知所有subscriber这个不幸的消息
            notifySubscribers(didLoginSuccess: false)
            return
        }
        
        /// 没有发生错误，通知登录成功
        notifySubscribers(didLoginSuccess: true)
    }
    
    /// 拉黑一名Peer，还没实现
    public static func blockUser(peer: Peer) {
        // TODO: 
    }
}
