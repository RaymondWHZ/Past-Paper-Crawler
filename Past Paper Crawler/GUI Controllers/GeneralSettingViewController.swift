//
//  SettingViews.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/28.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa
import Automator

class GeneralSetViewController: NSViewController {
    
    @IBOutlet var websitePopButton: NSPopUpButton!
    var lazyWebsiteSelection: String = PFUsingWebsiteName
    
    @IBOutlet var showAllCheckBox: NSButton!
    
    @IBOutlet var askEverytimeOption: NSButton!
    @IBOutlet var useDefaultOption: NSButton!
    @IBOutlet var pathControl: NSPathControl!
    @IBOutlet var browseButton: NSButton!
    @IBOutlet var createFolderCheckBox: NSButton!
    @IBOutlet var openInFinderCheckBox: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        websitePopButton.addItems(withTitles: Array(PFWebsites.keys))
        websitePopButton.selectItem(withTitle: PFUsingWebsiteName)
        
        showAllCheckBox.state = (PFDefaultShowAll) ? .on : .off
        
        let onOption = (PFUseDefaultPath) ? useDefaultOption : askEverytimeOption
        onOption!.state = .on
        savePolicySelected(onOption!)
        
        pathControl.url = URL(fileURLWithPath: PFDefaultPath)
        
        createFolderCheckBox.state = (PFCreateFolder) ? .on : .off
        
        openInFinderCheckBox.state = (PFOpenInFinder) ? .on : .off
    }
    
    @IBAction func websiteSelected(_ sender: Any) {
        let websiteSelection = websitePopButton.selectedItem!.title
        let websiteSelected = PFWebsites[websiteSelection]!
        let subjectUtil = SubjectUtil.get(for: websiteSelected)
        
        // check quick list
        
        let loadingView: LoadingListView = getController("Loading List View")!
        loadingView.cancelCallBack = {
            PFUsingWebsiteName = self.lazyWebsiteSelection
            self.websitePopButton.selectItem(withTitle: PFUsingWebsiteName)
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
            
            PFModifyQuickList({ (quickList) in
                for (index, subject) in quickList.enumerated() {
                    let level = subject.level
                    let name = subject.name
                    
                    let availableSubjects = sl![level]!
                    if availableSubjects.contains(name) {  // try to get subject from name
                        if !subject.enabled {  // special case with previously disabled subject
                            quickList[index] = subject.copy(alterEnabled: true)
                            operations.append((name, "Enabled"))
                        }
                        continue
                    }
                    
                    let code = getSubjectCode(of: name)  // try to get subject from code
                    if let subject = subjectUtil.findSubject(with: code) {
                        quickList[index] = subject
                        operations.append((name, "Renamed to " + subject.name))
                    }
                    else {
                        quickList[index] = subject.copy(alterEnabled: false)
                        operations.append((name, "Disabled"))
                    }
                }
            })
            
            DispatchQueue.main.async {
                loadingView.dismiss(nil)
                
                if !operations.isEmpty {
                    let renameView: RenameViewController = getController("Rename View Controller")!
                    renameView.operations = operations
                    self.presentAsSheet(renameView)
                    renameView.operationsTableView.reloadData()
                }
                
                PFUsingWebsiteName = websiteSelection
                self.lazyWebsiteSelection = PFUsingWebsiteName
            }
        }
    }
    
    @IBAction func showModeSelected(_ sender: Any) {
        PFDefaultShowAll = showAllCheckBox.state == .on
    }
    
    @IBAction func savePolicySelected(_ sender: Any) {
        if sender as? NSButton == useDefaultOption {
            PFUseDefaultPath = true
            askEverytimeOption.state = .off
            pathControl.isEnabled = true
            browseButton.isEnabled = true
        }
        else {
            PFUseDefaultPath = false
            useDefaultOption.state = .off
            pathControl.isEnabled = false
            browseButton.isEnabled = false
        }
    }
    
    @IBAction func browseClicked(_ sender: Any) {
        directoryOpenPanel.begin { result in
            if result == .OK, let url = directoryOpenPanel.url {
                self.pathControl.url = url
                PFDefaultPath = url.path
            }
        }
    }
    
    @IBAction func createFolderOptionChanged(_ sender: Any) {
        PFCreateFolder = createFolderCheckBox.state == .on
    }
    
    @IBAction func openInFinderOptionChanged(_ sender: Any) {
        PFOpenInFinder = openInFinderCheckBox.state == .on
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
    
    override func viewDidLoad() {
        operationsTableView.dataSource = self
    }
}

extension RenameViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return operations.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if row >= operations.count {
            return nil
        }
        if tableColumn!.title == "Subject name" {
            return operations[row].0
        }
        else {
            return operations[row].1
        }
    }
}

