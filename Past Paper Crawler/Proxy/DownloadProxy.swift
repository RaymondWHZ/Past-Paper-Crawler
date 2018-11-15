//
//  DownloadProxy.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/3.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

protocol DownloadProxy {
    func downloadPapers(specifiedPapers: [WebFile], exitAction: @escaping ([WebFile]) -> ())
}

class DefaultPathProxy: DownloadProxy {
    
    func downloadPapers(specifiedPapers: [WebFile], exitAction: @escaping ([WebFile]) -> () = { _ in }) {
        DispatchQueue.global().async {
            let failed = specifiedPapers.download(to: defaultPath, classify: createFolder)
            exitAction(failed)
        }
    }
}

class AskUserProxy: DownloadProxy {
    
    func downloadPapers(specifiedPapers: [WebFile], exitAction: @escaping ([WebFile]) -> () = { _ in }) {
        directoryOpenPanel.begin{ result in
            DispatchQueue.global().async {
                var failed: [WebFile] = []
                if result == .OK {
                    let path = directoryOpenPanel.url!.path
                    failed = specifiedPapers.download(to: defaultPath, classify: createFolder)
                }
                exitAction(failed)
            }
        }
    }
}
