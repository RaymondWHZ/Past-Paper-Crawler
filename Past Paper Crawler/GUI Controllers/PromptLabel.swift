//
//  PromptLabelControllers.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/30.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Cocoa

class PromptLabel: NSTextField {
    
    private var settedUp = false
    
    private var isDefault = false
    var defaultIsHidden: Bool = false {
        didSet {
            restore()
        }
    }
    var defaultColor: NSColor? {
        didSet {
            restore()
        }
    }
    var defaultText: String = "" {
        didSet {
            restore()
        }
    }
    
    override func viewDidMoveToWindow() {
        if settedUp {
            return
        }
        settedUp = true
        
        defaultIsHidden = isHidden
        defaultColor = textColor
        defaultText = stringValue
        isDefault = true
    }
    
    func showPrompt(_ message: String) {
        isDefault = false
        isHidden = false
        textColor = NSColor.black
        stringValue = message
    }
    
    func showError(_ message: String) {
        isDefault = false
        isHidden = false
        textColor = NSColor.red
        stringValue = "Error: " + message
    }
    
    func setToDefault() {
        isDefault = true
        restore()
    }
    
    private func restore() {
        if isDefault {
            isHidden = defaultIsHidden
            textColor = defaultColor
            stringValue = defaultText
        }
    }
}
