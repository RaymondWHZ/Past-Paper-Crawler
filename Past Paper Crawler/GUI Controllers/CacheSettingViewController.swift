//
//  CacheSettingViewController.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2019/5/4.
//  Copyright © 2019 吴浩榛. All rights reserved.
//

import Cocoa

class CacheTableCell : NSTableCellView {
    
    @IBOutlet var cacheName: NSTextField!
    @IBOutlet var removeButton: NSButton!
    
    var removeCallback: (String) -> () = { _ in }
    
    override func viewDidMoveToWindow() {
        addTrackingRect(bounds, owner: self, userData: nil, assumeInside: true)
    }
    
    @IBAction func removeClicked(_ sender: Any) {
        removeArray(for: cacheName.stringValue)
        removeCallback(cacheName.stringValue)
    }
    
    override func mouseEntered(with event: NSEvent) {
        removeButton.isHidden = false
    }
    
    override func mouseExited(with event: NSEvent) {
        removeButton.isHidden = true
    }
}

class CacheSettingViewController : NSViewController {
    
    @IBOutlet var cacheToDiskCheckBox: NSButton!
    @IBOutlet var cacheTable: NSTableView!
    var cacheArray: [String] = [] {
        didSet {
            cacheTable.reloadData()
        }
    }
    
    override func viewDidLoad() {
        cacheTable.dataSource = self
        cacheTable.delegate = self
        
        cacheToDiskCheckBox.state = PFCacheToDisk ? .on : .off
    }
    
    override func viewDidAppear() {
        cacheArray = diskCachedKeys
    }
    
    @IBAction func cacheToDiskClicked(_ sender: Any) {
        PFCacheToDisk = cacheToDiskCheckBox.state == .on
    }
    
    @IBAction func openFolderClicked(_ sender: Any) {
        workspace.openFile(cacheDirectory)
    }
    
    @IBAction func removeAllClicked(_ sender: Any) {
        cacheArray.forEach { removeArray(for: $0) }
        cacheArray.removeAll()
    }
}

extension CacheSettingViewController : NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return cacheArray.count
    }
}

extension CacheSettingViewController : NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let view = cacheTable.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Cache Table Cell"), owner: self) as? CacheTableCell {
            view.cacheName.stringValue = cacheArray[row]
            view.removeCallback = { removedName in
                if let index = self.cacheArray.firstIndex(of: removedName) {
                    self.cacheArray.remove(at: index)
                }
            }
            return view
        }
        return nil
    }
}
