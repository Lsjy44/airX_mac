//
//  AccountUtil.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation
import SwiftUI

class AccountUtil {
    private static var subscribers = Dictionary<String, (Bool) -> Void>()

    public static func subscribeToAutomaticLoginResult(id: String, handler: @escaping (Bool) -> Void) {
        subscribers[id] = handler
    }
    
    public static func clearSavedUserInfoAndSignOut() {
        Defaults.delete(.savedCredential)
        Defaults.delete(.loggedInUid)
        Defaults.delete(.savedCredentialType)
    }
    
    private static func notifySubscribers(didLoginSuccess: Bool) {
        for subscriber in subscribers.values {
            subscriber(didLoginSuccess)
        }
    }
    
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
            try AirXCloud.renew(uid: uid) { response in
                guard response.success else {
                    print("Failed: renew failed: \(response.message)")
                    notifySubscribers(didLoginSuccess: false)
                    return
                }
                
                // Almost there!
                print("Success.")
                GlobalState.shared.isSignedIn = true
                Defaults.write(.loggedInUid, value: uid)
                Defaults.write(.savedCredential, value: response.token)
            }
        }
        catch {
            notifySubscribers(didLoginSuccess: false)
            return
        }
        notifySubscribers(didLoginSuccess: true)
    }
}
