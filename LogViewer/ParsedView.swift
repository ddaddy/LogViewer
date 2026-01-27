//
//  ParsedView.swift
//  LogViewer
//
//  Created by Darren Jones on 15/06/2022.
//

import Foundation
import SwiftUI

struct ParsedView: View {
    
    var htmlString: String? {
        didSet {
            parser.htmlString = htmlString
        }
    }
    @StateObject private var parser: Parser = Parser()
    @State var filters = Set<Filter>()
    @State private var selectedSessionIndex: Int?
    private var filteredLines: [Line] {
        var lines = parser.lines
        if let selectedSessionIndex = selectedSessionIndex {
            lines = lines.filter { $0.sessionIndex == selectedSessionIndex }
        }
        let filtered = lines.filter({ filters.contains($0.type!) })
        return filtered.count == 0 ? lines : filtered
    }

    private var sessionLines: [Line] {
        parser.lines.filter { $0.type?.id == Filter.newSession.id }
    }

    private var sessionMenuTitle: String {
        guard let selectedSessionIndex = selectedSessionIndex,
              let line = sessionLines.first(where: { $0.sessionIndex == selectedSessionIndex }) else {
            return "All Sessions"
        }
        return sessionTitle(for: line)
    }

    private func sessionTitle(for line: Line) -> String {
        let raw = line.text
        if let title = raw.slice(from: "===== NEW SESSION ", to: " =====") {
            return shortSessionTitle(from: title)
        }
        return raw
    }

    private func shortSessionTitle(from title: String) -> String {
        guard let atRange = title.range(of: " at ") else { return title }
        var datePart = String(title[..<atRange.lowerBound])
        let timeAndZone = title[atRange.upperBound...]

        if let commaRange = datePart.range(of: ", ") {
            datePart = String(datePart[commaRange.upperBound...])
        }

        let dateParts = datePart.split(separator: " ")
        guard dateParts.count >= 2 else { return title }

        let day = String(dateParts[0])
        let month = String(dateParts[1])
        let monthShort = monthShortName(month)

        guard let timeToken = timeAndZone.split(separator: " ").first else { return title }
        let timeString = String(timeToken.prefix(5))

        return "\(day) \(monthShort) \(timeString)"
    }

    private func monthShortName(_ month: String) -> String {
        switch month.lowercased() {
        case "january": return "Jan"
        case "february": return "Feb"
        case "march": return "Mar"
        case "april": return "Apr"
        case "may": return "May"
        case "june": return "Jun"
        case "july": return "Jul"
        case "august": return "Aug"
        case "september": return "Sep"
        case "october": return "Oct"
        case "november": return "Nov"
        case "december": return "Dec"
        default: return month
        }
    }
    
    @State var expandedLines = Set<Line>()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            
            List {
                Section {
                    ScrollView(.horizontal) {
                        HStack(alignment: .center, spacing: 00) {
                            ForEach(parser.filters) { filter in
                                filterRow(filter)
                                    .frame(height: 40)
                                    .padding(.horizontal)
                                    .background(filter.colour)
                            }
                        }
                    }
                }
                
                Section {
                    ForEach(filteredLines) { line in
                        dataLine(line)
                            .listRowBackground(line.type?.colour)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = line.text
                                } label: {
                                    Text("Copy to clipboard")
                                    Image(systemName: "doc.on.doc")
                                }

                            }
                        
                        if expandedLines.contains(line),
                           let childLines = line.childLines {
                            ForEach(childLines) { childLine in
                                dataLine(childLine)
                                    .contextMenu {
                                        Button {
                                            UIPasteboard.general.string = childLine.text
                                        } label: {
                                            Text("Copy to clipboard")
                                            Image(systemName: "doc.on.doc")
                                        }

                                    }
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if !sessionLines.isEmpty {
                    Menu {
                        Button("All Sessions") {
                            selectedSessionIndex = nil
                        }
                        ForEach(sessionLines) { line in
                            if let sessionIndex = line.sessionIndex {
                                Button(sessionTitle(for: line)) {
                                    selectedSessionIndex = sessionIndex
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(sessionMenuTitle)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    filters.removeAll()
                    expandedLines.removeAll()
                    selectedSessionIndex = nil
                }
            }
        }
        .onAppear {
            parser.htmlString = htmlString
        }
        .onChange(of: parser.dismiss) { newValue in
            if newValue == true {
                dismiss()
            }
        }
    }
}

// MARK: - Filter rows
extension ParsedView {
    
    @ViewBuilder
    private func filterRow(_ filter: Filter) -> some View {
        
        Button {
            if filters.contains(filter) {
                filters.remove(filter)
            } else {
                filters.insert(filter)
            }
        } label: {
            HStack(alignment: .center) {
                if filters.contains(filter) {
                    Image(systemName: "checkmark")
                }
                Text(filter.title)
            }
            .frame(minWidth: 60)
            .foregroundColor(Color.primary)
        }
    }
}

// MARK: - Data lines
extension ParsedView {
    
    @ViewBuilder
    private func dataLine(_ line: Line) -> some View {
        
        if line.expandable {
            expandableDataLine(line)
        } else {
            HStack {
                Spacer()
                    .frame(width: 15)
                Text(line.text)
                Spacer()
                if let code = line.code {
                    Text("\(code)")
                }
            }
        }
    }
    
    @ViewBuilder
    private func expandableDataLine(_ line: Line) -> some View {
        
        Button {
            if expandedLines.contains(line) {
                expandedLines.remove(line)
            } else {
                expandedLines.insert(line)
            }
        } label: {
            HStack {
                Image(systemName: expandedLines.contains(line) ? "chevron.down" : "chevron.right")
                    .frame(minWidth: 15)
                Text(line.text)
                Spacer()
                if let code = line.code {
                    Text("\(code)")
                }
            }
        }
        
    }
}
