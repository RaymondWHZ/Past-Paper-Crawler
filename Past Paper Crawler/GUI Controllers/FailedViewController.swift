//
//  FailedViewController.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/10/2.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Cocoa

class FailedViewController: NSViewController {
    
    static var nextFailedList: [WebFile]? = nil
    var failedList: [WebFile] = FailedViewController.nextFailedList!
    
    @IBOutlet var failedTableView: NSTableView!
    var selected: [Bool] = []
    
    override func viewDidLoad() {
        FailedViewController.nextFailedList = nil
        
        failedTableView.dataSource = self
        failedTableView.delegate = self
    }
    
    @IBAction func retryClicked(_ sender: Any) {
        dismiss(nil)
        
        var selectedFiles: [WebFile] = []
        for (index, state) in selected.enumerated() {
            if state {
                selectedFiles.append(failedList[index])
            }
        }
        
        
    }
}

extension FailedViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        let number = failedList.count
        selected = Array(repeating: true, count: number)
        return number
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return selected[row]
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let state = object as! Int == 1  // cast Any to Bool
        selected[row] = state
    }
}

extension FailedViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        if let newCell = tableColumn?.dataCell as? NSButtonCell {  // fetch template cell
            newCell.title = failedList[row].name  // get the title from list
            return newCell
        }
        return nil
    }
}
