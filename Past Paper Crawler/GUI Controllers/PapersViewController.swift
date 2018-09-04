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
    @IBOutlet weak var seasonPopButton: NSPopUpButton!
    @IBOutlet weak var showAllCheckbox: NSButton!
    @IBOutlet weak var typePopButton: NSPopUpButton!
    
    @IBOutlet weak var papersTable: NSTableView!
    
    var subjectSystem: SubjectSystem?
    
    static var currentSubject: Dictionary<String, String>?
    var currentLevel: String {
        get {
            return PapersViewController.currentSubject!["level"]!
        }
    }
    var currentName: String {
        get {
            return PapersViewController.currentSubject!["name"]!
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
        
        subjectSystem = SubjectSystem(parent: self, selector: subjectPopButton) {
            level, subject in
            // change current subject
            PapersViewController.currentSubject = ["level": level, "name": subject]
            
            self.refreshList()
        }
        
        // refresh for the first time in case static subject had been set
        refreshList()
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
    
    func refreshList() {
        if PapersViewController.currentSubject == nil {
            return
        }
        
        // set selected subject
        subjectPopButton.item(at: 0)!.title = currentName
        subjectPopButton.selectItem(at: 0)
        
        // lock up buttons
        subjectPopButton.isEnabled = false
        papersProgress.startAnimation(nil)
        
        DispatchQueue.global().async {
            showProxy.reloadFrom(level: self.currentLevel, subject: self.currentName)  // access website to get all papers
            
            DispatchQueue.main.async {
                self.updateTable()
                
                // unlock buttons
                self.subjectPopButton.isEnabled = true
                self.papersProgress.stopAnimation(nil)
            }
        }
    }
    
    func updateTable() {  // updates table view according to display list
        selected = Array(repeating: false, count: currentDisplay.count)
        papersTable.reloadData()
    }
}

extension PapersViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return currentDisplay.count
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
