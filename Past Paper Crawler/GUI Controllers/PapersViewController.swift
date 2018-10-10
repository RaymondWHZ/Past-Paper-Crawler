//
//  PaperViewController.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/2.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

class PapersViewController: NSViewController {
    
    // ---standard controls---
    
    @IBOutlet weak var subjectPopButton: NSPopUpButton!
    @IBOutlet weak var papersProgress: NSProgressIndicator!
    
    @IBOutlet weak var yearPopButton: NSPopUpButton!
    @IBOutlet weak var seasonPopButton: NSPopUpButton!
    @IBOutlet weak var paperPopButton: NSPopUpButton!
    @IBOutlet weak var editionPopButton: NSPopUpButton!
    
    @IBOutlet weak var papersTable: NSTableView!
    @IBOutlet weak var selectAllButton: NSButton!
    
    @IBOutlet var viewPromptLabel: NSTextField!
    var viewPrompt: PromptLabelController?
    @IBOutlet weak var showAllCheckbox: NSButton!
    @IBOutlet weak var typePopButton: NSPopUpButton!
    
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var downloadProgress: NSProgressIndicator!
    
    var allControls: [NSControl] = []
    
    // ---custom variables---
    
    static var nextProxy: ShowProxy? = nil
    var showProxy: ShowProxy = PapersViewController.nextProxy!
    
    var subjectSystem: SubjectSystem?
    var refreshAction: Action?
    
    var selected: [Bool] = []  // indicates whether subject with corresponding index is selected
    
    // ---standard functions---
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        allControls = [
            subjectPopButton,
            
            yearPopButton,
            seasonPopButton,
            paperPopButton,
            editionPopButton,
            
            papersTable,
            selectAllButton,
            
            showAllCheckbox,
            typePopButton,
            
            downloadButton
        ]
        
        // clear next proxy
        PapersViewController.nextProxy = nil
        
        viewPrompt = PromptLabelController(viewPromptLabel)
        
        // set up table manipulators
        papersTable.dataSource = self
        papersTable.delegate = self
        
        // initiate criteria and subject display
        setUpSurrounding()
        
        subjectSystem = SubjectSystem(parent: self, selector: subjectPopButton, loadList)
        
        refreshAction = Action{
            self.subjectSystem!.refresh()
        }
        SubjectsSetViewController.viewCloseEvent.addAction(refreshAction!)
        
    }
    
    override func viewWillDisappear() {
        SubjectsSetViewController.viewCloseEvent.removeAction(refreshAction!)
    }
    
    // ---custom functions---
    
    var controlEnabled: Bool {  // whether to lock up the whole view
        get {
            return allControls.first!.isEnabled
        }
        set {
            for control in allControls {
                control.isEnabled = newValue
            }
        }
    }
    
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
    
    @IBAction func selectAllClicked(_ sender: Any) {
        papersTable.reloadData()  // the table will automatically detect whether it's on
    }
    
    @IBAction func changedShowOption(_ sender: Any) {
        let isOn = showAllCheckbox.state == .on
        
        var newShowProxy = ShowProxy()
        if isOn {
            viewPromptLabel.stringValue = "All files are shown."
        }
        else {
            newShowProxy = PapersWithAnswer()
            viewPromptLabel.stringValue = "Papers and answers are put together omitting any other file or paper before 2005."
        }
        
        // refresh pop button
        typePopButton.isHidden = showAllCheckbox.state == .off
        
        newShowProxy.restoreFrom(other: showProxy)
        showProxy = newShowProxy
        
        papersTable.reloadData()
        setUpSurrounding()
    }
    
    @IBAction func subjectSelected(_ sender: Any) {
        // redirect action
        subjectSystem!.selectorClicked()
    }
    
    @IBAction func criteriaSelected(_ sender: Any) {
        let popButton = sender as! NSPopUpButton
        let name = popButton.identifier!.rawValue
        let index = popButton.indexOfSelectedItem
        if index == 0 {
            showProxy.removeCriterion(name: name)
        }
        else {
            let value = popButton.item(at: index)!.title
            showProxy.setCriterion(name: name, value: value)
        }
        papersTable.reloadData()
    }
    
    @IBAction func downloadClicked(_ sender: Any) {
        // collect all indeices to download
        var selectedIndices: [Int] = []
        for (index, state) in selected.enumerated() {
            if state {
                selectedIndices.append(index)
            }
        }
        
        // start spinning
        downloadProgress.startAnimation(nil)
        
        showProxy.downloadPapers(at: selectedIndices, exitAction: {
            failed in
            
            // if all complished (might have another download mission), stop spinning
            if softwareDownloadStack == 0 {
                self.downloadProgress.stopAnimation(nil)
            }
            
            if !failed.isEmpty {
                self.performSegue(withIdentifier: "Show Failed", sender: nil)
            }
        })
    }
    
    func loadList(level: String, subject: String) {
        viewPrompt?.setToDefault()
        
        // set selected subject
        subjectPopButton.selectItem(at: 0)
        
        // lock up buttons
        controlEnabled = false
        papersProgress.startAnimation(nil)
        
        DispatchQueue.global().async {
            defer {
                // unlock buttons
                DispatchQueue.main.async {
                    self.controlEnabled = true
                    self.papersProgress.stopAnimation(nil)
                }
            }
            
            // access website to get all papers
            if !self.showProxy.loadFrom(level: level, subject: subject) {
                DispatchQueue.main.async {
                    self.viewPrompt?.showError("Failed to load subject!")
                }
                
                return
            }
            
            DispatchQueue.main.async {
                self.papersTable.reloadData()
                self.setUpSurrounding()
            }
        }
    }
    
    func setUpSurrounding() {
        // set up subject selector
        subjectPopButton.itemArray[0].title = currentSubject + " "  // add space to avoid duplication in list
        
        // set up criteria selector
        let summary = showProxy.criteriaSummary  // fetch all selections
        for popButton in [
            yearPopButton,
            seasonPopButton,
            paperPopButton,
            editionPopButton,
            typePopButton
            ] {
                let identifier = popButton!.identifier!.rawValue  // get button identifier
                let selections = Array(summary[identifier]!)  // get list of choice from summary, converting Set to Array
                popButton!.addItems(withTitles: selections)  // push in corresponding list of choice
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
            if row < currentDisplay.count {
                newCell.title = currentDisplay[row]  // get the title from list
                return newCell
            }
        }
        return nil
    }
}
