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
    
    @IBOutlet weak var papersTable: SelectTableView!
    @IBOutlet weak var selectAllButton: NSButton!
    
    var lazyCriteriaIndices: [String : Int] = [:]
    
    @IBOutlet var viewPromptLabel: PromptLabel!
    @IBOutlet var selectModePopButton: NSPopUpButton!
    @IBOutlet weak var typePopButton: NSPopUpButton!
    
    var lazySelectModeIndex: Int = -1
    
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var downloadProgress: NSProgressIndicator!
    @IBOutlet var downloadPromptLabel: PromptLabel!
    
    lazy var allControls: [NSControl] = {
        return [
            subjectPopButton,
            
            yearPopButton,
            seasonPopButton,
            paperPopButton,
            editionPopButton,
            
            papersTable,
            selectAllButton,
            
            selectModePopButton,
            typePopButton
        ]
    }()
    
    lazy var criteriaPopButtons: [NSPopUpButton] = {
        return [
            yearPopButton,
            seasonPopButton,
            paperPopButton,
            editionPopButton,
            typePopButton
        ]
    }()
    
    var windowTitle: String? {
        get {
            return view.window?.title
        }
        set {
            view.window?.title = newValue ?? ""
        }
    }
    
    // ---custom variables---
    
    private var showManager = ADShowManager()
    
    // ---standard functions---
    
    func updateTable() {
        papersTable.entrys = showManager.currentShowList
    }
    
    var fileCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up table manipulators
        papersTable.selectAllButton = selectAllButton
        papersTable.selectedAction = { _, _ in
            self.updateDownloadControls()
        }
        
        selectModePopButton.selectItem(at: PFDefaultShowAll ? 1 : 0)
        changedSelectOption(selectModePopButton)
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
    
    // quick accesse to showManager
    var criteriaSummary: ADCriteriaSummary?
    
    @IBAction func changedSelectOption(_ sender: Any) {
        let selectedIndex = selectModePopButton.indexOfSelectedItem
        let lastIndex = lazySelectModeIndex
        changeSelectOption(to: selectedIndex, lastIndex: lastIndex)
    }
    
    func changeSelectOption(to index: Int, lastIndex: Int) {
        if index == lastIndex { return }
        
        if lastIndex != -1 {
            let lastSelected = papersTable.selectedIndices
            undoManager?.registerUndo(withTarget: self) { _ in
                self.selectModePopButton.selectItem(at: lastIndex)
                self.changeSelectOption(to: lastIndex, lastIndex: index)
                self.papersTable.selectedIndices = lastSelected
            }
        }
        
        if index == 0 {
            typePopButton.isHidden = true
            papersTable.tableColumns.first?.title = "Papers (with answer)"
            viewPromptLabel.defaultText = "Papers and answers are put together omitting any other file or paper before 2005."
            showManager.showAll = false
        }
        else {
            typePopButton.isHidden = false
            papersTable.tableColumns.first?.title = "Files"
            viewPromptLabel.defaultText = "All files are shown."
            showManager.showAll = true
        }
        
        viewPromptLabel.setToDefault()
        updateTable()
        
        lazySelectModeIndex = index
    }
    
    @IBAction func subjectSelected(_ sender: Any) {
        if let subject = subjectPopButton.selectedSubject {
            load(subject: subject)
        }
    }
    
    func defaultUpdateAfterLoadingSubject() {
        guard let subject = showManager.currentSubject else {
            return
        }
        
        // remove all previous criteria
        setCriteriaPopButtons(summary: showManager.criteriaSummary)
        
        // auto switch to show all when no couple found
        if showManager.currentShowList.count == 0 {
            if !showManager.showAll {
                DispatchQueue.main.async {
                    self.selectModePopButton.selectItem(at: 1)
                    self.changeSelectOption(to: 1, lastIndex: -1)
                }
            }
            return
        }
        
        // reset selection
        updateTable()
        
        // set up title
        windowTitle = subject.name
    }
    
    func rawLoad(subject: Subject) -> Bool {
        return showManager.loadFrom(subject: subject)
    }
    
    func load(subject: Subject) {
        if subject == showManager.currentSubject { return }
        load(subject: subject) {
            DispatchQueue.main.async(execute: self.defaultUpdateAfterLoadingSubject)
        }
    }
    
    func backLoad(subject: Subject, lastSelected: [Int], lastCriteria: ADCriteria, lastSelectMode: Int) {
        if subject == showManager.currentSubject { return }
        load(subject: subject) {
            DispatchQueue.main.async {
                self.showManager.criteria = lastCriteria
                self.setCriteriaPopButtons(summary: self.showManager.criteriaSummary, criteria: lastCriteria)
                self.selectModePopButton.selectItem(at: lastSelectMode)
                self.updateTable()
                self.papersTable.selectedIndices = lastSelected
            }
        }
    }
    
    func load(subject: Subject, callback: @escaping () -> ()) {
        let lastSubject = showManager.currentSubject
        if subject == lastSubject {
            callback()
            return
        }
        
        let lastSelected = papersTable.selectedIndices
        let lastCriteria = showManager.criteria
        let lastSelectMode = selectModePopButton.indexOfSelectedItem
        
        var undone = false
        undoManager?.registerUndo(withTarget: self) { _ in
            undone = true
            self.backLoad(subject: lastSubject!, lastSelected: lastSelected, lastCriteria: lastCriteria, lastSelectMode: lastSelectMode)
        }
        
        self.subjectPopButton.selectedSubject = subject
        
        viewPromptLabel.setToDefault()
        
        // lock up buttons
        controlEnabled = false
        downloadButton.isEnabled = false
        downloadPromptLabel.isHidden = true
        papersProgress.startAnimation(nil)
        
        DispatchQueue.global(qos: .userInteractive).async {
            defer {
                // unlock buttons
                DispatchQueue.main.async {
                    self.controlEnabled = true
                    self.papersProgress.stopAnimation(nil)
                    self.updateDownloadControls()
                }
            }
            
            // access website to get all papers
            if !self.rawLoad(subject: subject) {
                DispatchQueue.main.async {
                    self.viewPromptLabel.showError("Failed to load subject!")
                }
                
                return
            }
            
            if undone { return }
            callback()
        }
    }
    
    @IBAction func criterionSelected(_ sender: Any) {
        let popButton = sender as! NSPopUpButton
        let name = popButton.identifier!.rawValue
        let index = popButton.indexOfSelectedItem
        let lastIndex = lazyCriteriaIndices[name] ?? 0
        
        if index == lastIndex { return }
        
        updateCriterion(for: popButton, lastIndex: lastIndex)
    }
    
    func updateCriterion(for popButton: NSPopUpButton, lastIndex: Int) {
        let name = popButton.identifier!.rawValue
        let index = popButton.indexOfSelectedItem
        let lastSelected = papersTable.selectedIndices
        
        undoManager?.registerUndo(withTarget: self, handler: { _ in
            popButton.selectItem(at: lastIndex)
            self.updateCriterion(for: popButton, lastIndex: index)
            self.papersTable.selectedIndices = lastSelected
        })
        
        if index == 0 {
            showManager.criteria.removeValue(forKey: name)
        }
        else {
            let value = popButton.item(at: index)!.title
            showManager.criteria[name] = value
        }
        updateTable()
        
        lazyCriteriaIndices[name] = index
    }
    
    func setCriteriaPopButtons(summary: ADCriteriaSummary? = nil, criteria: ADCriteria? = nil) {
        if summary != nil {
            criteriaPopButtons.forEach { popButton in
                let identifier = popButton.identifier!.rawValue  // get button identifier
                let selections = Array(summary![identifier]!)  // get list of choice from summary, converting Set to Array
                while popButton.numberOfItems > 1 { popButton.removeItem(at: 1) }  // remove original items
                popButton.addItems(withTitles: selections)  // push in corresponding list of choice
            }
            criteriaSummary = summary  // fetch all selections
        }
        
        if criteria != nil {
            criteriaPopButtons.forEach { popButton in
                let identifier = popButton.identifier!.rawValue
                if let value = criteria![identifier] {
                    popButton.selectItem(withTitle: value)
                }
            }
            showManager.criteria = criteria!
        }
    }
    
    let tooMuchFileAlert: NSAlert = {
        let alert = NSAlert()
        alert.messageText = "Number of selected files is too large, which may result in long download period. Would you like to continue?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Continue")
        return alert
    }()
    
    let cancelRespond = NSApplication.ModalResponse.alertFirstButtonReturn
    
    @IBAction func downloadClicked(_ sender: Any) {
        if fileCount > 20 {
            let respond = tooMuchFileAlert.runModal()
            if respond == cancelRespond {
                return
            }
        }
        
        // collect all indeices to download
        download(papers: showManager.getSelectedPapers(at: papersTable.selectedIndices))
    }
    
    func download(papers: [WebFile], to path: String? = nil) {
        // start spinning
        downloadProgress?.startAnimation(nil)
        downloadButton.isEnabled = false
        downloadPromptLabel.showPrompt("Downloading...")
        
        ADDownload(papers: papers, to: path) {
            path, failed in
            DispatchQueue.main.async {
                self.downloadProgress?.stopAnimation(nil)
                self.downloadButton.isEnabled = true
                
                // if any failed, show the failed view
                if !failed.isEmpty {
                    self.downloadPromptLabel.showError("Download Failed!")
                    self.presentAsSheet(
                        getFailedView(failedList: failed, retryAction: {
                            self.download(papers: $0, to: path)
                        })
                    )
                }
                else {
                    self.downloadPromptLabel.showPrompt("Download Succeed!")
                }
            }
        }
    }
    
    func updateDownloadControls() {
        let selectedCount = papersTable.selectedCount
        if selectedCount == 0 {
            fileCount = 0
            downloadPromptLabel.setToDefault()
            downloadButton.isEnabled = false
        }
        else {
            fileCount = (selectModePopButton.indexOfSelectedItem == 0) ? selectedCount * 2 : selectedCount
            downloadPromptLabel.showPrompt("\(fileCount) File(s)")
            downloadButton.isEnabled = true
        }
    }
}
