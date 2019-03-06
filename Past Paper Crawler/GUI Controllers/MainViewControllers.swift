//
//  ViewController.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/26.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    
    @IBOutlet var paperComboBox: NSComboBox!
    @IBOutlet var paperDownloadButton: NSButton!
    @IBOutlet var paperProcess: NSProgressIndicator!
    @IBOutlet var paperPromptLabel: NSTextField!
    var paperPrompt: PromptLabelController?
    var _possiblePaperList: [WebFile] = []
    var possibleFileList: [WebFile] {
        get {
            return _possiblePaperList
        }
        set {
            _possiblePaperList = newValue
            paperComboBox.reloadData()
            paperDownloadButton.isHidden = newValue.isEmpty
        }
    }
    var currentCode = ""
    var accessCount = 0
    
    @IBOutlet weak var subjectPopButton: NSPopUpButton!
    var defaultPopButtonPrompt = ""
    @IBOutlet weak var subjectProgress: NSProgressIndicator!
    @IBOutlet var subjectPromptLabel: NSTextField!
    var subjectPrompt: PromptLabelController?
    
    var subjectSystem: SubjectSystem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        paperComboBox.usesDataSource = true
        paperComboBox.dataSource = self
        paperComboBox.delegate = self
        
        paperPrompt = PromptLabelController(paperPromptLabel)
        subjectPrompt = PromptLabelController(subjectPromptLabel)
        
        defaultPopButtonPrompt = subjectPopButton.item(at: 0)!.title
        subjectSystem = SubjectSystem(parent: self, selector: subjectPopButton) {
            level, subject in
            
            // lock up button
            self.subjectPopButton.isEnabled = false
            self.subjectProgress.startAnimation(nil)
            self.subjectPrompt?.setToDefault()
            
            let paperWindow: NSWindowController = getController("Papers Window")!
            let paperView = paperWindow.contentViewController as! PapersViewController
            
            DispatchQueue.global(qos: .userInteractive).async {
                defer {
                    // unlock button
                    DispatchQueue.main.async {
                        self.subjectPopButton.isEnabled = true
                        self.subjectProgress.stopAnimation(nil)
                    }
                }
                
                // load current subject
                if !paperView.showProxy.loadFrom(level: level, subject: subject) {
                    DispatchQueue.main.async {
                        self.subjectPrompt?.showError("Failed to load subject!")
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    
                    // display paper window
                    paperView.papersTable.reloadData()
                    paperView.setUpSurrounding()
                    paperWindow.showWindow(nil)
                    
                    // set back prompt
                    self.subjectPopButton.item(at: 0)!.title = self.defaultPopButtonPrompt
                }
            }
        }
    }
    
    @IBAction func paperConfirmed(_ sender: Any) {
        let text = paperComboBox.stringValue
        if let selectedFile = possibleFileList.first(where: { $0.name == text }) {
            paperProcess.startAnimation(nil)
            PFDownloadProxy.downloadPapers(specifiedPapers: [selectedFile], exitAction: {
                failed in
                DispatchQueue.main.async {
                    if !failed.isEmpty {
                        self.paperPrompt?.showError("Download failed!")
                    }
                    
                    self.paperProcess.stopAnimation(nil)
                }
            })
        }
        else {
            if !text.isEmpty {
                paperPrompt?.showError("Paper not found!")
            }
            return
        }
    }
    
    @IBAction func subjectSelected(_ sender: Any) { subjectSystem!.selectorClicked() }
}

extension MainViewController: NSComboBoxDelegate {
    
    func accessSubject(code: String) {
        if code == currentCode {
            return
        }
        currentCode = code
        
        paperPrompt?.showPrompt("Loading subject...")
        paperProcess.startAnimation(nil)
        
        accessCount += 1
        DispatchQueue.global(qos: .userInteractive).async {
            defer {
                DispatchQueue.main.async {
                    self.accessCount -= 1
                    if self.accessCount == 0 {
                        self.paperProcess.stopAnimation(nil)
                    }
                }
            }
            
            guard let subject = SubjectUtil.current.findSubject(with: code) else {
                DispatchQueue.main.async {
                    self.reloadFileList(papers: [])
                    self.paperPrompt?.showError("Failed to find subject code!")
                }
                
                return
            }
            
            if self.currentCode != code {
                return
            }
            
            guard let files = PFUsingWebsite.getPapers(level: subject.level, subject: subject.name) else {
                DispatchQueue.main.async {
                    self.reloadFileList(papers: [])
                    self.paperPrompt?.showError("Failed to get paper list!")
                }
                
                return
            }
            
            if self.currentCode != code {
                return
            }
            
            DispatchQueue.main.async {
                self.reloadFileList(papers: files)
                self.paperPrompt?.setToDefault()
            }
        }
    }
    
    func reloadFileList(papers: [WebFile]) {
        possibleFileList = papers
        paperComboBox.reloadData()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        
        let text = paperComboBox.stringValue
        let count = text.count
        
        if count < 4 {
            if count == 0 {
                paperPrompt?.setToDefault()
            }
            else {
                paperPrompt?.showError("Subject code incomplete!")
            }
            reloadFileList(papers: [])
            currentCode = ""
            paperProcess.stopAnimation(nil)
            
            return
        }
        
        // cut first 4 characters
        let startIndex = text.startIndex
        let sepIndex = text.index(startIndex, offsetBy: 4)
        let subjectCode = String(text[..<sepIndex])
        
        // load subject
        accessSubject(code: subjectCode)
    }
}

extension MainViewController: NSComboBoxDataSource {
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return possibleFileList.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return possibleFileList[index].name
    }
}
