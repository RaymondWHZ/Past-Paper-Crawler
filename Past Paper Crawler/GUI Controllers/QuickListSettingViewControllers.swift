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
    
    var refreshEnabled = true
    let modifyQueue = DispatchQueue(label: "Quick List Modify Protect (All)")
    
    func modifyOn(action: @escaping () -> ()) {
        modifyQueue.async {
            self.refreshEnabled = false
            action()
            self.refreshEnabled = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up table manipulators
        subjectTable.dataSource = self
        subjectTable.delegate = self
        
        prompt = PromptLabelController(promptLabel)
        
        PFObserveQuickListChange(self, selector: #selector(updateData))
    }
    
    override func viewWillDisappear() {
        PFEndObserve(self)
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
            guard let subjects = PFUsingWebsite.getSubjects(level: self.lazySelectedLevel) else {
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
        PFUseQuickList { quickList in
            for subject in quickList {
                if subject.level != lazySelectedLevel || !subject.enabled {  // exclude other levels or disabled ones
                    continue
                }
                
                // find and tick on certain subject
                if let index = currentSubjects.index(of: subject.name) {
                    selected[index] = true
                }
            }
        }
        
        if reloadData {
            DispatchQueue.main.async {
                self.subjectTable.reloadData()
            }
        }
    }
    
    @objc func updateData() {
        if refreshEnabled {
            updateTable(reloadData: false)
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
        
        let name = self.currentSubjects[row]
        
        modifyOn {
            PFModifyQuickList { quickList in
                let nameLoc = quickList.firstIndex(where: { $0.name == name })
                if state && nameLoc == nil {  // add subject into list when not exist
                    quickList.append(Subject(level: self.lazySelectedLevel, name: name))
                }
                else if nameLoc != nil {  // find and remove subject from list when exist
                    quickList.remove(at: nameLoc!)
                }
            }
        }
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
    var subjects: [Subject] = []  // cache the subjects
    var selected: [Bool] = []  // indicates whether subject with corresponding index is selected
    
    var refreshEnabled = true
    let modifyQueue = DispatchQueue(label: "Quick List Modify Protect (Selected)")
    
    func modifyOn(action: @escaping () -> ()) {
        modifyQueue.async {
            self.refreshEnabled = false
            action()
            self.refreshEnabled = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PFUseQuickList { self.subjects = $0 }
        selected = Array(repeating: true, count: subjects.count)
        
        // set up table manipulators
        quickListTable.dataSource = self
        quickListTable.delegate = self
        
        PFObserveQuickListChange(self, selector: #selector(updateData))
    }
    
    override func viewDidDisappear() {
        PFEndObserve(self)
    }
    
    func drag(_ from: Int, _ to: Int) {  // swap position of to subjects
        modifyOn {
            // swap elements in both lists at the same time
            if self.selected[from] && self.selected[to] {
                PFModifyQuickList { $0.swapAt(from, to) }
            }
            self.subjects.swapAt(from, to)
            self.selected.swapAt(from, to)
            
            DispatchQueue.main.sync {
                // refresh table
                self.quickListTable.reloadData()
                self.quickListTable.selectRowIndexes(IndexSet(integer: to), byExtendingSelection: false)
            }
        }
    }
    
    @IBAction func dragUp(_ sender: Any) {
        let selectedIndex = quickListTable.selectedRow
        drag(selectedIndex, selectedIndex - 1)
    }
    
    @IBAction func dragDown(_ sender: Any) {
        let selectedIndex = quickListTable.selectedRow
        drag(selectedIndex, selectedIndex + 1)
    }
    
    @objc func updateData() {  // reload everything if any exotic change takes place
        if refreshEnabled {
            PFUseQuickList { self.subjects = $0 }
            DispatchQueue.main.async {
                self.quickListTable.reloadData()
            }
        }
    }
}

extension SelectedViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return subjects.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return selected[row]
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let state = object as! Int == 1  // cast Any to Bool
        selected[row] = state
        modifyOn {  // performance measure: subthread update
            PFModifyQuickList { quickList in
                if state {
                    let position = self.selected[0..<row].reduce(into: 0, { $0 += $1 ? 1 : 0 })
                    quickList.insert(self.subjects[row], at: position)
                }
                else {
                    quickList.remove(at: row)
                }
            }
        }
    }
}

extension SelectedViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        if row < subjects.count, let newCell = tableColumn?.dataCell as? NSButtonCell {  // fetch template cell
            newCell.title = subjects[row].name  // get the title from list
            return newCell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selected = quickListTable.selectedRow
        upButton.isEnabled = selected > 0  // can't move up a top subject
        downButton.isEnabled = selected < subjects.count - 1  // con't move down a bottom subject
    }
}
