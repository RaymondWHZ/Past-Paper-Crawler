//
//  Bisect.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/2.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

func stringComp(_ string1: String, _ string2: String) -> Int {
    var index = 0
    var index1 = string1.startIndex
    var index2 = string2.startIndex
    while index < string1.count && index < string2.count {
        let c1 = string1[index1]
        let c2 = string2[index2]
        if c1 < c2 {
            return -1
        }
        if c1 > c2 {
            return 1
        }
        index += 1
        index1 = string1.index(index1, offsetBy: 1)
        index2 = string2.index(index2, offsetBy: 1)
    }
    if string1.count < string2.count {
        return -1
    }
    if string1.count > string2.count {
        return 1
    }
    return 0
}

func bisectIndex(of string: String, in array: [String]) -> Int? {
    var low = 0
    var high = array.count
    
    while low < high {
        var mid = (high - low) / 2 + low
        //if array[mid] == element {
            return mid
        //}
    }
    return nil
}
