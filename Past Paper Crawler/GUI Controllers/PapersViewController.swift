//
//  PaperViewController.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/2.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

class PapersViewController: NSViewController, DownloadRepresentor {
    
    var progressIndicator: NSProgressIndicator?
    
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
    
    var showProxy: ShowProxy = defaultShowProxy
    
    var subjectSystem: SubjectSystem?
    var refreshAction: Action?
    
    var selected: [Bool] = []  // indicates whether subject with corresponding index is selected
    
    // ---standard functions---
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressIndicator = downloadProgress
        
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
        
        // initiate prompt
        viewPrompt = PromptLabelController(viewPromptLabel)
        
        // set up table manipulators
        papersTable.dataSource = self
        papersTable.delegate = self
        
        // set up subject system
        subjectSystem = SubjectSystem(parent: self, selector: subjectPopButton, loadList)
        
        if userDefaults.bool(forKey: defaultShowAllToken) {
            showAllCheckbox.state = .on
            changedShowOption(showAllCheckbox)
        }
    }
    
    // ---custom functions---
    
    private var controlEnabled: Bool {  // whether to lock up the whole view
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
        typePopButton.isHidden = !isOn
        
        let newShowProxy = (isOn) ? ShowProxy() : PapersWithAnswer()
        viewPromptLabel.stringValue = (isOn) ? "All files are shown." : "Papers and answers are put together omitting any other file or paper before 2005."
        
        newShowProxy.restoreFrom(other: showProxy)
        showProxy = newShowProxy
        
        papersTable.reloadData()
        resetCriteria()
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
        
        let papers = showProxy.getPapers(at: selectedIndices)
        download(files: papers)
    }
    
    func pre(download files: [WebFile]) { }
    
    func handle(failed files: [WebFile]) {
        self.presentAsSheet(getFailedView(failedList: files, retryAction: self.download))
    }
    
    func post(download files: [WebFile]) { }
    
    func loadList(level: String, subject: String) {
        // set back prompt line
        viewPrompt?.setToDefault()
        
        // lock up buttons
        controlEnabled = false
        papersProgress.startAnimation(nil)
        
        // select item
        subjectPopButton.selectItem(at: 0)
        subjectPopButton.item(at: 0)!.title = subject + " "
        
        DispatchQueue.global(qos: .userInteractive).async {
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
        if papersTable.numberOfRows == 0 {
            if showProxy is PapersWithAnswer {
                DispatchQueue.main.async {
                    self.showAllCheckbox.state = .on
                    self.changedShowOption(self.showAllCheckbox)
                }
            }
            return
        }
        
        // set up subject selector
        subjectPopButton.itemArray[0].title = currentSubject + " "  // add space to avoid duplication in list
        
        resetCriteria()
    }
    
    func resetCriteria() {
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
