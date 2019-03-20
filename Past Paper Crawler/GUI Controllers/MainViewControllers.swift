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
        if quickOpPerformButton.isHidden { return }
        quickOpPerformButton.isHidden = true
        let text = quickOpComboBox.stringValue
        if quickOpMode == .Subject {
            subjectPopButton.performConfirmSelection()
        }
        else if let selectedPaper = quickOpPossiblePapers.first(where: { $0.name == text }) {
            quickOpDownload(paper: selectedPaper)
        }
    }
    
    func quickOpDownload(paper: WebFile, to path: String? = nil) {
        quickOpProcess.startAnimation(nil)
        quickOpPromptLabel.setToDefault()
        ADDownload(papers: [paper], to: path) {
            path, failed in
            DispatchQueue.main.async {
                if !failed.isEmpty {
                    self.quickOpPromptLabel.showError("Download failed!")
                    self.quickOpRetryAction = {
                        self.quickOpDownload(paper: paper, to: path)
                    }
                }
                self.quickOpProcess.stopAnimation(nil)
            }
        }
    }
    
    func subjectOpen(subject: Subject) {
        subjectPromptLabel.setToDefault()
        
        // lock up button
        subjectPopButton.isEnabled = false
        subjectProgress.startAnimation(nil)
        
        let paperWindow: NSWindowController = getController("Papers Window")!
        let paperView = paperWindow.contentViewController as! PapersViewController
        
        DispatchQueue.global(qos: .userInteractive).async {
            defer {
                // unlock button
                DispatchQueue.main.async {
                    self.subjectPopButton.isEnabled = true
                    self.subjectPopButton.discardSelectedSubject()
                    self.subjectProgress.stopAnimation(nil)
                }
            }
            
            // load current subject
            if !paperView.showManager.loadFrom(subject: subject) {
                DispatchQueue.main.async {
                    self.subjectPromptLabel.showError("Failed to load subject!")
                }
                return
            }
            
            DispatchQueue.main.async {
                
                // display paper window
                paperView.papersTable.reloadData()
                paperView.resetSurrounding()
                paperWindow.showWindow(nil)
                
                // set back prompt
                self.subjectPopButton.item(at: 0)!.title = self.defaultPopButtonPrompt
            }
        }
    }
    
    @IBAction func retryClicked(_ sender: Any) {
        quickOpRetryButton.isHidden = true
        quickOpRetryAction()
    }
    
    @IBAction func subjectClicked(_ sender: Any) {
        quickOpPerformButton.isHidden = true
        
        if let subject = subjectPopButton.selectedSubject {
            subjectOpen(subject: subject)
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
        
        subjectPopButtonOperationQueue.sync {
            let lowercasedText = text.lowercased()
            var found = false
            for index in 2..<2+PFQuickListCount {
                if let item = subjectPopButton.item(at: index), item.title.lowercased().hasPrefix(lowercasedText) {
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
            quickOpProcess.stopAnimation(nil)
            return
        }
        
        let code = text[0...3]
        
        if code == currentCode {
            quickOpPromptLabel.setToDefault()
            return
        }
        currentCode = code
        
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
                }
                
                return
            }
            
            if self.currentCode != code {
                return
            }
            
            DispatchQueue.main.async {
                self.quickOpPossiblePapers = files
                self.quickOpPromptLabel.setToDefault()
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
