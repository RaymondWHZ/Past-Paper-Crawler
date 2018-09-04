//
//  ViewController.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/26.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    
    @IBOutlet weak var subjectPopButton: NSPopUpButton!
    
    var subjectSystem: SubjectSystem?
    
    var refreshAction: Action? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subjectSystem = SubjectSystem(parent: self, selector: subjectPopButton) {
            level, subject in
            // load current subject
            PapersViewController.currentSubject = ["level": level, "name": subject]
            
            // display paper window
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "Show Papers"), sender: nil)
            
            // switch back selection
            self.subjectPopButton.selectItem(at: 0)
        }
        
        refreshAction = Action{
            self.subjectSystem!.refresh()
        }
        SubjectsSetViewController.viewCloseEvent.addAction(refreshAction!)
    }
    
    override func viewWillDisappear() {
        SubjectsSetViewController.viewCloseEvent.removeAction(refreshAction!)
    }
    
    @IBAction func subjectSelected(_ sender: Any) { subjectSystem!.selectorClicked() }
}


