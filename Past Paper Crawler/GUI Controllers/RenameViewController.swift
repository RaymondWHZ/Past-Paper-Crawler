//
//  RenameViewController.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/10/28.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Cocoa

func doCheckQuicklist(parent: NSViewController) {
    let loadingView = getController("Loading List View") as! LoadingListView
    parent.presentAsSheet(loadingView)
    var operations: [(String, String)] = []
    
    DispatchQueue.global(qos: .userInteractive).async {
        guard let subjectLists = subjectLists else {
            loadingView.markFailed()
            return
        }
        
        for (index, subject) in quickList.enumerated() {
            let level = subject["level"]!
            var name = subject["name"]!
            var disabled = false
            if name.hasPrefix("*") {
                name.removeFirst()
                disabled = true
            }
            
            let availableSubjects = subjectLists[level]!
            if availableSubjects.contains(name) {
                if disabled {
                    quickList[index]["name"] = name
                    operations.append((name, "Enabled"))
                }
                continue
            }
            
            let end = name.lastIndex(where: { $0 <= "9" && $0 >= "0"})!
            let start = name.index(end, offsetBy: -3)
            let code = String(name[start...end])
            
            if let finding = findSubject(with: code) {
                quickList[index] = ["level": finding.0, "name": finding.1]
                operations.append((name, "Renamed to " + finding.1))
            }
            else {
                quickList[index]["name"]!.insert("*", at: name.startIndex)
                operations.append((name, "Disabled"))
            }
        }
        
        DispatchQueue.main.async {
            loadingView.dismiss(nil)
            
            if !operations.isEmpty {
                let renameView = getController("Rename View Controller") as! RenameViewController
                renameView.operations = operations
                parent.presentAsSheet(renameView)
                renameView.operationsTableView.reloadData()
            }
        }
    }
    
    
    //Loading List View
    
}

class LoadingListView: NSViewController {
    
    @IBOutlet var progressBar: NSProgressIndicator!
    @IBOutlet var failedLabel: NSTextField!
    
    override func viewDidLoad() {
        progressBar.startAnimation(nil)
    }
    
    func markFailed() {
        failedLabel.isHidden = false
        progressBar.stopAnimation(nil)
    }
}

class SubjectOperation {
    let subjectName: String
    let changeDescription: String
    let changeAction: () -> ()
    
    init(subjectName: String, changeDescription: String, _ changeAction: @escaping () -> ()) {
        self.subjectName = subjectName
        self.changeDescription = changeDescription
        self.changeAction = changeAction
    }
}

class RenameViewController: NSViewController {
    
    private var subject: UnsafeMutablePointer<Dictionary<String, String>>? = nil
    private var newSubject: Dictionary<String, String>? = nil
    @IBOutlet var operationsTableView: NSTableView!
    var operations: [(String, String)] = []
    var selected: [Bool] = []
    
    override func viewDidLoad() {
        operationsTableView.dataSource = self
    }
}

extension RenameViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        let count = operations.count
        selected = Array(repeating: true, count: count)
        return count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableColumn!.title == "Subject name" {
            return operations[row].0
        }
        else {
            return operations[row].1
        }
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let state = object as! Int == 1  // cast Any to Bool
        selected[row] = state
    }
}
