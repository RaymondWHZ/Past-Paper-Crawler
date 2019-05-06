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
    @IBOutlet weak var subjectTable: SelectTableView!
    @IBOutlet var promptLabel: PromptLabel!
    
    var refreshEnabled = true
    let modifyQueue = DispatchQueue(label: "Quick List Modify Protect (All)")
    
    func modifyOn(action: @escaping () -> ()) {
        modifyQueue.sync {  // async to maximize performance
            self.refreshEnabled = false
            action()
            self.refreshEnabled = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up table manipulators
        subjectTable.userSelectedAction = { row in
            let name = self.subjectTable.entrys[row]
            
            var lastQuicklist: QuickList?
            
            self.modifyOn {
                PFModifyQuickList { quickList in
                    let nameLoc = quickList.firstIndex(where: { $0.name == name })
                    if self.subjectTable.selected[row] {  // add subject into list when not exist
                        if nameLoc == nil {
                            lastQuicklist = quickList
                            quickList.append(Subject(level: self.lazySelectedLevel, name: name))
                        }
                    }
                    else {
                        if nameLoc != nil {  // find and remove subject from list when exist
                            lastQuicklist = quickList
                            quickList.remove(at: nameLoc!)
                        }
                    }
                }
            }
            
            if lastQuicklist != nil {
                self.undoManager?.registerUndo(withTarget: self) { _ in
                    PFModifyQuickList { $0 = lastQuicklist! }
                }
            }
        }
    }
    
    override func viewDidAppear() {
        levelSelected(levelPopButton!)
        
        PFObserveQuickListChange(self, selector: #selector(quickListChanged))
    }
    
    override func viewWillDisappear() {
        PFEndObserve(self)
    }
    
    var lazySelectedLevel = ""  // remain previous when level button changes, used to update changes
    @IBAction func levelSelected(_ sender: Any) {
        let lastSelectedLevel = lazySelectedLevel
        var undone = false
        undoManager?.registerUndo(withTarget: self) { _ in
            undone = true
            self.levelPopButton.selectItem(withTitle: lastSelectedLevel)
            self.levelSelected(self.levelPopButton!)
        }
        
        promptLabel.setToDefault()
        
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
                    self.promptLabel.showError("Failed to get subjects!")
                }
                
                return
            }
            
            if undone { return }
            
            DispatchQueue.main.async {
                self.subjectTable.entrys = subjects
                self.tickSubjects()
            }
        }
    }
    
    func tickSubjects() {
        subjectTable.selectedIndices = []
        let entrys = subjectTable.entrys
        PFUseQuickList { quickList in
            for subject in quickList {
                if subject.level != lazySelectedLevel || !subject.enabled {  // exclude other levels or disabled ones
                    continue
                }
                
                // find and tick on certain subject
                if let index = entrys.firstIndex(of: subject.name) {
                    subjectTable.setState(of: index, to: true)
                }
            }
        }
    }
    
    @objc func quickListChanged() {
        if refreshEnabled {
            DispatchQueue.main.async {
                self.tickSubjects()
            }
        }
    }
    
    @IBAction func showSelectedClicked(_ sender: Any) {  // called when view selected button clicked
        // fetch and show sub view
        performSegue(withIdentifier: "Show Selected", sender: nil)
    }
}



class SelectedViewController: NSViewController {
    
    @IBOutlet weak var quickListTable: SelectTableView!
    @IBOutlet weak var upButton: NSButton!
    @IBOutlet weak var downButton: NSButton!
    
    var currentSubjects: [Dictionary<String, String>] = []  // subjects that display in the table
    var subjects: [Subject] = []  // cache the subjects
    var selected: [Bool] = []  // indicates whether subject with corresponding index is selected
    
    var refreshEnabled = true
    let modifyQueue = DispatchQueue(label: "Quick List Modify Protect (Selected)")
    
    func modifyOn(action: @escaping () -> ()) {
        modifyQueue.async {  // async to maximize performance
            self.refreshEnabled = false
            action()
            self.refreshEnabled = true
        }
    }
    
    func rowInQuickListOf(rowInSubject: Int) -> Int {
        return quickListTable.selected[0..<rowInSubject].trueCount
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        quickListTable.defaultSelected = true
        
        PFUseQuickList { self.subjects = $0 }
        reloadQuickListTable()
        
        // set up table manipulators
        quickListTable.userSelectedAction = { row in
            self.modifyOn {  // performance measure: subthread update
                PFModifyQuickList { quickList in
                    let position = self.rowInQuickListOf(rowInSubject: row)
                    if self.quickListTable.selected[row] {
                        quickList.insert(self.subjects[row], at: position)
                    }
                    else {
                        quickList.remove(at: position)
                    }
                }
            }
        }
        
        quickListTable.selectionChangedAction = {
            let selectedRow = self.quickListTable.selectedRow
            self.upButton.isEnabled = selectedRow > 0  // can't move up a top subject
            self.downButton.isEnabled = selectedRow < self.quickListTable.entryCount - 1  // con't move down a bottom subject
        }
        
        PFObserveQuickListChange(self, selector: #selector(updateData))
    }
    
    override func viewDidDisappear() {
        PFEndObserve(self)
    }
    
    func reloadQuickListTable() {
        quickListTable.entrys = subjects.map { $0.name }
    }
    
    func drag(_ row1: Int, _ row2: Int) {  // swap position of to subjects
        undoManager?.registerUndo(withTarget: self) { _ in
            self.drag(row2, row1)
        }
        
        modifyOn {
            // swap elements in both lists at the same time
            if self.quickListTable.selected[row1] && self.quickListTable.selected[row2] {
                PFModifyQuickList { quicklist in
                    let index1 = self.rowInQuickListOf(rowInSubject: row1)
                    let index2 = self.rowInQuickListOf(rowInSubject: row2)
                    quicklist.swapAt(index1, index2)
                }
            }
            
            self.subjects.swapAt(row1, row2)
            
            DispatchQueue.main.async {
                self.quickListTable.swapRows(row1: row1, row2: row2)
                self.quickListTable.selectRowIndexes(IndexSet(integer: row2), byExtendingSelection: false)
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
                self.reloadQuickListTable()
            }
        }
    }
}
