//
//  SubjectSystem.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/29.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

private var quickListStartFromIndex = 2
private var defaultItemNum = 5

class QuickListPopUpButton : NSPopUpButton {
    
    private var parentController: NSViewController?
    
    private var lazySelectedItem: Int = 0
    
    private var _title = ""
    override var title: String {
        get {
            return _title
        }
        set {
            _title = newValue
            updateTitle()
        }
    }
    
    var selectedSubject: Subject? {
        didSet {
            updateTitle()
        }
    }
    
    func discardSelectedSubject() {
        selectedSubject = nil
    }
    
    private func updateTitle() {
        if selectedSubject == nil {
            item(at: 0)!.title = _title + " "
        }
        else {
            item(at: 0)!.title = selectedSubject!.name + " "
        }
    }
    
    private var settedUp = false
    override func viewDidMoveToWindow() {
        if settedUp { return }
        settedUp = true
        
        guard let parent = window?.windowController?.contentViewController else {
            return
        }
        parentController = parent
        
        if numberOfItems == 0 {
            addItem(withTitle: "")
        }
        else {
            _title = super.title
        }
        
        // set up control indices
        quickListStartFromIndex = numberOfItems + 1
        defaultItemNum = numberOfItems + 4
        
        // push back necessary items
        menu!.addItem(NSMenuItem.separator())
        addItem(withTitle: "Setup/Edit quick list...")
        menu!.addItem(NSMenuItem.separator())
        let otherItem = NSMenuItem(title: "Other...", action: nil, keyEquivalent: "f")
        otherItem.keyEquivalentModifierMask = .command
        menu!.addItem(otherItem)
        
        // perform the first refresh and hang he refresh action on observer
        refresh()
        PFObserveQuickListChange(self, selector: #selector(updateData))
    }
    
    deinit {
        PFEndObserve(self)
    }
    
    override func sendAction(_ action: Selector?, to target: Any?) -> Bool {
        let selectedItem = indexOfSelectedItem
        if selectedItem >= quickListStartFromIndex {
            selectItem(at: 0)
            
            // last item should be 'Other...', open selection menu
            if selectedItem == numberOfItems - 1 {
                let controller: AllSubjectsViewController = getController("All Subjects View")!
                controller.callback = {
                    subject in
                    self.selectedSubject = subject
                    self.performConfirmSelection()
                }
                parentController!.presentAsSheet(controller)
            }
            // third last item should be 'Setup...', open quick list setting
            else if selectedItem == numberOfItems - 3 {
                showQuickListSettingWindow()
            }
            // otherwise an ordinary item in displayed list is selected
            else {
                var selected: Subject? = nil
                PFUseQuickList { (quickList) in
                    selected = quickList[selectedItem - quickListStartFromIndex]
                }
                selectedSubject = selected!
            }
        }
        
        return super.sendAction(action, to: target)
    }
    
    func performConfirmSelection() {
        let _ = sendAction(action, to: target)
    }
    
    func refresh() {
        // remove original items in the displayed list
        for _ in defaultItemNum..<numberOfItems {
            removeItem(at: quickListStartFromIndex)
        }
        
        // push in quicklist items
        PFUseQuickList { quickList in
            var index = 0
            for subject in quickList {
                let target = index + quickListStartFromIndex
                
                self.insertItem(withTitle: subject.name, at: target)
                let item = self.item(at: target)!
                item.isEnabled = subject.enabled
                
                index += 1
                if index < 10 {
                    item.keyEquivalentModifierMask = .command
                    item.keyEquivalent = String(index)
                }
            }
        }
    }
    
    @objc func updateData() {
        DispatchQueue.main.async {
            self.refresh()
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
    @IBOutlet var promptLabel: PromptLabel!
    
    @IBOutlet var doneButton: NSButton!
    
    var callback: (Subject) -> () = { _ in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        levelSelected(levelPopButton)
    }
    
    @IBAction func levelSelected(_ sender: Any) {
        doneButton.isHidden = true
        
        // clear the prompt
        promptLabel.setToDefault()
        
        // remove original items in subject list
        subjectPopButton.removeAllItems()
        
        // lock up subject button since the list is either empty or in progress
        subjectPopButton.isEnabled = false
        
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
            
            guard let subjects = PFUsingWebsite.getSubjects(level: selectedLevel) else {
                DispatchQueue.main.async {
                    self.promptLabel.showError("Failed!")
                }
                
                return
            }
            
            DispatchQueue.main.async {
                // add all items into subject button
                self.subjectPopButton.addItems(withTitles: subjects)
                self.doneButton.isHidden = false
                if !self.currentText.isEmpty {
                    if let searchResult = subjects.first(where: { $0.lowercased().contains(self.currentText) }) {
                        self.subjectPopButton.selectItem(withTitle: searchResult)
                    }
                    else {
                        self.promptLabel.showError("Failed / Not found!")
                    }
                }
            }
        }
    }
    
    @IBAction func subjectSelected(_ sender: Any) {
        let selectedLevel = levelPopButton.selectedItem!.title
        let selectedSubject = subjectPopButton.selectedItem!.title
        self.dismiss(nil)
        self.callback(Subject(level: selectedLevel, name: selectedSubject))
    }
    
    var currentText = ""
    @IBAction func searchInputted(_ sender: Any) {
        promptLabel.setToDefault()
        
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
                self.promptLabel.showError("Failed / Not found!")
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
            
            guard let subject = SubjectUtil.current.findSubject(with: text) else {
                DispatchQueue.main.async {
                    self.promptLabel.showError("Failed / Not found!")
                }
                return
            }
            
            if self.currentText == text {
                DispatchQueue.main.async {
                    self.levelPopButton.selectItem(withTitle: subject.level)
                    
                    self.subjectPopButton.removeAllItems()
                    self.subjectPopButton.addItems(withTitles: PFUsingWebsite.getSubjects(level: subject.level)!)
                    self.subjectPopButton.isEnabled = true
                    self.subjectPopButton.selectItem(withTitle: subject.name)
                    
                    self.doneButton.isHidden = false
                }
            }
        }
    }
    
    @IBAction func doneClicked(_ sender: Any) {
        subjectSelected(subjectPopButton)
    }
}
