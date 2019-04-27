//
//  FailedViewController.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/10/2.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Cocoa

func getFailedView(failedList: [WebFile], retryAction: @escaping ([WebFile]) -> ()) -> NSViewController {
    let view: FailedViewController = getController("Failed View")!
    view.failedList = failedList
    view.retryAction = retryAction
    return view
}

class FailedViewController: NSViewController {
    @IBOutlet var failedTableView: SelectTableView!
    @IBOutlet var retryButton: NSButton!
    
    var failedList: [WebFile] = []
    var retryAction: ([WebFile]) -> () = {_ in}
    
    override func viewDidLoad() {
        failedTableView.defaultSelected = true
        failedTableView.entrys = failedList.map { $0.name }
        
        failedTableView.selectedAction = { row, state in
            if state {
                self.retryButton.isEnabled = true
            }
            else if self.failedTableView.selectedCount == 0 {
                self.retryButton.isEnabled = false
            }
        }
    }
    
    @IBAction func retryClicked(_ sender: Any) {
        dismiss(nil)
        
        // put every file that has a tick into an array
        retryAction(failedList[failedTableView.selectedIndices])
    }
}
