//
//  Filter.swift
//  LogViewer
//
//  Created by Darren Jones on 15/06/2022.
//

import SwiftUI
import CryptoKit

struct Filter: Identifiable, Hashable {
    
    var id: UUID
    var title: String
    var colour: Color
    
    init?(string: String) {
        
        if let uuidString = string.slice(from: "for=\"", to: "\""),
           let uuid = UUID(uuidString: uuidString),
           let title = string.removeLinebreaks().slice(from: " />", to: "</label>"),
           let hexColour = string.slice(from: "background-color: #", to: ";"),
           let colour = Color(hexColour) {
            
            self.title = title
            self.id = uuid
            self.colour = colour
            
            return
        }
        
        return nil
    }
    
    private init(id: UUID, title: String) {
        self.id = id
        self.title = title
        self.colour = .green
    }
    
    private static var newSessionId: UUID { uuidV5(namespace: DJLogTypeNamespace, name: "New Session") }
    
    static var newSession: Filter {
        return Filter(
            id: newSessionId,
            title: "New Session")
    }
}

fileprivate extension Color {
    
    init?(_ hex: String) {
        var str = hex
        if str.hasPrefix("#") {
            str.removeFirst()
        }
        if str.count == 3 {
            str = String(repeating: str[str.startIndex], count: 2)
            + String(repeating: str[str.index(str.startIndex, offsetBy: 1)], count: 2)
            + String(repeating: str[str.index(str.startIndex, offsetBy: 2)], count: 2)
        } else if !str.count.isMultiple(of: 2) || str.count > 8 {
            return nil
        }
        let scanner = Scanner(string: str)
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        if str.count == 2 {
            let gray = Double(Int(color) & 0xFF) / 255
            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: 1)
        } else if str.count == 4 {
            let gray = Double(Int(color >> 8) & 0x00FF) / 255
            let alpha = Double(Int(color) & 0x00FF) / 255
            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: alpha)
        } else if str.count == 6 {
            let red = Double(Int(color >> 16) & 0x0000FF) / 255
            let green = Double(Int(color >> 8) & 0x0000FF) / 255
            let blue = Double(Int(color) & 0x0000FF) / 255
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
        } else if str.count == 8 {
            let red = Double(Int(color >> 24) & 0x000000FF) / 255
            let green = Double(Int(color >> 16) & 0x000000FF) / 255
            let blue = Double(Int(color >> 8) & 0x000000FF) / 255
            let alpha = Double(Int(color) & 0x000000FF) / 255
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
        } else {
            return nil
        }
    }
}

// MARK: - Make sure we always have the same UUID for a type
// RFC-4122 namespace for DJLogging log-types.
// Pick any fixed UUID *once*; don’t ever change it afterwards
private let DJLogTypeNamespace = UUID(uuidString: "8E8AE4C2-0EAD-2493-90F0-3F26366C6349")!

/// SHA-1 / SHA-256 based UUID-v5 generator
private func uuidV5(namespace: UUID, name: String) -> UUID {
    guard #available(macOS 10.15, iOS 13.0, *) else { return UUID() }
    var hasher = SHA256()
    withUnsafeBytes(of: namespace.uuid) { hasher.update(bufferPointer: $0) }
    hasher.update(data: Data(name.utf8))
    let digest = hasher.finalize()           // 32 bytes; we need only the first 16
    let bytes  = Array(digest.prefix(16))

    // Copy into tuple and patch version / variant bits
    var uuid = (
        bytes[0], bytes[1], bytes[2], bytes[3],
        bytes[4], bytes[5],
        bytes[6], bytes[7],
        bytes[8], bytes[9],
        bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
    )
    uuid.6  = (uuid.6  & 0x0F) | 0x50    // version 5
    uuid.8  = (uuid.8  & 0x3F) | 0x80    // RFC 4122 variant

    return UUID(uuid: uuid)
}
