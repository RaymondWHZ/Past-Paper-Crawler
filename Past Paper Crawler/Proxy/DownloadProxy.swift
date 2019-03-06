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
    
    func downloadPapers(specifiedPapers: [WebFile], exitAction: @escaping ([WebFile]) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            let failed = specifiedPapers.download(to: PFDefaultPath, classify: PFCreateFolder, showInFinder: PFOpenInFinder)
            exitAction(failed)
        }
    }
}

class AskUserProxy: DownloadProxy {
    
    func downloadPapers(specifiedPapers: [WebFile], exitAction: @escaping ([WebFile]) -> ()) {
        directoryOpenPanel.begin { result in
            DispatchQueue.main.async {
                var failed: [WebFile] = []
                if result == .OK, let path = directoryOpenPanel.url?.path {
                    DispatchQueue.global(qos: .userInitiated).sync {
                        failed.append(contentsOf: specifiedPapers.download(to: path, classify: PFCreateFolder, showInFinder: PFOpenInFinder))
                    }
                }
                exitAction(failed)
            }
        }
    }
}
