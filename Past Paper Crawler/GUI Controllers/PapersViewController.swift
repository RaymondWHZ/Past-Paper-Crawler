//
//  PaperViewController.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/2.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

class PapersViewController: NSViewController {
    
    @IBOutlet weak var subjectPopButton: NSPopUpButton!
    @IBOutlet weak var papersProgress: NSProgressIndicator!
    
    @IBOutlet weak var yearPopButton: NSPopUpButton!
    @IBOutlet weak var seasonPopButton: NSPopUpButton!
    @IBOutlet weak var paperPopButton: NSPopUpButton!
    @IBOutlet weak var editionPopButton: NSPopUpButton!
    
    @IBOutlet weak var papersTable: NSTableView!
    @IBOutlet weak var selectAllButton: NSButton!
    
    @IBOutlet weak var showAllCheckbox: NSButton!
    @IBOutlet weak var typePopButton: NSPopUpButton!
    
    @IBOutlet weak var downloadButton: NSButton!
    
    var operationEnabled: Bool {
        get {
            return subjectPopButton.isEnabled
        }
        set {
            let b = newValue
            
            subjectPopButton.isEnabled = b
            
            yearPopButton.isEnabled = b
            seasonPopButton.isEnabled = b
            paperPopButton.isEnabled = b
            editionPopButton.isEnabled = b
            
            papersTable.isEnabled = b
            selectAllButton.isEnabled = b
            
            showAllCheckbox.isEnabled = b
            typePopButton.isEnabled = b
            
            downloadButton.isEnabled = b
        }
    }
    
    var subjectSystem: SubjectSystem?
    var refreshAction: Action?
    
    // quick accesses to showProxy
    var currentLevel: String {
        get {
            return showProxy.currentLevel
        }
    }
    var currentSubject: String {
        get {
            return showProxy.currentSubject
        }
    }
    var currentDisplay: [String] {
        get {
            return showProxy.currentShowList
        }
    }
    
    var selected: [Bool] = []  // indicates whether subject with corresponding index is selected
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up table manipulators
        papersTable.dataSource = self
        papersTable.delegate = self
        
        subjectSystem = SubjectSystem(parent: self, selector: subjectPopButton, loadList)
        
        refreshAction = Action{
            self.subjectSystem!.refresh()
        }
        SubjectsSetViewController.viewCloseEvent.addAction(refreshAction!)
        
        subjectPopButton.item(at: 0)!.title = currentSubject
    }
    
    override func viewWillDisappear() {
        SubjectsSetViewController.viewCloseEvent.removeAction(refreshAction!)
    }
    
    @IBAction func selectAllClicked(_ sender: Any) {
        papersTable.reloadData()
    }
    
    @IBAction func changedShowOption(_ sender: Any) {
        // refresh pop button
        typePopButton.isHidden = showAllCheckbox.state == .off
    }
    
    @IBAction func subjectSelected(_ sender: Any) {
        subjectSystem!.selectorClicked()
    }
    
    @IBAction func downloadClicked(_ sender: Any) {
        var selectedIndices: [Int] = []
        for (index, state) in selected.enumerated() {
            if state {
                selectedIndices.append(index)
            }
        }
        showProxy.downloadPapers(at: selectedIndices)
    }
    
    func loadList(level: String, subject: String) {
        // set selected subject
        subjectPopButton.item(at: 0)!.title = subject
        subjectPopButton.selectItem(at: 0)
        
        // lock up buttons
        operationEnabled = false
        papersProgress.startAnimation(nil)
        
        DispatchQueue.global().async {
            showProxy.loadFrom(level: level, subject: subject)  // access website to get all papers
            
            DispatchQueue.main.async {
                self.papersTable.reloadData()
                
                // unlock buttons
                self.operationEnabled = true
                self.papersProgress.stopAnimation(nil)
            }
        }
    }
}

extension PapersViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        let number = currentDisplay.count
        selected = Array(repeating: selectAllButton.state == .on, count: number)
        return number
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return selected[row]
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let state = object as! Int == 1  // cast Any to Bool
        selected[row] = state
    }
}

extension PapersViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        if let newCell = tableColumn?.dataCell as? NSButtonCell {  // fetch template cell
            newCell.title = currentDisplay[row]  // get the title from list
            return newCell
        }
        return nil
    }
}
