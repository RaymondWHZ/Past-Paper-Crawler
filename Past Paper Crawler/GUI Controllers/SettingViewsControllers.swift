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
    
    @IBOutlet var showAllCheckBox: NSButton!
    
    @IBOutlet var askEverytimeOption: NSButton!
    @IBOutlet var useDefaultOption: NSButton!
    @IBOutlet var pathTextField: NSTextField!
    @IBOutlet var browseButton: NSButton!
    @IBOutlet var createFolderCheckBox: NSButton!
    
    let openPanel = NSOpenPanel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        websitePopButton.addItems(withTitles: Array(websites.keys))
        websitePopButton.selectItem(withTitle: userDefaults.string(forKey: websiteToken)!)
        
        let showAll = userDefaults.bool(forKey: defaultShowAllToken)
        showAllCheckBox.state = (showAll) ? .on : .off
        
        let useDefaultPath = userDefaults.bool(forKey: useDefualtPathToken)
        let onOption = (useDefaultPath) ? useDefaultOption : askEverytimeOption
        onOption!.state = .on
        savePolicySelected(onOption!)
        
        pathTextField.stringValue = userDefaults.string(forKey: defaultPathToken)!
        
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.treatsFilePackagesAsDirectories = true
        
        let createFolder = userDefaults.bool(forKey: createFolderToken)
        createFolderCheckBox.state = (createFolder) ? .on : .off
    }
    
    @IBAction func websiteSelected(_ sender: Any) {
        userDefaults.set(websitePopButton.selectedItem?.title, forKey: websiteToken)
        cleanSubjectsCache()
        doCheckQuicklist(parent: self)
    }
    
    @IBAction func showModeSelected(_ sender: Any) {
        let showAll = showAllCheckBox.state == .on
        userDefaults.set(showAll, forKey: defaultShowAllToken)
    }
    
    @IBAction func savePolicySelected(_ sender: Any) {
        let useDefaultPath = sender as? NSButton == useDefaultOption
        ((useDefaultPath) ? askEverytimeOption : useDefaultOption)!.state = .off
        pathTextField.isEditable = useDefaultPath
        browseButton.isEnabled = useDefaultPath
        
        userDefaults.set(useDefaultPath, forKey: useDefualtPathToken)
    }
    
    @IBAction func pathChanged(_ sender: Any) {
        userDefaults.set(pathTextField.stringValue, forKey: defaultPathToken)
    }
    
    @IBAction func browseClicked(_ sender: Any) {
        openPanel.begin { result in
            if result == .OK {
                let path = self.openPanel.url!.path
                self.pathTextField.stringValue = path
                userDefaults.set(path, forKey: defaultPathToken)
            }
        }
    }
    @IBAction func createFolderOptionChanged(_ sender: Any) {
        let createFolder = createFolderCheckBox.state == .on
        userDefaults.set(createFolder, forKey: createFolderToken)
    }
}



class SubjectsSetViewController: NSViewController {
    
    @IBOutlet weak var levelPopButton: NSPopUpButton!
    @IBOutlet weak var subjectProgress: NSProgressIndicator!
    @IBOutlet weak var subjectTable: NSTableView!
    @IBOutlet var promptLabel: NSTextField!
    var prompt: PromptLabelController?
    
    var currentSubjects: [String] = []  // subjects that display in the table
    var selected: [Bool] = []  // indicates whether subject with corresponding index is selected
    var changes: [(String, Bool)] = []  // record all changes made to selection (subject name, change to state)
    var lazySelectedLevel = ""  // remain previous when level button changes, used to update changes
    
    var updateAction: Action? = nil  // action that updates table, will be sent to 'view selected', record here in case having to remove from event later
    
    static var viewCloseEvent = Event()  // multicast when view closes
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up table manipulators
        subjectTable.dataSource = self
        subjectTable.delegate = self
        
        prompt = PromptLabelController(promptLabel)
        
        // append update action to selected subjects view, so that the table can be updated when selected view closes
        updateAction = Action(self.updateTable)
        QuickListViewController.viewCloseEvent.addAction(updateAction!)
    }
    
    override func viewWillDisappear() {
        saveChanges()
        
        // remove to avoid stack
        QuickListViewController.viewCloseEvent.removeAction(updateAction!)
        
        // multicast close event
        SubjectsSetViewController.viewCloseEvent.performAll()
    }
    
    @IBAction func levelSelected(_ sender: Any) {
        saveChanges()
        
        prompt?.setToDefault()
        
        // clear all lists to avoid crash
        currentSubjects.removeAll()
        selected.removeAll()
        subjectTable.reloadData()
        
        if levelPopButton.indexOfSelectedItem == 0 {  // not deal with default choice
            return
        }
        
        lazySelectedLevel = levelPopButton.selectedItem!.title  // update lazy variable
        
        // lock up buttons
        levelPopButton.isEnabled = false
        subjectProgress.startAnimation(nil)
        
        DispatchQueue.global(qos: .userInteractive).async {
            defer {
                // unlock buttons
                DispatchQueue.main.async {
                    self.levelPopButton.isEnabled = true
                    self.subjectProgress.stopAnimation(nil)
                }
            }
            
            // access website to get all subjects
            guard let subjects = website.getSubjects(level: self.lazySelectedLevel) else {
                DispatchQueue.main.async {
                    self.prompt?.showError("Failed to get subjects!")
                }
                
                return
            }
            self.currentSubjects = subjects
            
            DispatchQueue.main.async {
                self.updateTable()
            }
        }
    }
    
    @IBAction func showSelected(_ sender: Any) {  // called when view selected button clicked
        saveChanges()
        
        // fetch and show sub view
        performSegue(withIdentifier: "Show Selected", sender: nil)
    }
    
    func updateTable() {  // updates table view according to quick list
        selected = Array(repeating: false, count: currentSubjects.count)
        for subject in quickList {
            if subject["level"] != lazySelectedLevel || subject["name"]!.hasPrefix("*") {  // exclude other levels
                continue
            }
            
            // find and tick on certain subject
            guard let index = currentSubjects.index(of: subject["name"]!) else {
                continue
            }
            selected[index] = true
        }
        
        subjectTable.reloadData()
    }
    
    func saveChanges() {  // called to save all changes made to table
        for (name, state) in changes {
            if state {  // add subject into list
                quickList.append(["name": name, "level": lazySelectedLevel])
            }
            else {  // find and remove subject from list
                let nameLoc = quickList.firstIndex(where: { $0["name"] == name })!
                quickList.remove(at: nameLoc)
            }
        }
        
        // clear changes list so that they won't be applied twice
        changes.removeAll()
    }
}

extension SubjectsSetViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return currentSubjects.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return selected[row]
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let state = object as? Int == 1  // cast Any to Bool
        selected[row] = state
        changes.append((currentSubjects[row], state))  // record changes
    }
}

extension SubjectsSetViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        if let newCell = tableColumn?.dataCell as? NSButtonCell{  // fetch template cell
            newCell.title = currentSubjects[row]  // get the title from list
            return newCell
        }
        return nil
    }
}



class QuickListViewController: NSViewController {
    
    @IBOutlet weak var quickListTable: NSTableView!
    @IBOutlet weak var upButton: NSButton!
    @IBOutlet weak var downButton: NSButton!
    
    var currentSubjects: [Dictionary<String, String>] = []  // subjects that display in the table
    var selected: [Bool] = []  // indicates whether subject with corresponding index is selected
    
    static var viewCloseEvent = Event()  // multicast when view closes
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up table manipulators
        quickListTable.dataSource = self
        quickListTable.delegate = self
        
        // initialize selected array
        selected = Array(repeating: true, count: quickList.count)
    }
    
    override func viewWillDisappear() {
        for (index, state) in selected.enumerated().reversed() {  // reversed to assure consistance of position
            if !state {  // if ticked off, remove the subject
                quickList.remove(at: index)
            }
        }
        
        // multicast close event
        QuickListViewController.viewCloseEvent.performAll()
    }
    
    func drag(_ from: Int, _ to: Int) {  // swap position of to subjects
        // swap elements in both lists at the same time
        quickList.swapAt(from, to)
        selected.swapAt(from, to)
        
        // refresh table
        quickListTable.reloadData()
        quickListTable.selectRowIndexes(IndexSet(integer: to), byExtendingSelection: false)
    }
    
    @IBAction func dragUp(_ sender: Any) {
        let selectedIndex = quickListTable.selectedRow
        drag(selectedIndex, selectedIndex - 1)
    }
    
    @IBAction func dragDown(_ sender: Any) {
        let selectedIndex = quickListTable.selectedRow
        drag(selectedIndex, selectedIndex + 1)
    }
}

extension QuickListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return quickList.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return selected[row]
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let state = object as! Int == 1  // cast Any to Bool
        selected[row] = state
    }
}

extension QuickListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        if let newCell = tableColumn?.dataCell as? NSButtonCell {  // fetch template cell
            var name = quickList[row]["name"]!
            if name.hasPrefix("*") {
                name.removeFirst()
                name += " (Disabled)"
            }
            newCell.title = name  // get the title from list
            return newCell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selected = quickListTable.selectedRow
        upButton.isEnabled = selected > 0  // can't move up a top subject
        downButton.isEnabled = selected < quickList.count - 1  // con't move down a bottom subject
    }
}
