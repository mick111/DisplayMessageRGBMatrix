//
//  ConnectionController.swift
//  DisplayMessage
//
//  Created by Michael Mouchous on 11/03/2017.
//  Copyright © 2017 Michael Mouchous. All rights reserved.
//

import Foundation


class ConnectionController: NSObject {
    let so = UInt32(MemoryLayout<sockaddr>.size)
    var sock: Int32! = nil
    var connected : Bool { return sock != nil }
    
    func send(message : String) throws {
        guard connected, var data = message.data(using: .utf8) else { return }
        
        var int8 = [Int8].init(repeating: 0, count: data.count)
        _=data.copyBytes(to: int8.withUnsafeMutableBufferPointer {$0})
        
        if Darwin.send(sock, int8, int8.count, 0) == -1 {
            sock = nil
            throw NSError(domain: NSPOSIXErrorDomain,
                          code: Int(errno), userInfo: nil)
        }
        
    }
    
    func disconnect() {
        guard sock != nil else { return }
        close(sock)
        sock = nil
    }
    
    func connect(host: String, port: UInt16) throws {
        disconnect()
        let port = port == 0 ? 23735 : port
        guard let hostInfo = gethostbyname(host),
            let list = hostInfo.pointee.h_addr_list,
            let h_addr = list.pointee else {
                throw NSError(domain: NSPOSIXErrorDomain,
                             code: Int(errno), userInfo: nil)
        }
        
        var sin = sockaddr_in()
        sin.sin_addr = h_addr.withMemoryRebound(to: in_addr.self, capacity: 1){$0}.pointee
        sin.sin_port = port.bigEndian
        sin.sin_family = sa_family_t(AF_INET)
        sock = socket(AF_INET, SOCK_STREAM, 0)
        
        var on = Int32(1)
        if setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, &on, 4) == -1 {
            throw NSError(domain: NSPOSIXErrorDomain,
                          code: Int(errno), userInfo: nil)
        }
        
        var sockadd = withUnsafePointer(to: &sin) { $0 }.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0.pointee }
        
        guard Darwin.connect(sock, &sockadd, so) != -1 || errno == EISCONN else {
            sock = nil
            throw NSError(domain: NSPOSIXErrorDomain,
                          code: Int(errno), userInfo: nil)
        }
        let hostPort = host + ":\(port)"
        UserDefaults.standard.set([hostPort] + self.lastServers.filter { $0 != (host, port) }.map { $0.0 + ":\($0.1)" }, forKey: "lastServers")
    }
    
    var lastServers : [(String, UInt16)] {
        let lastServers = UserDefaults.standard.array(forKey: "lastServers") as? [String] ?? []
        return lastServers.map {
            let host_port = $0.components(separatedBy: ":")
            return (host_port.first ?? "", UInt16(host_port.last ?? "0") ?? 0)
        }
    }
    
    func showTime() throws {
        try send(message: "HOUR\n")
    }
    func nyan() throws {
        try send(message: "NYAN\n")
    }
    func dedim() throws {
        try send(message: "DEDIM\n")
    }
    func setMessage(text: String) throws {
        try send(message: "TEXT \(text.utf8)\n")
    }
    func setMessage(color : (red: Float, green: Float, blue: Float)) throws {
        try send(message: "COLOR \(color.red) \(color.green) \(color.blue)\n")
    }
    func setMessage(bgcolor : (red: Float, green: Float, blue: Float)) throws {
        try send(message: "BGCOLOR \(bgcolor.red) \(bgcolor.green) \(bgcolor.blue)\n")
    }
    func setMessage(color : String) throws {
        try send(message: "COLOR \(color)\n")
    }
}
