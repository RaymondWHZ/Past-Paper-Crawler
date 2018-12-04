//
//  PublicConstants.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/4.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

let storyboard = NSStoryboard(name: "Main", bundle: nil)
func getController<T>(_ name: String) -> T? {
    let rawValue = storyboard.instantiateController(withIdentifier: name)
    return rawValue as? T
}

let notificationCenter = NotificationCenter.default
let userDefaults = UserDefaults.standard
let fileManager = FileManager.default
let workspace = NSWorkspace.shared

var directoryOpenPanel: NSOpenPanel {
    let openPanel = NSOpenPanel()
    openPanel.canChooseFiles = false
    openPanel.canChooseDirectories = true
    openPanel.canCreateDirectories = true
    openPanel.treatsFilePackagesAsDirectories = true
    return openPanel
}
