//
//  CountArray.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2019/4/20.
//  Copyright © 2019 吴浩榛. All rights reserved.
//

import Foundation

extension Array where Element == Bool {
    
    var trueCount: Int {
        return reduce(into: 0) { if $1 { $0 += 1 } }
    }
}

extension Array {
    
    subscript(indices: [Int]) -> [Element] {
        var subarray: [Element] = []
        subarray.reserveCapacity(indices.count)
        indices.forEach { index in subarray.append(self[index]) }
        return subarray
    }
}

extension ArraySlice where Element == Bool {
    
    var trueCount: Int {
        return reduce(into: 0) { if $1 { $0 += 1 } }
    }
}
