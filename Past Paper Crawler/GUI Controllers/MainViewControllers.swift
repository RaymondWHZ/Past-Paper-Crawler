//
//  ViewController.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/26.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

let usingSite = PapaCambridge()

class MainViewController: NSViewController {
    
    @IBOutlet weak var subjectPopButton: NSPopUpButton!
    
    var subjectSystem: SubjectSystem?
    
    var refreshAction: Action? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subjectSystem = SubjectSystem(parent: self, selector: subjectPopButton) {
            level, subject in
            
            // usingSite.getPapers(level: level, subject: subject)
            
            // display paper window
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "Show Papers"), sender: nil)
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

class PapersViewController: NSViewController {
    
    @IBOutlet weak var seasonPopButton: NSPopUpButton!
    @IBOutlet weak var showAllCheckbox: NSButton!
    @IBOutlet weak var typePopButton: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func refreshFiles(files: [String]) {
        
    }
    
    @IBAction func changedShowOption(_ sender: Any) {
        
        // refresh pop button
        typePopButton.isHidden = showAllCheckbox.state == .off
    }
    
    @IBAction func seasonSelected(_ sender: Any) {
        
    }
}


