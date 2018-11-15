//
//  SubjectSystem.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/29.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

/*
 [
 "level": "A-Level",
 "name": "Biology (0610)"
 ]
 */

private func getAllSubjectViewController() -> AllSubjectsViewController {
    return getController("All Subjects View") as! AllSubjectsViewController
}

class SubjectSystem {
    
    let parent: NSViewController
    let selector: NSPopUpButton
    let callback: (String, String) -> ()
    
    let defaultItemNum = 4
    let quickListStartFromIndex = 2
    
    var refreshAction: Action?
    
    init(
        parent: NSViewController,
        selector: NSPopUpButton,
        _ callback: @escaping (String, String) -> ()
        ) {
        self.parent = parent
        self.selector = selector
        self.callback = callback
        
        refresh()
        refreshAction = Action({
            DispatchQueue.main.async {
                self.refresh()
            }
        })
        quickListChangeEvent.addAction(refreshAction!)
    }
    
    deinit {
        quickListChangeEvent.removeAction(refreshAction!)
    }
    
    func selectorClicked() {
        let selectedItem = selector.indexOfSelectedItem
        if selectedItem < 1 {
            return
        }
        
        selector.selectItem(at: 0)
        
        // last item should be 'other...', open selection menu
        if selectedItem == selector.numberOfItems - 1 {
            let controller = getAllSubjectViewController()
            controller.callback = {
                level, subject in
                self.selector.item(at: 0)!.title = subject
                self.callback(level, subject)
            }
            parent.presentAsSheet(controller)
        }
        // otherwise an ordinary item in displayed list is selected
        else {
            let selected = quickList[selectedItem - quickListStartFromIndex]
            selector.item(at: 0)!.title = selected["name"]!
            callback(selected["level"]!, selected["name"]!)
        }
    }
    
    func refresh() {
        // remove original items in the displayed list
        for _ in defaultItemNum..<selector.numberOfItems {
            selector.removeItem(at: quickListStartFromIndex)
        }
        
        // add in new items
        for i in quickList.indices {
            let target = i + quickListStartFromIndex
            var name = quickList[i]["name"]!
            var enabled = true
            if name.hasPrefix("*") {
                name.removeFirst()
                enabled = false
            }
            
            selector.insertItem(withTitle: name, at: target)
            let item = selector.item(at: target)!
            item.isEnabled = enabled
            
            if i + 1 < 10 {
                item.keyEquivalentModifierMask = .command
                item.keyEquivalent = String(i + 1)
            }
        }
    }
}

class AllSubjectsViewController: NSViewController {
    
    @IBOutlet var searchTextField: NSSearchField!
    @IBOutlet var searchProgress: NSProgressIndicator!
    
    @IBOutlet weak var levelPopButton: NSPopUpButton!
    @IBOutlet weak var subjectPopButton: NSPopUpButton!
    var userChangedLevel = false
    
    @IBOutlet weak var levelProgress: NSProgressIndicator!
    @IBOutlet var promptLabel: NSTextField!
    var prompt: PromptLabelController?
    
    @IBOutlet var doneButton: NSButton!
    
    var callback: (String, String) -> () = {
        _, _ in
        fatalError("Didn't assgin end action for subjects view controller")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prompt = PromptLabelController(promptLabel)
    }
    
    @IBAction func levelSelected(_ sender: Any) {
        doneButton.isHidden = true
        
        // clear the prompt
        prompt?.setToDefault()
        
        // remove original items in subject list
        clearSubjectPopButton()
        
        // lock up subject button since the list is either empty or in progress
        subjectPopButton.isEnabled = false
        
        // do not deal with the first item
        if levelPopButton.indexOfSelectedItem == 0 {
            userChangedLevel = false
            return
        }
        
        userChangedLevel = true
        
        // lock up button
        levelPopButton.isEnabled = false
        levelProgress.startAnimation(nil)
        
        // get level name
        let selectedLevel = levelPopButton.selectedItem!.title
        
        DispatchQueue.global(qos: .userInteractive).async {
            defer {
                DispatchQueue.main.async {
                    // unlock buttons
                    self.levelPopButton.isEnabled = true
                    self.subjectPopButton.isEnabled = true
                    self.levelProgress.stopAnimation(nil)
                }
            }
            
            guard let subjects = usingWebsite.getSubjects(level: selectedLevel) else {
                DispatchQueue.main.async {
                    self.prompt?.showError("Failed!")
                }
                
                return
            }
            
            DispatchQueue.main.async {
                // add all items into subject button
                self.subjectPopButton.addItems(withTitles: subjects)
                if !self.currentText.isEmpty, let searchResult = subjects.first(where: { $0.lowercased().contains(self.currentText) }) {
                    self.subjectPopButton.selectItem(withTitle: searchResult)
                    self.doneButton.isHidden = false
                }
            }
        }
    }
    
    func clearSubjectPopButton() {
        let topTitle = subjectPopButton.itemTitle(at: 0)
        subjectPopButton.removeAllItems()
        subjectPopButton.addItem(withTitle: topTitle)
    }
    
    @IBAction func subjectSelected(_ sender: Any) {
        if subjectPopButton.indexOfSelectedItem == 0 {
            doneButton.isHidden = true
            return
        }
        
        let selectedLevel = levelPopButton.selectedItem!.title
        let selectedSubject = subjectPopButton.selectedItem!.title
        self.dismiss(nil)
        self.callback(selectedLevel, selectedSubject)
    }
    
    var currentText = ""
    @IBAction func searchInputted(_ sender: Any) {
        prompt?.setToDefault()
        
        let text = searchTextField.stringValue.lowercased()
        currentText = text
        if text.isEmpty {
            return
        }
        
        if userChangedLevel && levelPopButton.indexOfSelectedItem != 0 && subjectPopButton.isEnabled {
            if let searchResult = subjectPopButton.itemTitles.first(where: { $0.lowercased().contains(text) }) {
                subjectPopButton.selectItem(withTitle: searchResult)
                doneButton.isHidden = false
            }
            else {
                self.prompt?.showError("Failed / Not found!")
            }
            return
        }
        
        searchProgress.startAnimation(nil)
        DispatchQueue.global(qos: .userInteractive).async {
            defer {
                DispatchQueue.main.async {
                    self.searchProgress.stopAnimation(nil)
                }
            }
            
            guard let finding = SubjectUtil.current.findSubject(with: text) else {
                DispatchQueue.main.async {
                    self.prompt?.showError("Failed / Not found!")
                }
                return
            }
            
            if self.currentText == text {
                DispatchQueue.main.async {
                    self.levelPopButton.selectItem(withTitle: finding.0)
                    
                    self.clearSubjectPopButton()
                    self.subjectPopButton.addItems(withTitles: usingWebsite.getSubjects(level: finding.0)!)
                    self.subjectPopButton.isEnabled = true
                    self.subjectPopButton.selectItem(withTitle: finding.1)
                    
                    self.doneButton.isHidden = false
                }
            }
        }
    }
    
    @IBAction func doneClicked(_ sender: Any) {
        subjectSelected(subjectPopButton)
    }
}
