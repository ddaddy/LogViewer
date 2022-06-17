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
    private var filteredLines: [Line] {
        let f = parser.lines.filter({ filters.contains($0.type!) })
        return f.count == 0 ? parser.lines : f
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    filters.removeAll()
                    expandedLines.removeAll()
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
