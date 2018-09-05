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
    @IBOutlet weak var papersProgress: NSProgressIndicator!
    
    var subjectSystem: SubjectSystem?
    
    var refreshAction: Action?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subjectSystem = SubjectSystem(parent: self, selector: subjectPopButton) {
            level, subject in
            // lock up button
            self.subjectPopButton.isEnabled = false
            self.papersProgress.startAnimation(nil)
            
            DispatchQueue.global().async {
                // load current subject
                showProxy.loadFrom(level: level, subject: subject)
                
                DispatchQueue.main.async {
                    // display paper window
                    self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "Show Papers"), sender: nil)
                    
                    // switch back selection
                    self.subjectPopButton.selectItem(at: 0)
                    
                    // unlock button
                    self.subjectPopButton.isEnabled = true
                    self.papersProgress.stopAnimation(nil)
                }
            }
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


