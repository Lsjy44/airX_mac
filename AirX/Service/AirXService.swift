//
//  AirXService.swift
//  AirXmac
//
//  Created by Hatsune Miku on 2023-06-14.
//

import Foundation
import AppKit

// Global interrupt flag.
private var interrupt = false
private var pasteboard = NSPasteboard.general
private var lastIncomingString = ""
private var textChangeSubscribers = Dictionary<String, (String, String) -> Void>()
private var fileSendingProgressSubscribers = Dictionary<String, (UInt8, UInt64, UInt64, UInt8) -> Void>();
private var fileComingSubscribers = Dictionary<String, (UInt64, String, String) -> Void>();
private var filePartSubscribers = Dictionary<String, (UInt8, UInt32, UInt32, Data) -> Void>();

private func shouldInterrupt() -> Bool {
    return interrupt
}

/*
 void (*text_callback_c)(const char*, uint32_t, const char*, uint32_t),
 void (*file_coming_callback_c)(uint64_t, const char*, uint32_t, const char*, uint32_t),
 void (*file_sending_callback_c)(uint8_t, uint64_t, uint64_t, uint8_t),
 void (*file_part_callback_c)(uint8_t, uint32_t, uint32_t, const char*),
 */

private func onFilePart(
    fileId: UInt8,
    offset: UInt32,
    length: UInt32,
    data: UnsafePointer<CChar>?
) {
    guard let data else {
        return
    }
    
    let dataManaged = Data(bytes: data, count: Int(length))

    for subscriber in filePartSubscribers.values {
        subscriber(fileId, offset, length, dataManaged)
    }
}

private func onFileSendingProgress(
    fileId: UInt8,
    progress: UInt64,
    total: UInt64,
    status: UInt8
) {
    for subscriber in fileSendingProgressSubscribers.values {
        // TODO: better status repr
        subscriber(fileId, progress, total, status)
    }
}

private func onFileComing(
    fileSize: UInt64,
    fileNameStringPointer: UnsafePointer<CChar>?,
    fileNameStringLength: UInt32,
    sourceIpAddressStringPointer: UnsafePointer<CChar>?,
    sourceIpAddressStringLength: UInt32
) {
    guard let fileNameStringPointer, let sourceIpAddressStringPointer else {
        return
    }
    
    let fileName = String(cString: fileNameStringPointer)
    let sourceIpAddressString = String(cString: sourceIpAddressStringPointer)
    
    for subscriber in fileComingSubscribers.values {
        subscriber(fileSize, fileName, sourceIpAddressString)
    }
}

private func onTextReceived(
    incomingStringPointer: UnsafePointer<CChar>?,
    incomingStringLength: UInt32,
    sourceIpAddressStringPointer: UnsafePointer<CChar>?,
    sourceIpAddressStringLength: UInt32
) {
    guard let incomingStringPointer, let sourceIpAddressStringPointer else {
        return
    }
    
    let incomingString = String(cString: incomingStringPointer)
    let sourceIpAddressString = String(cString: sourceIpAddressStringPointer)
    
    pasteboard.declareTypes([.string], owner: nil)
    
    // Copy string to pasteboard.
    lastIncomingString = incomingString
    guard pasteboard.setString(incomingString, forType: .string) else {
        return
    }
    
    for subscriber in textChangeSubscribers.values {
        subscriber(incomingString, sourceIpAddressString)
    }
}

class AirXService {
    // AirX service opaque structure.
    private static var airxPointer: OpaquePointer?  = .none

    // Pasteboard last change count and content.
    private static var lastPasteboardChangeCount    = NSPasteboard.general.changeCount
    private static var lastPasteboardContent        = NSPasteboard.general.string(forType: .string) ?? ""
    
    // Timer for monitoring the clipboard.
    private static var timer: Timer?                = .none
    
    // Workers.
    private static var threads: Array<Thread>       = .init()
    // Configurations.
    public static let discoveryServiceServerPort   = Defaults.int(.discoveryServiceServerPort)
    public static let discoveryServiceClientPort   = Defaults.int(.discoveryServiceClientPort)
    public static let textServiceListenPort        = Defaults.int(.textServiceListenPort)
    public static let groupIdentity                = Defaults.int(.groupIdentity)
    public static let host                         = "0.0.0.0"

    public static func subscribeToTextChange(id: String, handler: @escaping (String, String) -> Void) {
        textChangeSubscribers[id] = handler
    }
    
    public static func startAsync() {
        guard threads.isEmpty else {
            return
        }
        
        let hostBuffer = host.toBuffer()
        airxPointer = airx_create(
            UInt16(discoveryServiceServerPort),
            UInt16(discoveryServiceClientPort),
            hostBuffer,
            host.utf8Size(),
            UInt16(textServiceListenPort),
            UInt32(groupIdentity)
        )
        hostBuffer.deallocate()
        
        // Run text and lan discovery service in seperate threads.
        threads.append(Thread(block: {
            airx_data_service(
                airxPointer,
                onTextReceived,
                onFileComing,
                onFileSendingProgress,
                onFilePart,
                shouldInterrupt
            )
        }))
        threads.append(Thread(block: {
            airx_lan_discovery_service(airxPointer, shouldInterrupt)
        }))
        
        // Reset interrupt flag and start the services!
        interrupt = false
        for t in threads {
            t.start()
        }
        startMonitoringClipboard()
        GlobalState.shared.isServiceOnline = true
    }

    // Services stop at their next ticks.
    public static func initiateStopAsync() {
        interrupt = true
        for t in threads {
            t.cancel()
        }
        threads.removeAll()
        stopMonitoringClipboard()
        GlobalState.shared.isServiceOnline = false
    }
    
    public static func readCurrentPeers() -> Array<String> {
        let buffer = UnsafeMutablePointer<CChar>
            .allocate(capacity: 4096)
        let len = Int(airx_get_peers(airxPointer, buffer))

        // 简单封个口
        buffer.advanced(by: len).assign(repeating: 0, count: 1)
        
        // Decode and free.
        let ret = String(cString: buffer)
        buffer.deallocate()

        return ret.split(separator: .init(unicodeScalarLiteral: ","))
            .map({ substring in String(substring) })
    }
    
    private static func startMonitoringClipboard() {
        stopMonitoringClipboard()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if self.lastPasteboardChangeCount != pasteboard.changeCount {
                self.lastPasteboardChangeCount = pasteboard.changeCount
                if let newContent = pasteboard.string(forType: .string), newContent != self.lastPasteboardContent {
                    self.lastPasteboardContent = newContent
                    self.onPasteboardChanged(newContent: newContent)
                }
            }
        }
    }
    
    private static func stopMonitoringClipboard() {
        timer?.invalidate()
        timer = nil
    }
    
    private static func onPasteboardChanged(newContent: String) {
        guard newContent != lastIncomingString else {
            // Prevent recursive copy-send.
            print("Prevented recursive copy-send.")
            return
        }

        print("Clipboard changed, broadcasting new text.")
        let buffer = newContent.toBuffer()
        airx_broadcast_text(airxPointer!, buffer, newContent.utf8Size())
        buffer.deallocate()
    }
}
