//
//  ViewController.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/26.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    
    @IBOutlet var quickOpComboBox: NSComboBox!
    @IBOutlet var quickOpPerformButton: NSButton!
    @IBOutlet var quickOpProcess: NSProgressIndicator!
    @IBOutlet var quickOpPromptLabel: PromptLabel!
    @IBOutlet var quickOpRetryButton: NSButton!
    var quickOpRetryAction: () -> () = {} {
        didSet {
            quickOpRetryButton.isHidden = false
        }
    }
    var quickOpPossiblePapers: [WebFile] = [] {
        didSet {
            quickOpComboBox.reloadData()
        }
    }
    var currentCode = ""
    var currentSubjectPrompt = ""
    var accessCount = 0
    
    @IBOutlet var subjectPopButton: QuickListPopUpButton!
    let subjectPopButtonOperationQueue = DispatchQueue(label: "Subject Pop Button Protect")
    var defaultPopButtonPrompt = ""
    @IBOutlet weak var subjectProgress: NSProgressIndicator!
    @IBOutlet var subjectPromptLabel: PromptLabel!
    
    enum Mode {
        case Subject
        case Paper
    }
    var quickOpMode: Mode = .Paper {
        willSet {
            if newValue != quickOpMode {
                if newValue == .Subject {
                    quickOpPerformButton.title = "open sub"
                }
                else {
                    quickOpPerformButton.title = "download"
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        quickOpComboBox.usesDataSource = true
        quickOpComboBox.dataSource = self
        quickOpComboBox.delegate = self
        
        quickOpMode = .Subject
    }
    
    @IBAction func operationConfirmed(_ sender: Any) {
        let text = quickOpComboBox.stringValue
        if quickOpMode == .Subject {
            if !quickOpPerformButton.isHidden {
                subjectPopButton.performConfirmSelection()
            }
        }
        else if let selectedPaper = quickOpPossiblePapers.first(where: { $0.name == text }) {
            quickOpDownload(paper: selectedPaper)
        }
    }
    
    func quickOpDownload(paper: WebFile, to path: String? = nil) {
        quickOpProcess.startAnimation(nil)
        quickOpPromptLabel.showPrompt("Downloading...")
        quickOpComboBox.isEnabled = false
        quickOpPerformButton.isEnabled = false
        ADDownload(papers: [paper], to: path) {
            path, failed in
            DispatchQueue.main.async {
                if !failed.isEmpty {
                    self.quickOpPromptLabel.showError("Failed!")
                    self.quickOpRetryAction = {
                        self.quickOpDownload(paper: paper, to: path)
                    }
                }
                else {
                    self.quickOpPromptLabel.showPrompt("Succeed!")
                }
                self.quickOpProcess.stopAnimation(nil)
                self.quickOpComboBox.isEnabled = true
                self.quickOpPerformButton.isEnabled = true
            }
        }
    }
    
    @IBAction func retryClicked(_ sender: Any) {
        quickOpRetryButton.isHidden = true
        quickOpRetryAction()  // fire action
    }
    
    func startLoadingSubject() {
        // lock up button
        quickOpComboBox.isEnabled = false
        quickOpPerformButton.isEnabled = false
        subjectPopButton.isEnabled = false
        subjectProgress.startAnimation(nil)
    }
    
    func endLoadingSubject() {
        
    }
    
    var _subjactLoading: Bool = false
    var subjectLoading: Bool {
        get {
            return _subjactLoading
        }
        set {
            _subjactLoading = newValue
            if newValue {
                // lock up button
                quickOpComboBox.isEnabled = false
                quickOpPerformButton.isEnabled = false
                subjectPopButton.isEnabled = false
                subjectProgress.startAnimation(nil)
            }
            else {
                quickOpComboBox.isEnabled = true
                quickOpPerformButton.isEnabled = true
                subjectPopButton.isEnabled = true
                subjectProgress.stopAnimation(nil)
            }
        }
    }
    
    @IBAction func subjectSelected(_ sender: Any) {
        if let subject = subjectPopButton.selectedSubject {
            var undone = false
            undoManager?.registerUndo(withTarget: subjectPopButton) { _ in
                undone = true
                self.subjectLoading = false
            }
            
            subjectPromptLabel.setToDefault()
            
            subjectLoading = true
            
            let paperWindow: NSWindowController = getController("Papers Window")!
            let paperView = paperWindow.contentViewController as! PapersViewController
            
            DispatchQueue.global(qos: .userInteractive).async {
                defer {
                    DispatchQueue.main.async {
                        self.subjectLoading = false
                        self.undoManager?.removeAllActions()
                    }
                }
                
                // load current subject
                if !paperView.rawLoad(subject: subject) {
                    DispatchQueue.main.async {
                        self.subjectPromptLabel.showError("Failed to load subject!")
                    }
                    return
                }
                
                if undone { return }
                
                DispatchQueue.main.async {
                    // display paper window
                    paperView.subjectPopButton.selectedSubject = subject
                    paperView.defaultUpdateAfterLoadingSubject()
                    paperWindow.showWindow(nil)
                    
                    // set back prompt
                    self.subjectPopButton.discardSelectedSubject()
                    self.quickOpPerformButton.isHidden = true
                }
            }
        }
    }
}

extension MainViewController: NSComboBoxDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        quickOpRetryButton.isHidden = true
        
        let text = quickOpComboBox.stringValue
        
        if text.isEmpty {
            quickOpPromptLabel.setToDefault()
            return
        }
        
        if text[0] < "0" || text[0] > "9" {
            findSubject()
        }
        else {
            loadPapers()
        }
    }
    
    func findSubject() {
        quickOpMode = .Subject
        quickOpPromptLabel.setToDefault()
        quickOpPossiblePapers = []
        
        let text = quickOpComboBox.stringValue
        
        subjectPopButtonOperationQueue.sync {  // find subject from quick list
            let lowercasedText = text.lowercased()
            var found = false
            for index in 2..<2+PFQuickListCount {
                if let item = subjectPopButton.item(at: index), item.isEnabled && item.title.lowercased().hasPrefix(lowercasedText) {
                    DispatchQueue.main.async {
                        self.subjectPopButton.select(item)
                        self.quickOpMode = .Subject
                        self.quickOpPerformButton.isHidden = false
                    }
                    found = true
                    break
                }
            }
            if !found {
                quickOpPerformButton.isHidden = true
            }
        }
    }
    
    func loadPapers() {
        quickOpMode = .Paper
        
        let text = quickOpComboBox.stringValue
        
        quickOpPerformButton.isHidden = !quickOpPossiblePapers.contains(where: { $0.name == text })
        
        let count = text.count
        if count < 4 {
            quickOpPossiblePapers = []
            if count > 0 {
                quickOpPromptLabel.showError("Subject code incomplete!")
            }
            currentCode = ""
            currentSubjectPrompt = ""
            quickOpProcess.stopAnimation(nil)
            return
        }
        
        let code = text[0...3]
        if code != currentCode {
            currentCode = code
            loadSubject(code: code)
        }
        else if !currentSubjectPrompt.isEmpty {
            quickOpPromptLabel.showPrompt(currentSubjectPrompt)
        }
    }
    
    func loadSubject(code: String) {
        quickOpPromptLabel.showPrompt("Loading subject...")
        quickOpProcess.startAnimation(nil)
        
        accessCount += 1
        DispatchQueue.global(qos: .userInteractive).async {
            defer {
                DispatchQueue.main.async {
                    self.accessCount -= 1
                    if self.accessCount == 0 {
                        self.quickOpProcess.stopAnimation(nil)
                    }
                }
            }
            
            guard let subject = SubjectUtil.current.findSubject(with: code) else {
                DispatchQueue.main.async {
                    self.quickOpPossiblePapers = []
                    self.quickOpPromptLabel.showError("Failed to find subject code!")
                    self.quickOpRetryAction = {
                        self.loadSubject(code: code)
                    }
                }
                
                return
            }
            
            if self.currentCode != code {
                return
            }
            
            guard let files = PFUsingWebsite.getPapers(level: subject.level, subject: subject.name) else {
                DispatchQueue.main.async {
                    self.quickOpPossiblePapers = []
                    self.quickOpPromptLabel.showError("Failed to get paper list!")
                    self.quickOpRetryAction = {
                        self.loadSubject(code: code)
                    }
                }
                
                return
            }
            
            if self.currentCode != code {
                return
            }
            
            DispatchQueue.main.async {
                self.quickOpPossiblePapers = files
                self.currentSubjectPrompt = "Subject: \(subject.name)"
                self.quickOpPromptLabel.showPrompt(self.currentSubjectPrompt)
            }
        }
    }
}

extension MainViewController: NSComboBoxDataSource {
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return quickOpPossiblePapers.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return quickOpPossiblePapers[index].name
    }
}
