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
    
    @IBOutlet var subjectPopButton: QuickListPopUpButton!
    @IBOutlet weak var papersProgress: NSProgressIndicator!
    
    @IBOutlet weak var yearPopButton: NSPopUpButton!
    @IBOutlet weak var seasonPopButton: NSPopUpButton!
    @IBOutlet weak var paperPopButton: NSPopUpButton!
    @IBOutlet weak var editionPopButton: NSPopUpButton!
    
    @IBOutlet weak var papersTable: NSTableView!
    @IBOutlet weak var selectAllButton: NSButton!
    
    @IBOutlet var viewPromptLabel: PromptLabel!
    @IBOutlet weak var showAllCheckbox: NSButton!
    @IBOutlet weak var typePopButton: NSPopUpButton!
    
    @IBOutlet var downloadCountLabel: PromptLabel!
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var downloadProgress: NSProgressIndicator!
    
    var allControls: [NSControl] = []
    
    // ---custom variables---
    
    var showManager = ADShowManager()
    
    var selected: [Bool] = [] {  // indicates whether subject with corresponding index is selected
        didSet {
            let selectedCount = selected.reduce(into: 0) { if $1 { $0 += 1 } }
            if selectedCount == 0 {
                selectAllButton.state = .off
                downloadCountLabel.setToDefault()
                downloadButton.isEnabled = false
            }
            else {
                selectAllButton.state = (selectedCount == selected.count) ? .on : .off
                let fileCount = (showAllCheckbox.state == .on) ? selectedCount : selectedCount * 2
                downloadCountLabel.showPrompt("Selected \(fileCount) files")
                downloadButton.isEnabled = true
            }
        }
    }
    
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
            typePopButton
        ]
        
        // set up table manipulators
        papersTable.dataSource = self
        papersTable.delegate = self
        
        if PFDefaultShowAll {
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
            return showManager.currentLevel
        }
    }
    var currentSubject: String {
        get {
            return showManager.currentSubject
        }
    }
    var currentDisplay: [String] {
        get {
            return showManager.currentShowList
        }
    }
    
    @IBAction func selectAllClicked(_ sender: Any) {
        papersTable.reloadData()  // the table will automatically detect whether it's on
    }
    
    @IBAction func changedShowOption(_ sender: Any) {
        let isOn = showAllCheckbox.state == .on
        typePopButton.isHidden = !isOn
        
        viewPromptLabel.defaultText = (isOn) ? "All files are shown." : "Papers and answers are put together omitting any other file or paper before 2005."
        
        showManager.showAll = isOn
        selectAllButton.state = .off
        papersTable.reloadData()
    }
    
    @IBAction func subjectSelected(_ sender: Any) {
        guard let subject = subjectPopButton.selectedSubject else {
            return
        }
        
        viewPromptLabel.setToDefault()
        
        // lock up buttons
        controlEnabled = false
        downloadButton.isEnabled = false
        papersProgress.startAnimation(nil)
        
        // select item
        subjectPopButton.selectItem(at: 0)
        subjectPopButton.item(at: 0)!.title = subject.name + " "
        
        DispatchQueue.global(qos: .userInteractive).async {
            defer {
                // unlock buttons
                DispatchQueue.main.async {
                    self.controlEnabled = true
                    self.papersProgress.stopAnimation(nil)
                }
            }
            
            // access website to get all papers
            if !self.showManager.loadFrom(subject: subject) {
                DispatchQueue.main.async {
                    self.viewPromptLabel.showError("Failed to load subject!")
                }
                
                return
            }
            
            DispatchQueue.main.async {
                self.selectAllButton.state = .off
                self.papersTable.reloadData()
                self.resetSurrounding()
            }
        }
    }
    
    @IBAction func criteriaSelected(_ sender: Any) {
        let popButton = sender as! NSPopUpButton
        let name = popButton.identifier!.rawValue
        let index = popButton.indexOfSelectedItem
        if index == 0 {
            showManager.removeCriterion(name: name)
        }
        else {
            let value = popButton.item(at: index)!.title
            showManager.setCriterion(name: name, value: value)
        }
        papersTable.reloadData()
    }
    
    func resetSurrounding() {  // only called when new subject selected
        // set up title
        view.window?.title = currentSubject
        
        // set up subject selector
        subjectPopButton.itemArray[0].title = currentSubject + " "  // add space to avoid duplication in list
        
        if papersTable.numberOfRows == 0 {
            if !showManager.showAll {  // auto switch to show all when no couple found
                DispatchQueue.main.async {
                    self.showAllCheckbox.state = .on
                    self.changedShowOption(self.showAllCheckbox)
                }
            }
            return
        }
        
        // remove all previous criteria
        resetCriteria()
    }
    
    func resetCriteria() {
        // set up criteria selector
        let summary = showManager.criteriaSummary  // fetch all selections
        for popButton in [
            yearPopButton,
            seasonPopButton,
            paperPopButton,
            editionPopButton,
            typePopButton
            ] {
                let identifier = popButton!.identifier!.rawValue  // get button identifier
                let selections = Array(summary[identifier]!)  // get list of choice from summary, converting Set to Array
                while popButton!.numberOfItems > 1 { popButton!.removeItem(at: 1) }  // remove original items
                popButton!.addItems(withTitles: selections)  // push in corresponding list of choice
        }
    }
    
    @IBAction func downloadClicked(_ sender: Any) {
        // collect all indeices to download
        var selectedIndices: [Int] = []
        for (index, state) in selected.enumerated() {
            if state {
                selectedIndices.append(index)
            }
        }
        
        download(papers: showManager.getSelectedPapers(at: selectedIndices))
    }
    
    func download(papers: [WebFile], to path: String? = nil) {
        // start spinning
        downloadProgress?.startAnimation(nil)
        
        ADDownload(papers: papers, to: path) {
            path, failed in
            DispatchQueue.main.async {
                // if all complished (might have another download mission), stop spinning
                if webFileDownloadStack == 0 {
                    self.downloadProgress?.stopAnimation(nil)
                }
                
                // if any failed, show the failed view
                if !failed.isEmpty {
                    self.presentAsSheet(
                        getFailedView(failedList: failed, retryAction: {
                            self.download(papers: $0, to: path)
                        })
                    )
                }
            }
        }
    }
}

extension PapersViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        let count = currentDisplay.count
        let selectAll = selectAllButton.state == .on
        selected = Array(repeating: selectAll, count: count)
        return count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if row < selected.count {
            return selected[row]
        }
        return false
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let state = object as! Int == 1  // cast Any to Bool
        selected[row] = state
    }
}

extension PapersViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        if row < currentDisplay.count, let newCell = tableColumn?.dataCell as? NSButtonCell {  // fetch template cell
            newCell.title = currentDisplay[row]  // get the title from list
            return newCell
        }
        return nil
    }
}
