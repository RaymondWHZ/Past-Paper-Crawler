//
//  SettingViews.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/28.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

class GeneralSetViewController: NSViewController {
    
    @IBOutlet var websitePopButton: NSPopUpButton!
    var lazyWebsiteSelection: String = usingWebsiteName
    
    @IBOutlet var showAllCheckBox: NSButton!
    
    @IBOutlet var askEverytimeOption: NSButton!
    @IBOutlet var useDefaultOption: NSButton!
    @IBOutlet var pathTextField: NSTextField!
    @IBOutlet var browseButton: NSButton!
    @IBOutlet var createFolderCheckBox: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        websitePopButton.addItems(withTitles: Array(websites.keys))
        websitePopButton.selectItem(withTitle: usingWebsiteName)
        
        showAllCheckBox.state = (defaultShowAll) ? .on : .off
        
        let onOption = (useDefaultPath) ? useDefaultOption : askEverytimeOption
        onOption!.state = .on
        savePolicySelected(onOption!)
        
        pathTextField.stringValue = defaultPath
        
        createFolderCheckBox.state = (createFolder) ? .on : .off
    }
    
    @IBAction func websiteSelected(_ sender: Any) {
        let websiteSelection = websitePopButton.selectedItem!.title
        let websiteSelected = websites[websiteSelection]!
        let subjectUtil = SubjectUtil.get(for: websiteSelected)
        
        // check quick list
        
        let loadingView = getController("Loading List View") as! LoadingListView
        loadingView.cancelCallBack = {
            usingWebsiteName = self.lazyWebsiteSelection
            self.websitePopButton.selectItem(withTitle: usingWebsiteName)
        }
        
        self.presentAsSheet(loadingView)
        
        DispatchQueue.global(qos: .userInteractive).async {
            // time requiring operation
            let sl = subjectUtil.subjectLists
            
            // check if cancelled during time required operation
            if loadingView.cancelled {
                return
            }
            
            // ensure not nil
            if sl == nil {
                DispatchQueue.main.async {
                    loadingView.markFailed()
                }
                return
            }
            
            var operations: [(String, String)] = []
            
            for (index, subject) in quickList.enumerated() {
                let level = subject["level"]!
                var name = subject["name"]!
                var disabled = false
                if name.hasPrefix("*") {
                    name.removeFirst()
                    disabled = true
                }
                
                let availableSubjects = sl![level]!
                if availableSubjects.contains(name) {
                    if disabled {
                        quickList[index]["name"] = name
                        operations.append((name, "Enabled"))
                    }
                    continue
                }
                
                let code = getSubjectCode(of: name)
                if let finding = subjectUtil.findSubject(with: code) {
                    quickList[index] = ["level": finding.0, "name": finding.1]
                    operations.append((name, "Renamed to " + finding.1))
                }
                else {
                    quickList[index]["name"]!.insert("*", at: name.startIndex)
                    operations.append((name, "Disabled"))
                }
            }
            
            DispatchQueue.main.async {
                loadingView.dismiss(nil)
                
                if !operations.isEmpty {
                    let renameView = getController("Rename View Controller") as! RenameViewController
                    renameView.operations = operations
                    self.presentAsSheet(renameView)
                    renameView.operationsTableView.reloadData()
                }
                
                usingWebsiteName = websiteSelection
                self.lazyWebsiteSelection = usingWebsiteName
            }
        }
    }
    
    @IBAction func showModeSelected(_ sender: Any) {
        defaultShowAll = showAllCheckBox.state == .on
    }
    
    @IBAction func savePolicySelected(_ sender: Any) {
        useDefaultPath = sender as? NSButton == useDefaultOption
        ((useDefaultPath) ? askEverytimeOption : useDefaultOption)!.state = .off
        pathTextField.isEditable = useDefaultPath
        browseButton.isEnabled = useDefaultPath
    }
    
    @IBAction func pathChanged(_ sender: Any) {
        defaultPath = pathTextField.stringValue
    }
    
    @IBAction func browseClicked(_ sender: Any) {
        directoryOpenPanel.begin { result in
            if result == .OK {
                defaultPath = directoryOpenPanel.url!.path
                self.pathTextField.stringValue = defaultPath
            }
        }
    }
    @IBAction func createFolderOptionChanged(_ sender: Any) {
        createFolder = createFolderCheckBox.state == .on
    }
}



class LoadingListView: NSViewController {
    
    @IBOutlet var progressBar: NSProgressIndicator!
    @IBOutlet var failedLabel: NSTextField!
    var cancelled = false
    var cancelCallBack = {}
    
    override func viewDidLoad() {
        progressBar.startAnimation(nil)
    }
    
    func markFailed() {
        failedLabel.isHidden = false
        progressBar.stopAnimation(nil)
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        cancelled = true
        dismiss(nil)
        cancelCallBack()
    }
}

class RenameViewController: NSViewController {
    
    private var subject: UnsafeMutablePointer<Dictionary<String, String>>? = nil
    private var newSubject: Dictionary<String, String>? = nil
    @IBOutlet var operationsTableView: NSTableView!
    var operations: [(String, String)] = []
    var selected: [Bool] = []
    
    override func viewDidLoad() {
        operationsTableView.dataSource = self
    }
}

extension RenameViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        let count = operations.count
        selected = Array(repeating: true, count: count)
        return count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableColumn!.title == "Subject name" {
            return operations[row].0
        }
        else {
            return operations[row].1
        }
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let state = object as! Int == 1  // cast Any to Bool
        selected[row] = state
    }
}

