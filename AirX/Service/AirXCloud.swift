//
//  NetworkUtil.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation
import Alamofire    /** Alamofire库用于HTTP网络请求 */

/// AirXCloud类，用于：方便的和云端进行交互，提供登录、续期等功能
/// 未来网盘的交互也在这里
class AirXCloud {
    /// base url，指定了服务器地址，之后的每个请求的URL都基于base进行拼接
    /// 例如 `https://airx.eggtartc.com/auth/token` 就是登录的URL
    private static let BASE = "https://airx.eggtartc.com"
    
    /// 列举在登录过程中，可能出现的错误
    enum AirXError: Error {
        case malformedPassword /** 密码不是标准UTF-8编码或无法被计算SHA256 */
        case incorrectCredential /** 密码不对 */
    }
    
    /// LoginPacket是指登录的时候，从客户端发往服务端的数据包
    struct LoginPacket: Encodable {
        let uid: String         /** 用户UID */
        let password: String    /** 密码明文的SHA256的SHA256（两层） */
        let salt: String        /** 登录盐。参见文档登录盐篇 */
    }
    
    /// 服务端将会按照这个格式，返回登录结果
    struct LoginResponse: Decodable {
        let success: Bool       /** 登录是否成功 */
        let message: String     /** 一段文本，如果登录成功，这段文本就是success，
                                 如果登录失败，这段文本将会是失败原因 */
        let name: String?       /** 登录成功则为用户昵称，登录失败则为`nil` */
        let token: String?      /** 成功则为token，参见文档token篇。失败为`nil` */
    }
    
    /// 续期token的时候，发往服务端的数据
    struct RenewPacket: Encodable {
        let uid: String         /** 用户UID */
    } /** 这有一个奇怪的点，既然续期token，为什么这里面不含旧token呢？
       因为token是在HTTP请求头发送的。详见文档token篇 */
    
    /// 续期结果
    struct RenewResponse: Decodable {
        let success: Bool       /** 续期是否成功 */
        let message: String     /** 成功则为success，失败则为失败原因 */
        let token: String?      /** 成功`token`失败`nil` */
    }
    
    /// 登录获得token的操作
    public static func login(
        uid: String,
        password: String,
        completion: @escaping (_ response: LoginResponse) -> Void
        /** completion参数是希望传入一个函数，当登录有结果的时候（不论成败），会调用completion实现把登录结果告诉调用方
             所以这种函数也通常形象的称为`回调函数`
             为什么不直接返回登录结果，而是非要弄一个函数呢？
             因为网络请求是异步的，也就是说，
         */
    ) throws {
        /// 目前没启用登录盐机制，因为有点麻烦，所以直接用的固定值
        let salt = "114514"
        
        /// 进行2层的哈希，失败则返回`malformedPassword`错误
        guard let passwordSha256Sha256 = password.sha256()?.sha256() else {
            throw AirXError.malformedPassword
        }
        
        // 构造LoginPacket
        let packet = LoginPacket(uid: uid, password: passwordSha256Sha256, salt: salt)
        
        // 正式进行post请求！
        try post(
            "/auth/token",  /** 最终拼接成 https://airx.eggtartc.com/auth/token */
            parameters: packet,
            requireAuthentication: false, /** 登录操作当然无需token，就是为了token才登的录 */
            completion: completion
        )
    }
    
    /// Token的续期操作
    /// 这个函数的结构和login非常像，`completion`等概念是相同的
    public static func renew(
        uid: String,
        completion: @escaping (_ response: RenewResponse) -> Void
    ) throws {
        let packet = RenewPacket(uid: uid)
        try post(
            "/auth/renew",
            parameters: packet,
            requireAuthentication: true,    /** token续期就是拿着旧token去换新的 */
            completion: completion
        )
    }
    
    /// Post请求的封装
    /// 泛型 P：代表任意一个Encodable的对象，这里用于`Swift结构体 -> JSON数据`的转换
    /// 泛型 T：代表任意一个Decodable的对象，这里用于`JSON数据 -> Swift结构体`的转换
    /// 服务端只识别JSON，所以需要这一来一回的转换。
    private static func post<P: Encodable, T: Decodable>(
        _ path: String, /** 请求路径，如 `/auth/token` */
        parameters: P,  /** Encodable */
        requireAuthentication: Bool,
        completion: @escaping (_ response: T) -> Void
    ) throws {
        /// HTTP请求头(Header)是重要的概念，参见 https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers
        var headers = HTTPHeaders.default
        if requireAuthentication {
            // Is airx token?
            /// 如果需要授权，那就把token放进header里面
            /// 这里先判断，我们存着的是不是AirX的token？还是谷歌的
            if Defaults.credentialType() != .airxToken {
                /// 不是AirX token那必然不能用在AirX服务器上
                throw AirXError.incorrectCredential
            }

            // Is token seems valid?
            /// Token别是空的
            let token = Defaults.string(.savedCredential, def: "")
            guard !token.isEmpty else {
                throw AirXError.incorrectCredential
            }

            /// 正式附加token信息（格式：`Bearer <token>`)
            /// 其中`Bearer`是固定搭配
            headers.add(.authorization("Bearer \(token)"))
        }
        
        /// AF.request是Alamofire库提供的
        AF.request(
            BASE + path,    /** 这里实际进行了 URL拼接 */
            method: .post,  /** 请求方法为POST。另一种最常见的方法为GET */
            parameters: parameters,
            encoder: JSONParameterEncoder.default,  /** JSONParameterEncoder顾名思义用于把Encodable给Encode成JSON */
            headers: headers
        ).responseDecodable(of: T.self) { decoded in /** 这时候`decoded`已经包含着解析好的Swift结构体对象 */
            /// DispatchQueue的使用，用于确保代码在UI线程执行
            /// 因为只有UI线程的代码有权更新UI
            /// 这么一来，方便调用方在他的completion里更新UI
            DispatchQueue.main.async {
                completion(decoded.value!)
            }
        }
    }
}
