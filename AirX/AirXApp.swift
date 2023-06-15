//
//  SwiftUIPracticeApp.swift
//  SwiftUIPractice
//
//  Created by Hatsune Miku on 2023-01-28.
//

import SwiftUI

enum WindowIds: String {
    case signIn
    case controlPanel
    case about
    case textNotice
    
    var windowTitle: String {
        switch self {
        case .signIn:
            return "Sign In"
            
        case .controlPanel:
            return "Developer Control Panel"
            
        case .about:
            return "About AirX"
            
        case .textNotice:
            return "Text Notice"
        }
    }
}

@main
struct AirXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    
    // TODO: \.  ?
    @Environment(\.openWindow)
    var openWindow
    
    @ObservedObject
    var globalState = GlobalState.shared
    
    private func viewWillAppear() {
        AccountUtil.subscribeToAutomaticLoginResult(id: "default", handler: onAutomaticSignInResult)
        AirXService.subscribeToTextChange(id: "default", handler: onTextReceived)
    }
    
    private func onTextReceived(_ text: String, _ from: String) {
        // These codes must be delayed - they can't run directly during a view update,
        // because `onTextReceived` is called from another thread.
        DispatchQueue.main.async {
            TextNoticeViewModel.shared.receivedText = text
            TextNoticeViewModel.shared.from = from
            TextNoticeViewModel.shared.showTextNotice = true
            UIUtil.createWindow(openWindow, windowId: .textNotice)
        }
    }
    
    private func onAutomaticSignInResult(didLoginSuccess: Bool) {
        if didLoginSuccess {
            return
        }
        
        // Open sign-in window if automatic login failed.
        onToggleSignInOutMenuItemClicked()
    }
    
    var menuItems: some View {
        VStack {
            globalState.isServiceOnline
                ? Text("AirX Is Online!")
                : Text("AirX Is Offline.")
            
            Button("\(globalState.isServiceOnline ? "Stop" : "Start") Service", action: onToggleServiceMenuItemClicked)
                .keyboardShortcut("S")
            Button("Open Control Panel", action: onOpenControlPanelMenuItemClicked)
                .keyboardShortcut("O")
            
            Divider()
            
            if globalState.isSignedIn {
                Text("UID: \(Defaults.string(.savedUsername, def: "0"))")
            }
            
            Button("Sign \(globalState.isSignedIn ? "Out" : "In")", action: onToggleSignInOutMenuItemClicked)
            
            Divider()

            Button("About AirX", action: onAboutMenuItemClicked)
                .keyboardShortcut("A")
            Button("Exit", action: onExitApplicationMenuItemClicked)
                .keyboardShortcut("E")
        }
    }
    
    var exitingMenuItems: some View {
        VStack {
            Text("AirX is exiting...")
            Button("Force Exit", action: onForceExitMenuItemClicked)
                .keyboardShortcut("F")
        }
    }
    
    var body: some Scene {
        let _ = viewWillAppear()

        MenuBarExtra("AirX", image: "AppIconBoldTransparent") {
            if globalState.isApplicationExiting {
                exitingMenuItems
            }
            else {
                menuItems
            }
        }

        Window(WindowIds.signIn.windowTitle, id: WindowIds.signIn.rawValue) {
            LoginView(isSignedInRef: $globalState.isSignedIn)
        }.windowResizability(.contentSize)
            .defaultPosition(.center)
            .defaultSize(width: 366, height: 271)

        Window(WindowIds.controlPanel.windowTitle, id: WindowIds.controlPanel.rawValue) {
            ControlPanelView()
        }.windowResizability(.contentSize)
            .defaultPosition(.center)
            .defaultSize(width: 277, height: 460)
        
        Window(WindowIds.about.windowTitle, id: WindowIds.about.rawValue) {
            AboutView()
        }.windowResizability(.contentSize)
            .defaultPosition(.center)
            .defaultSize(width: 305, height: 273)
        
        Window(WindowIds.textNotice.windowTitle, id: WindowIds.textNotice.rawValue) {
            TextNoticeView(theme: .constant(DarkMode()))
        }.windowResizability(.contentSize)
            .windowStyle(.hiddenTitleBar)
            .defaultPosition(.bottomTrailing)
            .defaultSize(width: 317, height: 196)
    }
    
    func onToggleServiceMenuItemClicked() {
        if globalState.isServiceOnline {
            AirXService.initiateStopAsync()
        }
        else {
            AirXService.startAsync()
        }
    }
    
    func onAboutMenuItemClicked() {
        UIUtil.createWindow(openWindow, windowId: .about)
    }
    
    func onToggleSignInOutMenuItemClicked() {
        if globalState.isSignedIn {
            globalState.isSignedIn = false
            AccountUtil.clearSavedUserInfoAndSignOut()
            return
        }
        UIUtil.createWindow(openWindow, windowId: .signIn)
    }
    
    func onOpenControlPanelMenuItemClicked() {
        UIUtil.createWindow(openWindow, windowId: .controlPanel)
    }
    
    func onExitApplicationMenuItemClicked() {
        globalState.isApplicationExiting = true
        AirXService.initiateStopAsync()
        Task {
            do {
                // TODO: wait for stop
                try await Task.sleep(for: .seconds(2))
            }
            catch {}
            exit(EXIT_SUCCESS)
        }
    }
    
    func onForceExitMenuItemClicked() {
        exit(EXIT_FAILURE)
    }
}
