//
//  PromptLabelControllers.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/30.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Cocoa

class PromptLabelController {
    private let label: NSTextField
    
    private let defaultIsHidden: Bool
    private let defaultColor: NSColor
    private let defaultText: String
    
    var currentText: String {
        return label.stringValue
    }
    
    init (_ label: NSTextField) {
        self.label = label
        
        defaultIsHidden = label.isHidden
        defaultColor = label.textColor!
        defaultText = label.stringValue
    }
    
    func showPrompt(_ message: String) {
        label.isHidden = false
        label.textColor = NSColor.black
        label.stringValue = message
    }
    
    func showError(_ message: String) {
        label.isHidden = false
        label.textColor = NSColor.red
        label.stringValue = "Error: " + message
    }
    
    func setToDefault() {
        label.isHidden = defaultIsHidden
        label.textColor = defaultColor
        label.stringValue = defaultText
    }
}
