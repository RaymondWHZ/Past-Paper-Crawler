//
//  main.swift
//  Past Paper Crawler Core Test
//
//  Created by 吴浩榛 on 2019/4/23.
//  Copyright © 2019 吴浩榛. All rights reserved.
//

import Foundation

func getSubjectCode(of subject: String) -> String {
    let end = subject.lastIndex(where: { $0 <= "9" && $0 >= "0"})!
    let start = subject.index(end, offsetBy: -3)
    let code = String(subject[start...end])
    return code
}

cacheArray(array: [WebFile(url: "https://www.baidu.com")], for: "TestKey")
