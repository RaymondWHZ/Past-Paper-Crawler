//
//  SelectTableView.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2019/4/19.
//  Copyright © 2019 吴浩榛. All rights reserved.
//

import Cocoa

class SelectTableView: NSTableView, NSTableViewDelegate, NSTableViewDataSource {
    
    private var _selected: [Bool] = []
    var selected: [Bool] {
        return _selected
    }
    
    var selectedCount: Int {
        return _selected.trueCount
    }

    private var settedUp = false
    override func viewDidMoveToWindow() {
        if settedUp { return }
        settedUp = true
        
        delegate = self
        dataSource = self
    }
    
    var defaultSelected = false
    
    //                       row
    var userSelectedAction: (Int) -> () = { _ in }
    var anySelectedAction: () -> () = { }
    var selectionChangedAction: () -> () = { }
    
    private var _entrys: [String] = []
    var entrys: [String] {
        get {
            return _entrys
        }
        set {
            _entrys = newValue
            setAllStates(to: defaultSelected)
        }
    }
    
    var entryCount: Int {
        return entrys.count
    }
    
    func setState(of row: Int, to state: Bool) {
        if _selected[row] == state { return }
        _selected[row] = state
        reloadData()
    }
    
    func setAllStates(to state: Bool) {
        _selected = Array(repeating: state, count: entryCount)
        reloadData()
    }
    
    func swapRows(row1: Int, row2: Int) {
        _entrys.swapAt(row1, row2)
        _selected.swapAt(row1, row2)
        reloadData()
    }
    
    var selectedIndices: [Int] {
        get {
            var indices: [Int] = []
            indices.reserveCapacity(selectedCount)
            for (index, state) in _selected.enumerated() {
                if state {
                    indices.append(index)
                }
            }
            return indices
        }
        set {
            _selected = Array(repeating: false, count: entryCount)
            for index in newValue {
                if index < _selected.count {
                    _selected[index] = true
                }
            }
            reloadData()
        }
    }
    
    var selectAllButton: NSButton? {
        didSet {
            selectAllButton?.setButtonType(.pushOnPushOff)
            selectAllButton?.target = self
            selectAllButton?.action = #selector(selectAllClicked)
        }
    }
    
    @objc func selectAllClicked() {
        if selectAllButton != nil {
            let selectAll = selectAllButton!.state == .on
            undoableChangeAllSelected(to: selectAll)
        }
    }
    
    private func undoableChangeAllSelected(to state: Bool) {
        let newSelected = Array(repeating: state, count: entryCount)
        undoableChangeSelected(to: newSelected)
    }
    
    private func undoableChangeSelected(to states: [Bool]) {
        let lastSelected = _selected
        undoManager?.registerUndo(withTarget: self) { _ in
            self.undoableChangeSelected(to: lastSelected)
        }
        
        _selected = states
        reloadData()
    }
    
    func unduableChangeState(of row: Int, to state: Bool) {
        let lastState = _selected[row]
        undoManager?.registerUndo(withTarget: self) { _ in
            self.unduableChangeState(of: row, to: lastState)
        }
        
        if state == lastState { return }
        _selected[row] = state
        userSelectedAction(row)
        reloadData()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return entryCount
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return _selected[row]
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let state = object as! Int == 1  // cast Any to Bool
        unduableChangeState(of: row, to: state)
    }
    
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        if row < entryCount, let newCell = tableColumn?.dataCell as? NSButtonCell {  // fetch template cell
            newCell.title = entrys[row]  // get the title from list
            return newCell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        selectionChangedAction()
    }
    
    override func reloadData() {
        selectAllButton?.state = (entryCount > 0 && selectedCount == entryCount) ? .on : .off
        anySelectedAction()
        super.reloadData()
    }
}
