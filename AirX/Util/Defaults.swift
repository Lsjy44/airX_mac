//
//  Defaults.swift
//  SwiftUIPractice
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation

/// 设置管理

enum DefaultKeys: String {
    case savedUsername                  /** 上次登录的UID */
    case shouldRememberPassword         /** 是否应记住密码 */

    /// Tokens or password.
    case loggedInUid                    /** 正登录着的UID */
    case savedCredentialType            /** 保存的密码类型（明文？token？） */
    case savedCredential                /** 保存的密码内容 */
    
    case discoveryServiceServerPort
    case discoveryServiceClientPort
    case textServiceListenPort
    case groupIdentity
    
    case isNotFirstRun                  /** 是否并非首次运行 */
}

class Defaults {
    /// 得到管理设置的对象，设置被称为UserDefaults
    private static let defaults = UserDefaults.standard
    
    /// 尝试初始化设置
    public static func tryInitializeConfigurationsForFirstRun() {
        /// 如果不是第一次运行了，不要初始化
        if bool(.isNotFirstRun) {
            return
        }
        
        /// 只有第一次运行，才初始化
        write(.discoveryServiceClientPort, value: 0)
        write(.discoveryServiceServerPort, value: 9818)
        write(.textServiceListenPort, value: 9819)
        write(.groupIdentity, value: 0)
        write(.isNotFirstRun, value: true)
    }
    
    /// 读取String类型数据
    public static func string(_ key: DefaultKeys, def: String) -> String {
        return defaults.string(forKey: key.rawValue) ?? def
    }
    
    /// 读取bool类型数据
    public static func bool(_ key: DefaultKeys) -> Bool {
        return defaults.bool(forKey: key.rawValue)
    }
    
    public static func int(_ key: DefaultKeys) -> Int {
        return defaults.integer(forKey: key.rawValue)
    }
    
    public static func double(_ key: DefaultKeys) -> Double {
        return defaults.double(forKey: key.rawValue)
    }
    
    public static func delete(_ key: DefaultKeys) {
        defaults.removeObject(forKey: key.rawValue)
    }
    
    /// 读取保存的密码信息
    public static func savedCredential() -> String {
        return string(.savedCredential, def: "")
    }
    
    /// 读取保存的密码类型信息
    public static func credentialType() -> CredentialType {
        return CredentialType(
            rawValue: string(
                .savedCredentialType,
                def: CredentialType.password.rawValue
            )
        ) ?? .password
    }
    
    /// 写入任意数据
    public static func write(_ key: DefaultKeys, value: Any?) {
        defaults.set(value, forKey: key.rawValue)
    }
    
    /// 给写入密码类型数据做特殊对待，因为它数据类型特殊
    public static func write(_ key: DefaultKeys, value: CredentialType) {
        defaults.set(value.rawValue, forKey: key.rawValue)
    }
    
    /// 两个同名函数，怎么知道到底调的是哪个：适用意义最狭隘的那一个
    /// 比如写入一个int，直接适用Any，也就是第一个
    /// 如果写入一个CredentialType，同时适用两个，但是CredentialType比Any狭隘，所以适用第二个
}
