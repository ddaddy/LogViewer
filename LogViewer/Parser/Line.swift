//
//  Lines.swift
//  LogViewer
//
//  Created by Darren Jones on 15/06/2022.
//

import SwiftUI

class Line: Identifiable, Hashable {
    
    var id: UUID = UUID()
    
    var expandable: Bool
    var dateString: String?
    var text: String
    /// `filterId` matches a uuid in the filters to show the correct type and colour
    var filterId: UUID?
    /// `uuid` groups lines together, so we can filter out a request and response. Not all lines have it.
    var uuid: UUID?
    var code: Int?
    /// `parentId` belongs to the parent row that has hidden associated rows.
    var parentId: UUID?
    /// `childLines` will be added afterwards by the parser.
    var childLines: [Line]?
    /// `sessionIndex` groups lines by the "New Session" markers.
    var sessionIndex: Int?
    
    // MARK: - Hidden rows
    var isHidden: Bool = false
    /// `hiddenId` is the `UUID` that matches the parent `parentId`
    var hiddenId: UUID?
    
    // `type` will be added afterwards by the parser
    var type: Filter?
    
    init?(string: String) {
        
        if let tr = string.slice(from: nil, to: ">"),
           let dateString = string.slice(from: "<td class=\"date\">", to: "</td>"),
           let codeString = string.slice(from: "<td class=\"code\">", to: "</td>"),
           let text = string.slice(from: "<td class=\"title\">", to: "</td>") {
            
            self.expandable = tr.contains("class=\"expandable\"")
            self.dateString = dateString
            self.text = text
            
            if let id = tr.slice(from: "id=\"", to: "\"") {
                let idUUID = UUID(uuidString: id)
                self.filterId = idUUID
            }
            
            if let uuidString = string.slice(from: "<td class=\"uuid\" onclick=\"filter('", to: "')\">") {
                self.uuid = UUID(uuidString: uuidString)
            }
            
            if let code = Int(codeString) {
                self.code = code
            }
            
            if let parentUUIDString = tr.slice(from: "onclick=\"showHideRow('", to: "');"),
               let parentUUID = UUID(uuidString: parentUUIDString) {
                self.parentId = parentUUID
            }
            
            return
            
        } else if let tr = string.slice(from: nil, to: ">"),
                  let hiddenUUIDString = tr.slice(from: "class=\"hidden_row ", to: "\""),
                  let hiddenUUID = UUID(uuidString: hiddenUUIDString),
                  let text = string.slice(from: "<td colspan=7>", to: "</td>") {
            
            self.isHidden = true
            self.hiddenId = hiddenUUID
            self.expandable = false
            self.text = text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .decodingHTMLEntities()
                .replacingOccurrences(of: "<br />", with: "\n")
            
            return
        }
        
        print("Not parsed", string)
        
        return nil
    }
}

// MARK: - Hashable
extension Line {
    
    static func == (lhs: Line, rhs: Line) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Debug
extension Line: CustomStringConvertible {
    
    var description: String {
        
        var topRow = "\(dateString ?? "") \t\(type?.title ?? "") \t\(uuid?.uuidString ?? "") \t"
        if topRow.count == 4 {
            topRow = ""
        }
        
        var childlines = ""
        if let childLines = childLines,
           childLines.count > 0 {
            childlines = "\n\(childLines)"
        }
        
        return "\(topRow)\(text)\(childlines)"
    }
}
