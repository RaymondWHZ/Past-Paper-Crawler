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

private let allSubjectViewController = getController("All Subjects View") as! AllSubjectsViewController

class SubjectSystem {
    
    let parent: NSViewController
    let selector: NSPopUpButton
    let callback: (String, String) -> ()
    
    let defaultItemNum = 4
    let quickListStartFromIndex = 2
    
    var refreshAction: Action? = nil
    
    init(
        parent: NSViewController,
        selector: NSPopUpButton,
        _ callback: @escaping (String, String) -> ()
        ) {
        self.parent = parent
        self.selector = selector
        self.callback = callback
        
        selector.autoenablesItems = false
        
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
            allSubjectViewController.callback = {
                level, subject in
                self.selector.item(at: 0)!.title = subject
                self.callback(level, subject)
            }
            parent.presentAsSheet(allSubjectViewController)
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
            selector.item(at: target)!.isEnabled = enabled
        }
    }
}

class AllSubjectsViewController: NSViewController {
    
    @IBOutlet weak var levelPopButton: NSPopUpButton!
    @IBOutlet weak var subjectPopButton: NSPopUpButton!
    @IBOutlet weak var subjectProgress: NSProgressIndicator!
    @IBOutlet weak var customProgress: NSProgressIndicator!
    @IBOutlet var promptLabel: NSTextField!
    var prompt: PromptLabelController?
    
    var callback: (String, String) -> () = {
        _, _ in
        fatalError("Didn't assgin end action for subjects view controller")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prompt = PromptLabelController(promptLabel)
    }
    
    @IBAction func levelSelected(_ sender: Any) {
        // clear the prompt
        prompt?.setToDefault()
        
        // remove original items in subject list
        let topTitle = subjectPopButton.itemTitle(at: 0)
        subjectPopButton.removeAllItems()
        subjectPopButton.addItem(withTitle: topTitle)
        
        // lock up subject button since the list is either empty or in progress
        subjectPopButton.isEnabled = false
        
        // do not deal with the first item
        if levelPopButton.indexOfSelectedItem == 0 {
            return
        }
        
        // lock up button
        levelPopButton.isEnabled = false
        subjectProgress.startAnimation(nil)
        
        // get level name
        let selectedLevel = levelPopButton.selectedItem!.title
        
        DispatchQueue.global(qos: .userInteractive).async {
            defer {
                DispatchQueue.main.async {
                    // unlock buttons
                    self.levelPopButton.isEnabled = true
                    self.subjectPopButton.isEnabled = true
                    self.subjectProgress.stopAnimation(nil)
                }
            }
            
            guard let subjects = website.getSubjects(level: selectedLevel) else {
                DispatchQueue.main.async {
                    self.prompt?.showError("Failed to get subjects!")
                }
                
                return
            }
            
            DispatchQueue.main.async {
                // add all items into subject button
                self.subjectPopButton.addItems(withTitles: subjects)
            }
        }
    }
    
    @IBAction func subjectSelected(_ sender: Any) {
        if subjectPopButton.indexOfSelectedItem == 0 {
            return
        }
        
        let selectedLevel = levelPopButton.selectedItem!.title
        let selectedSubject = subjectPopButton.selectedItem!.title
        self.dismiss(nil)
        self.callback(selectedLevel, selectedSubject)
    }
}
