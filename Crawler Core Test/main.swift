//
//  main.swift
//  Crawler Core Test
//
//  Created by 吴浩榛 on 2018/9/3.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

var wholeCoupleList: [FileCouple] = []

let wholeList = website.getPapers(level: "AS & A-Level", subject: "Mathematics (9709)")

let filtered = wholeList.filter { (f) -> Bool in
    let fInfo = info(of: f.name)
    if fInfo["type"] == types["ms"] || fInfo["type"] == types["qp"] {
        return fInfo["year"]?.compare("2004") == ComparisonResult.orderedDescending
    }
    return false
}
let sortedList = filtered.sorted { (f1, f2) -> Bool in
    let f1InfoStr = infoStrWithoutType(file: f1)
    let f2InfoStr = infoStrWithoutType(file: f2)
    return f1InfoStr.compare(f2InfoStr) == ComparisonResult.orderedAscending
}

for e in sortedList {
    print(e.name)
}

var currentPos = 0
let l_list = sortedList.count
while currentPos < l_list {
    
    let currentFile = sortedList[currentPos]
    let cfInfo = info(of: currentFile.name)
    currentPos += 1
    
    let nextFile = sortedList[currentPos]
    
    if cfInfo["type"] == types["qp"] {
        if let fileCouple = FileCouple(qp: currentFile, ms: nextFile) {
            wholeCoupleList.append(fileCouple)
            currentPos += 1
        }
        /*
        else {
            var fastPos = currentPos + 1
            var file = sortedList[fastPos]
            var name = file.name
            var fInfo = info(of: name)
            let typeMS = types["ms"]
            while fInfo["type"] != typeMS {
                file = sortedList[fastPos]
                name = file.name
                fInfo = info(of: name)
                
                fastPos += 1
            }
            wholeCoupleList.append(FileCouple(qp: currentFile, ms: file))
         }
         */
    }
    else {
        /*
        if cfInfo["paper"] == "other..." || cfInfo["paper"] == "None" {
            
        }
        */
        if let fileCouple = FileCouple(qp: nextFile, ms: currentFile) {
            wholeCoupleList.append(fileCouple)
            currentPos += 1
        }
    }
}

for e in wholeCoupleList {
    print(e.description)
}
