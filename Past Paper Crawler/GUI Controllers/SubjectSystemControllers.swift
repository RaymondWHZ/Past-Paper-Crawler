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

class SubjectSystem {
    
    let parent: NSViewController
    let selector: NSPopUpButton
    let callback: (String, String) -> ()
    
    var defaultItemNum = 4
    var quickListStartFromIndex = 2
    
    init(
        parent: NSViewController,
        selector: NSPopUpButton,
        _ callback: @escaping (String, String) -> ()
        ) {
        self.parent = parent
        self.selector = selector
        self.callback = callback
        
        refresh()
    }
    
    func selectorClicked() {
        guard let selectedItem = selector.selectedItem else {
            return
        }
        
        if selectedItem == selector.lastItem {
            selector.selectItem(at: 0)
            
            let controller = parent.storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "All Subjects View")) as! AllSubjectsViewController
            controller.callback = {
                level, subject in
                self.selector.item(at: 0)!.title = subject
                self.callback(level, subject)
            }
            parent.presentViewControllerAsSheet(controller)
        }
        else if selector.indexOfSelectedItem > 0{
            let selectedIndex = self.selector.indexOfSelectedItem
            DispatchQueue.global().async {
                let selected = quickList[selectedIndex - self.quickListStartFromIndex]
                DispatchQueue.main.async {
                    self.callback(selected["level"]!, selected["name"]!)
                }
            }
        }
    }
    
    func refresh() {
        for _ in 4..<selector.numberOfItems {
            selector.removeItem(at: quickListStartFromIndex)
        }
        for i in 0..<quickList.count {
            selector.insertItem(withTitle: quickList[i]["name"]!, at: i + quickListStartFromIndex)
        }
    }
}

class AllSubjectsViewController: NSViewController {
    
    @IBOutlet weak var levelPopButton: NSPopUpButton!
    @IBOutlet weak var subjectPopButton: NSPopUpButton!
    @IBOutlet weak var subjectProgress: NSProgressIndicator!
    @IBOutlet weak var customProgress: NSProgressIndicator!
    
    var callback: (String, String) -> () = {
        _, _ in
        fatalError("Didn't assgin end action for subjects view controller")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func levelSelected(_ sender: Any) {
        
        let topTitle = subjectPopButton.itemTitle(at: 0)
        subjectPopButton.removeAllItems()
        subjectPopButton.addItem(withTitle: topTitle)
        subjectPopButton.isEnabled = false
        
        if levelPopButton.indexOfSelectedItem == 0 {
            return
        }
        
        levelPopButton.isEnabled = false
        
        let selectedLevel = levelPopButton.selectedItem!.title
        
        subjectProgress.startAnimation(nil)
        
        DispatchQueue.global().async {
            let subjects = website.getSubjects(level: selectedLevel)
            
            DispatchQueue.main.async {
                self.subjectPopButton.addItems(withTitles: subjects)
                
                self.subjectProgress.stopAnimation(nil)
                self.subjectPopButton.isEnabled = true
                
                self.levelPopButton.isEnabled = true
            }
        }
    }
    
    @IBAction func subjectSelected(_ sender: Any) {
        if subjectPopButton.indexOfSelectedItem == 0 {
            return
        }
        
        let selectedLevel = subjectPopButton.selectedItem!.title
        let selectedSubject = subjectPopButton.selectedItem!.title
        self.dismiss(nil)
        self.callback(selectedLevel, selectedSubject)
    }
}
