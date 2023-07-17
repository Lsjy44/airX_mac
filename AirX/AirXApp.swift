//
//  SwiftUIPracticeApp.swift
//  SwiftUIPractice
//
//  Created by Hatsune Miku on 2023-01-28.
//

import SwiftUI

/// 前两句 @main和struct AirXApp: App是固定搭配，每个app都要这么写的
@main
struct AirXApp: App {
    /// 要求管理自己的生命周期，委任给AppDelegate类进行管理（在AppDelegate.swift里面）
    /// 所谓生命周期，就是当app被打开了、被关闭了等等时机，系统会对app进行一个通知，方便让app在适当的时机做事情
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    
    /// 使用openWindow能力，然后就拥有了openWindow能力可以弹出新窗口
    /// SwiftUI默认如果你不要求使用的话，是无法主动打开新窗口的
    @Environment(\.openWindow)
    var openWindow
    
    /// 使用GlobalState（定义在GlobalState.swift里面），共享全局状态
    @ObservedObject
    var globalState = GlobalState.shared
   
    /// 新建worker
    private let fileWriterWorker = FileWriterWorker()

    /// 每当app运行，调用一次
    private func viewWillAppear() {
        /// 订阅者模式，顾名思义“XX有了任何动态之后通知我”
        /// 这里订阅了loginResult：登录有结果了的时候通知我
        /// 还订阅了textChange：来新文本了通知我
        /// 以此类推
        AccountUtils.subscribeToAutomaticLoginResult(id: "default", handler: onAutomaticSignInResult)
        AirXService.subscribeToTextChange(id: "default", handler: onTextReceived)
        AirXService.subscribeToFileComing(id: "default", handler: onFileComing)
        AirXService.subscribeToFilePart(id: "default", handler: onFilePart)
        AirXService.subscribeToFileSendingProgress(id: "default", handler: onFileSendingProgress)
        
        /// 启动worker线程
        fileWriterWorker.start()
    }
    
    /// 每当发出去的文件又传了一点点的时候，调用一次，报告最新progress
    private func onFileSendingProgress(_ fileId: UInt8, _ progress: UInt64, _ total: UInt64, status: FileSendingStatus) {
        print("fileid=\(fileId), progress=\(progress)/\(total)")
    }
    
    /// 每当来了一个文件分块的时候，调用一次
    /// 这个函数具有决定TCP连接是否应该断开的权利：返回`true`断开，返回`false`不断。
    /// 这样一来，当发现用户已经把某个文件取消掉的时候，就可以通过返回`true`来断开连接
    /// 从而防止发送方白白浪费带宽
    /// Return true to interrupt the connection.
    private func onFilePart(_ fileId: UInt8, _ offset: UInt64, _ length: UInt64, _ data: Data) -> Bool {
        /// 判断是否来了个不存在的fileId？
        guard let file = globalState.receiveFiles[fileId] else {
            debugPrint("Unexpected file received.")
            return true
        }
        
        /// 判断用户是不是已经取消掉这个文件了
        guard file.status != .cancelledBySender && file.status != .cancelledByReceiver else {
            debugPrint("File cancelled.")
            return true
        }
        
        /// 提交workload给worker，让他在后台把文件写入
        fileWriterWorker.addWorkload(
            FileWriterWorker.FilePartWorkload(
                fileId: fileId, offset: offset, length: length, data: data))
        
        /// 不要断开连接
        return false
    }
    
    /// 每当别人试图发给我一个文件（还没发呢），调用一次
    /// 这时候，由用户决定要不要收。
    private func onFileComing(_ fileSize: UInt64, _ remoteFullPath: String, _ peer: Peer) {
        /// 来了哪个文件？独取出来
        let fileName = FileUtils.getFileName(fullPath: remoteFullPath)
        
        DispatchQueue.main.async {
            /// UI线程弹窗询问用户：要接受吗？
            let selection = UIUtils.alertBox(
                title: "Received File",
                message: "\(peer.description) is sending the file \(fileName) (\(fileSize) Bytes) to you!",
                primaryButtonText: "Accept",
                secondaryButtonText: "Explicitly Decline",
                thirdButtonText: "Ignore"
            )
            
            /// 判断用户是不是选了第三个：Ignore，即不接受，也不明确拒绝
            guard selection != .alertThirdButtonReturn else {
                /// 这种是最好处理的，忽略就行，这样一来，发送方永远等不到回应。
                return
            }
            
            /// 剩下两种情况：接受，或者明确拒绝，都是要respond给发送方的
            let accept = selection == .alertFirstButtonReturn
            let fileId = FileUtils.getNextFileId()
            
            /// 如果accept，准备接收这个文件，进行准备工作
            if accept {
                prepareForReceivingFile(fileId, fileSize, remoteFullPath, peer)
            }
            
            /// 把答复告知发送方
            AirXService.respondToFile(
                host: peer.host, fileId: fileId, fileSize: fileSize, remoteFullPath: remoteFullPath, accept: accept)
        }
    }
    
    /// 每当新文本来了的时候，调用一次
    private func onTextReceived(_ text: String, _ from: Peer) {
        /// 凡是动了UI的要放在UI线程里运行
        DispatchQueue.main.async {
            /// 更新ViewModel，也就是：即将显示在窗口里面的内容
            TextNoticeViewModel.shared.receivedText = text
            TextNoticeViewModel.shared.from = from
            TextNoticeViewModel.shared.showTextNotice = true
            
            /// 弹出新文本弹窗
            UIUtils.createWindow(openWindow, windowId: .textNotice)
        }
    }
    
    // ===========================================================
    
    /// 准备接受一个文件的准备工作
    private func prepareForReceivingFile(_ fileId: UInt8, _ fileSize: UInt64, _ remoteFullPath: String, _ from: Peer) {
        /// 确定要存在哪个文件夹：默认是 `下载/AirxFiles`
        /// 这是通过先获得`下载`这一目录的URL（URL不一定非得是网址，本地文件也可以是URL）
        /// 然后拼接上AirXFiles而成
        let savingDirectory = FileUtils.getDownloadDirectoryUrl()
            .appending(path: "AirXFiles", directoryHint: .isDirectory)
        
        /// 然后，确定保存的文件名叫什么
        /// 这里直接沿用发送方那边，确保文件名一致性
        let fileName = FileUtils.getFileName(fullPath: remoteFullPath)
        
        /// 拼接前二者，得到本地保存的文件的完整URL
        let savingFullPath = savingDirectory
            .appending(path: fileName)
        
        /// 为啥这里又多折腾一次？重点在于 `percentEncoded: false`
        /// 如果直接用`savingDirectory`，那么Swift无法正确处理中文和空格
        /// 这样一来，原本: `C:\Program Files\一个中文文件.txt` 就成了 `C%3A%5CProgram%20Files%5C%E4%B8%AD%E6%96%87.txt`
        /// 啥玩意儿啊这是，为了确保Swift不要做这样奇奇怪怪的转换，所以明确指定`percentEncoded: false`
        /// 所以才能正确得到`C:\Program Files\一个中文文件.txt`
        let savingDirectoryPath = savingDirectory.path(percentEncoded: false)
        
        /// 目标目录（`下载/AirXFiles`）是否还不存在？
        if !FileManager.default.fileExists(
            atPath: savingDirectoryPath) {
            /// 若不存在，就创建它
            guard let _ = try? FileManager.default.createDirectory(
                atPath: savingDirectoryPath,
                withIntermediateDirectories: true
            ) else {
                /// 创建失败的话，弹窗
                DispatchQueue.main.async {
                    _ = UIUtils.alertBox(title: "Error", message: "Can't create output directory \(savingDirectoryPath)", primaryButtonText: "OK")
                }
                return
            }
        }
        
        /// 目标文件是否还不存在？
        if !FileManager.default.fileExists(atPath: savingFullPath.path(percentEncoded: false)) {
            /// 不存在就创建它，内容先空的就行
            guard FileManager.default.createFile(atPath: savingFullPath.path(percentEncoded: false), contents: nil) else {
                /// 创建失败的话，弹窗
                DispatchQueue.main.async {
                    _ = UIUtils.alertBox(title: "Error", message: "Can't create file \(savingFullPath.path(percentEncoded: false)) for writing.", primaryButtonText: "OK")
                }
                return
            }
        }
        
        /// 打开目标文件以进行写入，这里的实际行为是创建了`FileHandle`
        guard let fileHandle = try? FileHandle(forWritingTo: savingFullPath) else {
            /// 失败的话弹窗
            DispatchQueue.main.async {
                _ = UIUtils.alertBox(title: "Error", message: "Can't open file \(savingFullPath.path(percentEncoded: false)) for writing.", primaryButtonText: "OK")
            }
            return
        }
        
        /// 提前把硬盘空间给占上，steam同款做法
        guard fileHandle.ensureSize(fileSize) else {
            /// 没占上的话，弹窗
            DispatchQueue.main.async {
                _ = UIUtils.alertBox(title: "Error", message: "Failed to ensure file size.", primaryButtonText: "OK")
            }
            return
        }
        
        /// 构造ReceiveFile对象，现在我们有一个待收文件了
        let receiveFile = ReceiveFile(
            remoteFullPath: remoteFullPath,
            fileHandle: fileHandle,
            localSaveFullPath: savingFullPath,
            totalSize: fileSize,
            fileId: fileId,
            from: from,
            progress: 0,
            status: .accepted
        )

        /// 把待收文件放进全局状态里
        GlobalState.shared.receiveFiles[fileId] = receiveFile
        
        /// 同时弹出新文件窗口
        let window = FileNoticeWindow(fileId: fileId)
        UIUtils.showNSWindow(window)
        
        /// 还记得之前respondToFile吗？现在文件传输已经开始了，onFilePart函数将会开始被频繁调用。
    }
    
    /// 当登录有结果的时候，告知
    private func onAutomaticSignInResult(didLoginSuccess: Bool) {
        /// 登录成功了自然是最好的
        if didLoginSuccess {
            return
        }
        
        // Open sign-in window if automatic login failed.
        onToggleSignInOutMenuItemClicked()
    }
    
    /// 定义菜单项
    var menuItems: some View {
        VStack {
            /// 第一项，根据在线状态确定一段儿文本
            globalState.isServiceOnline
                ? Text("AirX Is Online!")
                : Text("AirX Is Offline.")
            
            /// 第2项，开始/停止服务的选项，快捷键S键
            Button("\(globalState.isServiceOnline ? "Stop" : "Start") Service", action: onToggleServiceMenuItemClicked)
                .keyboardShortcut("S")
            
            /// 第3项，打开控制面板选项
            Button("Open Control Panel", action: onOpenControlPanelMenuItemClicked)
                .keyboardShortcut("O")
            
            /// 一个分割线
            Divider()
            
            /// 如果已登录，插一项UID显示
            if globalState.isSignedIn {
                Text("UID: \(Defaults.string(.savedUsername, def: "0"))")
            }
            
            /// 第4项，登录/注销选项
            Button("Sign \(globalState.isSignedIn ? "Out" : "In")", action: onToggleSignInOutMenuItemClicked)
            
            Divider()
            
            /// 发送文件选项
            Button("Send File", action: onSendFileMenuItemClicked)
            
            Divider()

            /// 关于选项
            Button("About AirX", action: onAboutMenuItemClicked)
                .keyboardShortcut("A")

            /// 退出选项
            Button("Exit", action: onExitApplicationMenuItemClicked)
                .keyboardShortcut("E")
        }
    }
    
    /// 程序正在退出的时候，整个菜单则显示截然不同的内容
    var exitingMenuItems: some View {
        VStack {
            /// 一行文字：正在退出
            Text("AirX is exiting...")
            
            /// 一个选项：立刻退出（而不去等AirX服务真正停止）
            /// 其实不等也没什么关系
            Button("Force Exit", action: onForceExitMenuItemClicked)
                .keyboardShortcut("F")
        }
    }
    
    /// 这个body是注册所有菜单项、按钮、窗口的地方
    var body: some Scene {
        /// 首先调用我们的`viewWillAppear()`实现初始化工作
        /// `let _ = xxx()`写法是说，故意丢弃`xxx`的返回值，免得编辑器以为我们是不小心的
        let _ = viewWillAppear()

        /// 真正定义菜单
        MenuBarExtra("AirX", image: "AppIconBoldTransparent") {
            /// 根据是否正在退出，显示不同的内容
            if globalState.isApplicationExiting {
                exitingMenuItems
            }
            else {
                menuItems
            }
        }

        /// 注册登录窗口，id就只是为了提供一个独一无二的名字给他而已
        /// 窗口内使用LoginView作为内容
        /// 屏幕居中，宽高安排好
        Window(WindowIds.signIn.windowTitle, id: WindowIds.signIn.rawValue) {
            LoginView(isSignedInRef: $globalState.isSignedIn)
        }.windowResizability(.contentSize)
            .defaultPosition(.center)
            .defaultSize(width: 366, height: 271)

        /// 控制面板窗口
        /// 窗口内使用ControlPanelView作为内容
        /// 屏幕居中，宽高安排好
        Window(WindowIds.controlPanel.windowTitle, id: WindowIds.controlPanel.rawValue) {
            ControlPanelView()
        }.windowResizability(.contentSize)
            .defaultPosition(.center)
            .defaultSize(width: 277, height: 460)
        
        /// 关于窗口
        /// 窗口内使用AboutView作为内容
        Window(WindowIds.about.windowTitle, id: WindowIds.about.rawValue) {
            AboutView()
        }.windowResizability(.contentSize)
            .defaultPosition(.center)
            .defaultSize(width: 305, height: 273)
        
        /// 新文本窗口
        /// 窗口内使用TextNoticeView作为内容，暂时锁亮色主题
        Window(WindowIds.textNotice.windowTitle, id: WindowIds.textNotice.rawValue) {
            TextNoticeView(theme: .constant(LightMode()))
        }.windowResizability(.contentSize)
            .windowStyle(.hiddenTitleBar)
            .defaultPosition(.bottomTrailing)
            .defaultSize(width: 317, height: 196)
        
        /// 还有FileNoticeWindow和PeerPickerWindow是别处用代码动态地创建的
        /// 那样做的好处是可以同时存在好几个重复的比如PeerPickerWindow
        /// 在这里静态注册的，同一窗口只能弹一个，不能好几个共存
    }
    
    /// 当开/关服务菜单项被点击
    func onToggleServiceMenuItemClicked() {
        if globalState.isServiceOnline {
            AirXService.initiateStopAsync()
        }
        else {
            AirXService.startAsync()
        }
    }
    
    /// 当关于被点击
    func onAboutMenuItemClicked() {
        /// 借助openWindow能力，打开about窗口
        UIUtils.createWindow(openWindow, windowId: .about)
    }
    
    /// 当登录/注销被点击
    func onToggleSignInOutMenuItemClicked() {
        if globalState.isSignedIn {
            /// 注销的时候，清除保存的token
            globalState.isSignedIn = false
            AccountUtils.clearSavedUserInfoAndSignOut()
            return
        }
        UIUtils.createWindow(openWindow, windowId: .signIn)
    }
    
    /// 控制面板点击
    func onOpenControlPanelMenuItemClicked() {
        UIUtils.createWindow(openWindow, windowId: .controlPanel)
    }
    
    /// 退出点击
    func onExitApplicationMenuItemClicked() {
        /// app置于正在退出状态
        globalState.isApplicationExiting = true
        
        /// 开始停止airx服务
        AirXService.initiateStopAsync()
        
        /// 这里开发阶段直接等2秒后就认为airx关闭完成了
        /// 后续应该改成真的等airx停止了再退出
        Task {
            do {
                // TODO: wait for stop
                try await Task.sleep(for: .seconds(2))
            }
            catch {}
            
            /// 常量`EXIT_SUCCESS`等于0，代表退出成功
            exit(EXIT_SUCCESS)
        }
    }
    
    /// 当发送文件被点击
    func onSendFileMenuItemClicked() {
        /// 获取现在哪些peer在线
        let peers = AirXService.readCurrentPeers()

        /// 无人在线的话，弹窗
        guard !peers.isEmpty else {
            _ = UIUtils.alertBox(title: "Error", message: "No peers available.", primaryButtonText: "OK")
            return
        }
        
        /// 让用户选一个文件。如果啥也没选，返回
        guard let fileUrl = UIUtils.pickFile() else {
            return
        }
       
        /// 让用户从所有在线peer里挑一个
        let peerPicker = PeerPickerWindow(callback: .constant({ peer in
            debugPrint("Sending \(fileUrl.path(percentEncoded: false))")
            /// 注意看这里也是一个回调函数的函数体
            /// 用户选好peer了，现在peer和file俱在，开始发送
            AirXService.trySendFile(host: peer.host, filePath: fileUrl.path(percentEncoded: false))
        }))
        
        /// 弹出选人窗口。实际代码中，先执行到这里，用户人选完后，在执行上边的回调
        UIUtils.showNSWindow(peerPicker)
    }
    
    /// 强制退出点击
    func onForceExitMenuItemClicked() {
        exit(EXIT_FAILURE)
    }
}

/// 给每个window类型附一个文本标识，比如 signin窗口，代号是“Sign In”
/// 后续通过代号来确定是哪个窗口。
enum WindowIds: String {
    case signIn
    case controlPanel
    case about
    case textNotice
    case fileNotice
    
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
            
        case .fileNotice:
            return "File Notice"
        }
    }
}
