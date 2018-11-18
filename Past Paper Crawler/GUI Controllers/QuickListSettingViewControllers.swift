//
//  QuickListSettingViewController.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/11/10.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Cocoa

class QuickListViewController: NSViewController {
    
    @IBOutlet weak var levelPopButton: NSPopUpButton!
    @IBOutlet weak var subjectProgress: NSProgressIndicator!
    @IBOutlet weak var subjectTable: NSTableView!
    @IBOutlet var promptLabel: NSTextField!
    var prompt: PromptLabelController?
    
    var currentSubjects: [String] = []  // subjects that display in the table
    var selected: [Bool] = []  // indicates whether subject with corresponding index is selected
    var changes: [(String, Bool)] = []  // record all changes made to selection (subject name, change to state)
    var lazySelectedLevel = ""  // remain previous when level button changes, used to update changes
    
    var refreshAction: Action?
    var refreshEnabled = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up table manipulators
        subjectTable.dataSource = self
        subjectTable.delegate = self
        
        prompt = PromptLabelController(promptLabel)
        
        refreshAction = Action {
            if self.refreshEnabled {
                self.updateTable(reloadData: false)
            }
        }
        quickListChangeEvent.addAction(refreshAction!)
    }
    
    override func viewWillDisappear() {
        quickListChangeEvent.removeAction(refreshAction!)
    }
    
    @IBAction func levelSelected(_ sender: Any) {
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
            guard let subjects = usingWebsite.getSubjects(level: self.lazySelectedLevel) else {
                DispatchQueue.main.async {
                    self.prompt?.showError("Failed to get subjects!")
                }
                
                return
            }
            
            self.currentSubjects = subjects
            self.updateTable()
        }
    }
    
    @IBAction func showSelectedClicked(_ sender: Any) {  // called when view selected button clicked
        // fetch and show sub view
        performSegue(withIdentifier: "Show Selected", sender: nil)
    }
    
    func updateTable(reloadData: Bool = true) {  // updates table view according to quick list
        selected = Array(repeating: false, count: currentSubjects.count)
        for subject in quickList {
            if subject["level"] != lazySelectedLevel || subject["name"]!.hasPrefix("*") {  // exclude other levels
                continue
            }
            
            // find and tick on certain subject
            if let index = currentSubjects.index(of: subject["name"]!) {
                selected[index] = true
            }
        }
        
        if reloadData {
            DispatchQueue.main.async {
                self.subjectTable.reloadData()
            }
        }
    }
}

extension QuickListViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return currentSubjects.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return selected[row]
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let state = object as? Int == 1  // cast Any to Bool
        selected[row] = state
        
        self.refreshEnabled = false  // avoid auto refresh
        
        let name = self.currentSubjects[row]
        
        quickListWriteQueue.async {
            let nameLoc = quickList.firstIndex(where: { $0["name"] == name })
            if state && nameLoc == nil {  // add subject into list when not exist
                quickList.append(["name": name, "level": self.lazySelectedLevel])
            }
            else if nameLoc != nil {  // find and remove subject from list when exist
                quickList.remove(at: nameLoc!)
            }
        }
        
        self.refreshEnabled = true  // avoid auto refresh
    }
}

extension QuickListViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        if row < currentSubjects.count, let newCell = tableColumn?.dataCell as? NSButtonCell {  // fetch template cell
            newCell.title = currentSubjects[row]  // get the title from list
            return newCell
        }
        return nil
    }
}



class SelectedViewController: NSViewController {
    
    @IBOutlet weak var quickListTable: NSTableView!
    @IBOutlet weak var upButton: NSButton!
    @IBOutlet weak var downButton: NSButton!
    
    var currentSubjects: [Dictionary<String, String>] = []  // subjects that display in the table
    var selected: [Bool] = []  // indicates whether subject with corresponding index is selected
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up table manipulators
        quickListTable.dataSource = self
        quickListTable.delegate = self
        
        // initialize selected array
        selected = Array(repeating: true, count: quickList.count)
    }
    
    override func viewWillDisappear() {
        quickListWriteQueue.async {
            for (index, state) in self.selected.enumerated().reversed() {  // reversed to assure consistance of position
                if !state {  // if ticked off, remove the subject
                    quickList.remove(at: index)
                }
            }
        }
    }
    
    func drag(_ from: Int, _ to: Int) {  // swap position of to subjects
        // swap elements in both lists at the same time
        quickListWriteQueue.async {
            quickList.swapAt(from, to)
        }
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

extension SelectedViewController: NSTableViewDataSource {
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

extension SelectedViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        if row < quickList.count, let newCell = tableColumn?.dataCell as? NSButtonCell {  // fetch template cell
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
