//
//  SourceEditorCommand.swift
//  EmojifyMe
//
//  Created by Eric Kunz on 7/13/16.
//
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
        
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: (NSError?) -> Void ) -> Void {
        
        var updatedLineIndexes = [Int]()
        
        guard let selections = invocation.buffer.selections as NSMutableArray as? [XCSourceTextRange] else {
            completionHandler(NSError(domain: "EmojifyExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "No selection"]))
            return
        }
        
        for selection in selections {
            
            for index in selection.start.line...selection.end.line {
                
                guard var line = invocation.buffer.lines[index] as? String else { continue }
                
                let rangeStart = line.index(line.startIndex, offsetBy: index == selection.start.line ? selection.start.column : 0)
                var rangeEnd = index == selection.end.line ? line.index(line.startIndex, offsetBy: selection.end.column + 1) : line.endIndex
                
                for emojo in emoji {
                    if line.localizedCaseInsensitiveContains(emojo.value) {
                        let range = rangeStart..<rangeEnd
                        let newLine = line.replacingOccurrences(of: emojo.value, with: emojo.key, options: .caseInsensitive, range: range)
                        invocation.buffer.lines[index] = newLine
                        if !updatedLineIndexes.contains(index) { updatedLineIndexes.append(index) }
                        rangeEnd = line.index(rangeEnd, offsetBy: line.distance(from: line.endIndex, to: newLine.endIndex))
                        line = newLine
                    }
                }
            }
        }
        
        if !updatedLineIndexes.isEmpty {
            let updatedSelections: [XCSourceTextRange] = updatedLineIndexes.map { lineIndex in
                let lineSelection = XCSourceTextRange()
                lineSelection.start = XCSourceTextPosition(line: lineIndex, column: 0)
                lineSelection.end = XCSourceTextPosition(line: lineIndex + 1, column: 0)
                return lineSelection
            }
            invocation.buffer.selections.setArray(updatedSelections)
        }
        
        completionHandler(nil)
    }
    
}
