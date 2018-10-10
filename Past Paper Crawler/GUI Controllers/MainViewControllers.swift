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
    var paperPrompt: PromptLabelController? = nil
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
    @IBOutlet weak var subjectProgress: NSProgressIndicator!
    @IBOutlet var subjectPromptLabel: NSTextField!
    var subjectPrompt: PromptLabelController? = nil
    
    var subjectSystem: SubjectSystem?
    var nextShowProxy: ShowProxy? = nil
    
    var refreshAction: Action?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        paperComboBox.usesDataSource = true
        paperComboBox.dataSource = self
        paperComboBox.delegate = self
        
        paperPrompt = PromptLabelController(paperPromptLabel)
        subjectPrompt = PromptLabelController(subjectPromptLabel)
        
        subjectSystem = SubjectSystem(parent: self, selector: subjectPopButton) {
            level, subject in
            
            // lock up button
            self.subjectPopButton.isEnabled = false
            self.subjectProgress.startAnimation(nil)
            self.subjectPrompt?.setToDefault()
            
            DispatchQueue.global().async {
                defer {
                    // unlock button
                    DispatchQueue.main.async {
                        self.subjectPopButton.isEnabled = true
                        self.subjectProgress.stopAnimation(nil)
                    }
                }
                
                // load current subject
                PapersViewController.nextProxy = defaultShowProxy
                if !PapersViewController.nextProxy!.loadFrom(level: level, subject: subject) {
                    DispatchQueue.main.async {
                        self.subjectPrompt?.showError("Failed to load subject!")
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    
                    // display paper window
                    self.performSegue(withIdentifier: "Show Papers", sender: nil)
                    
                    // switch back selection
                    self.subjectPopButton.selectItem(at: 0)
                }
            }
        }
        
        // add refresh action to setting panel
        refreshAction = Action(subjectSystem!.refresh)
        SubjectsSetViewController.viewCloseEvent.addAction(refreshAction!)
    }
    
    override func viewWillDisappear() {
        // remove refresh action from setting panel
        SubjectsSetViewController.viewCloseEvent.removeAction(refreshAction!)
    }
    
    @IBAction func paperConfirmed(_ sender: Any) {
        let text = paperComboBox.stringValue
        if let selectedFile = possibleFileList.first(where: { $0.name == text }) {
            paperProcess.startAnimation(nil)
            downloadProxy.downloadPapers(specifiedPapers: [selectedFile], exitAction: {
                failed in
                
                if !failed.isEmpty {
                    self.paperPrompt?.showError("Download failed!")
                }
                
                self.paperProcess.stopAnimation(nil)
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
        DispatchQueue.global().async {
            defer {
                DispatchQueue.main.async {
                    self.accessCount -= 1
                    if self.accessCount != 0 {
                        self.paperProcess.stopAnimation(nil)
                    }
                }
            }
            
            guard let res = findSubject(with: code) else {
                DispatchQueue.main.async {
                    self.reloadFileList(papers: [])
                    self.paperPrompt?.showError("Failed to find subject code!")
                }
                
                return
            }
            
            if self.currentCode != code {
                return
            }
            
            guard let files = website.getPapers(level: res.0, subject: res.1) else {
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
