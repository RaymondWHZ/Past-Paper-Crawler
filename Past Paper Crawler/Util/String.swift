//
//  Substring.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2019/3/12.
//  Copyright © 2019 吴浩榛. All rights reserved.
//

import Foundation

extension String{
    
    subscript(intIndex: Int) -> String {
        let index = self.index(self.startIndex, offsetBy: intIndex)
        return String(self[index])
    }
    
    subscript(range: ClosedRange<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex...endIndex])
    }
}
