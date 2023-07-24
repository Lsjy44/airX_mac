//
//  NetworkUtil.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation
import Alamofire

class AirXCloud {
#if DEBUG
    // 没事儿暂时不动后端
    public static let API_BASE = "https://airx.eggtartc.com"
    public static let WEBSOCKET_BASE = "wss://airx.eggtartc.com/device-register"

    // public static let API_BASE = "http://localhost:2479"
    // public static let WEBSOCKET_BASE = "http://localhost:2479/device-register"
#else
    public static let API_BASE = "https://airx.eggtartc.com"
    public static let WEBSOCKET_BASE = "wss://airx.eggtartc.com/device-register"
#endif

    enum AirXError: Error {
        case 卧槽
        case incorrectCredential
    }
    
    struct LoginPacket: Encodable {
        let uid: String
        let password: String
        let salt: String
    }
    
    struct LoginResponse: Decodable {
        let success: Bool
        let message: String
        let name: String?
        let token: String?
    }
    
    struct RenewPacket: Encodable {
        let uid: String
    }
    
    struct RenewResponse: Decodable {
        let success: Bool
        let message: String
        let token: String?
    }
    
    struct MessageSendPacket: Encodable {
        let content: String
        let type: Int
    }
    
    struct MessageSendResponse: Decodable {
        let success: Bool
        let message: String
    }
    
    public static func login(
        uidOrEmail: String,
        password: String,
        completion: @escaping (_ response: LoginResponse) -> Void
    ) throws {
        let salt = "114514"
        guard let passwordSha256Sha256 = password.sha256()?.sha256() else {
            throw AirXError.卧槽
        }
        let packet = LoginPacket(uid: uidOrEmail, password: passwordSha256Sha256, salt: salt)
        try post(
            "/auth/token",
            parameters: packet,
            requireAuthentication: false,
            completion: completion
        )
    }
    
    public static func renew(
        uid: String,
        completion: @escaping (_ response: RenewResponse) -> Void
    ) throws {
        let packet = RenewPacket(uid: uid)
        try post(
            "/auth/renew",
            parameters: packet,
            requireAuthentication: true,
            completion: completion
        )
    }
    
    public static func sendMessage(
        content: String,
        type: MessageType,
        completion: @escaping (_ response: MessageSendResponse) -> Void
    ) throws {
        let packet = MessageSendPacket(content: content, type: type.rawValue)
        try post(
            "/api/v1/message",
            parameters: packet,
            requireAuthentication: true,
            completion: completion
        )
    }
    
    private static func post<P: Encodable, T: Decodable>(
        _ path: String,
        parameters: P,
        requireAuthentication: Bool,
        // TODO: learn @escaping
        completion: @escaping (_ response: T) -> Void
    ) throws {
        var headers = HTTPHeaders.default
        if requireAuthentication {
            // Is airx token?
            if Defaults.credentialType() != .airxToken {
                throw AirXError.incorrectCredential
            }

            // Is token seems valid?
            let token = Defaults.string(.savedCredential, def: "")
            guard !token.isEmpty else {
                throw AirXError.incorrectCredential
            }

            headers.add(.authorization("Bearer \(token)"))
        }
        
        AF.request(
            API_BASE + path,
            method: .post,
            parameters: parameters,
            encoder: JSONParameterEncoder.default,
            headers: headers
        ).responseDecodable(of: T.self) { decoded in
            if let decodedValue = decoded.value {
                DispatchQueue.main.async {
                    completion(decodedValue)
                }
            }
            else if let error = decoded.error {
                AccountUtils.clearSavedUserInfoAndSignOut()
                AccountUtils.notifySubscribers(didLoginSuccess: false)
                print("Error in decoding response: \(error), path: \(path)")
            }
            else {
                print("Error in decoding response: Unknown error")
            }
        }
    }
}
