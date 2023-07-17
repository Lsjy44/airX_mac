//
//  login.swift
//  SwiftUIPractice
//
//  Created by 刘世俊懿 on 2023-05-24.
//

import Foundation
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

/// 登录页面
struct LoginView: View {
    /// 要求使用`presentationMode`能力用来关闭当前窗口的
    @Environment(\.presentationMode) var presentationMode
    
    /// 用户刚刚输入的UID，初值为用户上次登录用的UID
    @State private var uid: String
        = Defaults.string(.savedUsername, def: "")
    
    /// 密码
    @State private var password: String
        = Defaults.savedCredential()
    
    /// 是否记住密码
    @State private var shouldRememberPassword: Bool
        = Defaults.bool(.shouldRememberPassword)

    /// 历史遗留，好像不用了
    @State private var shouldShowContentView: Bool = false
    
    /// 是否正在登录中
    @State private var isLoggingIn: Bool = false
    
    /// 是否应该显示错误信息
    @State private var shouldShowAlert: Bool = false
    
    /// 错误信息内容
    @State private var errorMessage: String = ""
    
    /// 外部传来的，是否已经登过录了
    @Binding var isSignedInRef: Bool
    
    
    /// 登录按钮点击
    func onSignInClicked() {
        Task {
            /// 更新状态：正在登录中，从而登录按钮等变灰
            isLoggingIn = true
            do {
                /// 进行登录网络请求
                try AirXCloud.login(uid: uid, password: password) { response in
                    /// 登录失败，显示错误信息
                    guard response.success else {
                        errorMessage = response.message
                        shouldShowAlert = true
                        return
                    }
                    
                    // Success
                    /// 保存token
                    Defaults.write(.savedCredential, value: response.token)
                    Defaults.write(.savedCredentialType, value: .airxToken)
                    GlobalState.shared.isSignedIn = true

                    /// 我这里是不是搞反了
                    if shouldRememberPassword {
                        Defaults.write(.savedUsername, value: uid)
                    }
                    
                    /// 关闭当前窗口
                    presentationMode.wrappedValue.dismiss()
                }
            }
            catch {
                /// 如果登录过程中出现错误，显示错误信息
                errorMessage = error.localizedDescription
                shouldShowAlert = true
                isLoggingIn = false
                return
            }
            
            /// 更新状态，不再处于`登录中`状态
            /// 从而登录按钮等又可以点了
            isLoggingIn = false
        }
    }
    
    /// 注册，跳转URL
    func onSignUpClicked() {
        if let url = URL(string: "http://shijunyi-cv.com/shijunyi/shijunyi.html#home") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// 记住密码这个选项发生改变
    func onRememberMeChanged(newValue: Bool) {
        /// 记忆用户选择
        UserDefaults.standard.set(newValue, forKey: "ShouldRememberPassword")
        
        if !newValue {
            /// 不再记住密码的话，删去本地所存的token
            UserDefaults.standard.removeObject(forKey: "SavedPassword")
            password = ""
        }
    }
    
    /// 谷歌给的
    func onOpenUrl(url: URL) {
        GIDSignIn.sharedInstance.handle(url)
    }
    
    /// 谷歌给的
    func onGoogleSignInClicked() {
        guard let presentingWindow = NSApplication.shared.windows.first else {
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) { signInResult, error in
            guard let result = signInResult else {
                // Inspect error
                errorMessage = error?.localizedDescription ?? "Unknown error"
                shouldShowAlert = true
                return
            }
            // If sign in succeeded, display the app's main content View.
            // TODO: continue google signin
            print(result)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .trailing) {
                    Text("Account").frame(height: 20)
                    Text("Password").frame(height: 20)
                }.frame(width: 80, alignment: .trailing)
                
                VStack {
                    TextField("Enter UID/Email", text: $uid)
                        .frame(height: 20)
                        .onSubmit(onSignInClicked)
                    
                    SecureField("Enter Password", text: $password)
                        .frame(height: 20)
                        .onSubmit(onSignInClicked)
                }
            }
            
            Toggle("Remember Me", isOn: $shouldRememberPassword)
                .disabled(isLoggingIn)
                .onChange(
                    of: shouldRememberPassword,
                    perform: onRememberMeChanged
                )
            
            HStack {
                Button("Sign In", action: onSignInClicked).disabled(isLoggingIn)
                Button("Sign Up", action: onSignUpClicked).disabled(isLoggingIn)
            }

            //忘记密码
            HStack {
                Link("Forgot your password?", destination: URL(string: "http://shijunyi-cv.com/shijunyi/shijunyi.html#home")!)
            }
            
            Divider()
            
            GoogleSignInButton(
                viewModel: GoogleSignInButtonViewModel(
                    scheme: .light, style: .wide, state: isLoggingIn ? .disabled : .normal),
                action: onGoogleSignInClicked
            )
        }
        .frame(width: 300, height: 200)
        .padding()
        .onOpenURL(perform: onOpenUrl)
        .alert(errorMessage, isPresented: $shouldShowAlert) {
            Button("OK", role: .cancel, action: {})
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isSignedInRef: .constant(false))
    }
}
