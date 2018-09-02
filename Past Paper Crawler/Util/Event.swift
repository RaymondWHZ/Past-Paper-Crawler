//
//  Event.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/2.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

private var actionNum = 0
class Action: Hashable {
    
    let perform: () -> ()
    var hashValue: Int
    
    init(_ subroutine: @escaping () -> ()) {
        perform = subroutine
        
        hashValue = actionNum
        actionNum += 1
    }
    
    static func == (lhs: Action, rhs: Action) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

class Event {  // multicast util
    
    private var actions: [Action] = []
    
    func addAction(_ action: Action) {
        actions.append(action)
    }
    
    func removeAction(_ action: Action) {
        if let actionLoc = actions.index(of: action) {
            actions.remove(at: actionLoc)
        }
    }
    
    func performAll() {
        for action in actions {
            action.perform()
        }
    }
}
