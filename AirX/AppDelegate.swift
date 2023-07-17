//
//  AppDelegate.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-14.
//

import AppKit
import Foundation
import SwiftUI
import GoogleSignIn /** 谷歌给的 */

/// `delegate`读起来音同代理，实际意思也是代理。代理本App执行生命周期函数
/// 所谓生命周期，就是当app被打开了、被关闭了等等时机，系统会对app进行一个通知，方便让app在适当的时机做事情
/// 第一行固定搭配，就是要继承这两个NS开头的东西
/// 实际会发现有不少命名是NS开头的，这是苹果的历史遗留
class AppDelegate: NSResponder, NSApplicationDelegate {
    /// 顾名思义，每当application did finish launching的时候调用
    func applicationDidFinishLaunching(_ notification: Notification) {
        /// 防止重复运行。也就是说，一台电脑不能同时开两个airx，不然乱套了
        preventMultipleInstances()
        
        /// 初始化airx
        airx_init()
        
        /// 初始化设置
        Defaults.tryInitializeConfigurationsForFirstRun()
        
        /// 初始化谷歌登录
        registerForGoogleSignIn()
        
        /// 尝试自动登录
        AccountUtils.tryAutomaticLogin()
        
        /// 启动airx服务
        AirXService.startAsync()

        print("AirX macOS Frontend")
    }

    /// 顾名思义，这个函数决定：当本程序所有窗口都被关闭了的时候，本程序该不该结束？
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        /// 不该
        return false
    }
    
    /// 这是谷歌给的代码，直接用就完了
    func registerForGoogleSignIn() {
        // Register for GetURL events.
        let appleEventManager = NSAppleEventManager.shared()
        appleEventManager.setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    /// 防止重复运行
    private func preventMultipleInstances() {
        /// 获得自身进程ID。进程ID在当前系统是唯一的，唯一确定一个进程。
        let myPid = ProcessInfo.processInfo.processIdentifier
        let workspace = NSWorkspace.shared
        let apps = workspace.runningApplications
        
        for app in apps {
            /// 放眼这台机器的所有进程，如果有谁的名字(bundleIdentifier)和自己一样，但是进程ID却不一样
            if app.processIdentifier != myPid && app.bundleIdentifier == Bundle.main.bundleIdentifier {
                /// 说明是另一个我已经在运行了，那我走
                print("Another instance is already running. Exiting...")
                exit(EXIT_SUCCESS)
            }
        }
    }
    
    
    /// 这是谷歌给的代码，直接用就完了
    /// 为什么这有个`@objc`呢，因为谷歌登录那套东西他们是用objective-C写的
    /// 虽说是和swift可以互相调用，但是swift这边需要加上`@objc`来明确标注这是和objc混合调用
    @objc func handleGetURLEvent(event: NSAppleEventDescriptor?, replyEvent: NSAppleEventDescriptor?) {
        if let urlString = event?.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue{
            let url = URL(string: urlString)
            GIDSignIn.sharedInstance.handle(url!)
        }
    }
}
