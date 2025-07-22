//
//  Parser.swift
//  LogViewer
//
//  Created by Darren Jones on 15/06/2022.
//

import Foundation
import SwiftUI

class Parser: ObservableObject {
    
    var htmlString: String? {
        didSet {
            parse()
        }
    }
    
    @Published var filters: [Filter] = []
    @Published var lines: [Line] = []
    @Published var dismiss: Bool = false
    
    private func parse() {
        
        guard let htmlString = htmlString,
              htmlString.contains("<fieldset id=\"filterList\">") else {

            dismiss.toggle()
            return
        }
        
        let filters = parseFilters(htmlString)
        self.filters = filters
        
        let lines = parseLines(htmlString)
        let merged = self.mergeLinesAndFilters(lines: lines, filters: filters)
        let parents = self.mergeParentsAndChildren(lines: merged)
        
        self.lines = parents
    }
}

extension Parser {
    
    private func parseFilters(_ htmlString: String) -> [Filter] {
        
        var res = [Filter]()
        if let fieldset = htmlString.slice(from: "<fieldset id=\"filterList\">", to: "</fieldset>") {
            let arr = fieldset.components(separatedBy: "<label", minimumLength: 20)
            res = arr.compactMap({ Filter(string: $0) })
        }
        // Manually add the new Session filter, as we missed it off the logging framework.
        if !res.contains(.newSession) {
            res.append(.newSession)
        }
        return res
    }
    
    private func parseLines(_ htmlString: String) -> [Line] {
        
        if let table = htmlString.slice(from: "<table border=1>", to: "</table>") {
            let arr = table.components(separatedBy: "<tr ", minimumLength: 20)
            return arr.compactMap({ Line(string: $0) })
        }
        return []
    }
    
    private func mergeLinesAndFilters(lines: [Line], filters: [Filter]) -> [Line] {
        
        let mapped = lines.map({ line -> Line in
            line.type = filters.first(where: { $0.id == line.filterId })
            return line
        })
        
        return mapped
    }
    
    private func mergeParentsAndChildren(lines: [Line]) -> [Line] {
        let parents = lines.filter({ !$0.isHidden })
        let children = lines.filter({ $0.isHidden })
        
        let m = parents.map { pline -> Line in
            pline.childLines = children.filter({ $0.hiddenId == pline.parentId })
            return pline
        }
        
        return m
    }
}

extension String {
    
    /**
     Removes linebreaks
     */
    func removeLinebreaks() -> String {
        self.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
    }
    
    /**
     Returns a string that occurs between 2 strings
     Omitting a from or to string will return including the start/end of the string.
     */
    func slice(from: String? = nil, to: String? = nil) -> String? {
        var rangeFrom = range(of: from ?? "%$£somethingthatshouldntappearinthestring£$%")?.upperBound
        if (from == nil) { rangeFrom = startIndex }
        guard let rangeFrom = rangeFrom else { return nil }
        
        var rangeTo = self[rangeFrom...].range(of: to ?? "%$£somethingthatshouldntappearinthestring£$%")?.lowerBound
        if (to == nil) { rangeTo = endIndex }
        guard let rangeTo = rangeTo else { return nil }
        
        return String(self[rangeFrom..<rangeTo])
    }
    
    /**
     Returns an array containing substrings from the string that have been divided by characters in the given string.
     But omits any smaller than the minimum length.
     */
    func components<T>(separatedBy separator: T, minimumLength:UInt) -> [String] where T: StringProtocol {
        components(separatedBy: separator)
            .filter({ $0.count > minimumLength })
    }
}
