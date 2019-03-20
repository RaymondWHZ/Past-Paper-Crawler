//
//  DownloadProxy.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/3.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

typealias ADDownloadExitAction = (String, [WebFile]) -> ()

func ADDownload(papers: [WebFile], to path: String? = nil, exitAction: @escaping ADDownloadExitAction) {
    DispatchQueue.global(qos: .userInitiated).async {
        var actualPath = ""
        var failed: [WebFile] = []
        if path == nil {
            var ask = true
            if PFUseDefaultPath {
                var isDir = ObjCBool(false)
                let exists = fileManager.fileExists(atPath: PFDefaultPath, isDirectory: &isDir)
                if exists && isDir.boolValue {
                    ask = false
                    actualPath = PFDefaultPath
                }
            }
            if ask {
                let group = DispatchGroup()
                group.enter()
                DispatchQueue.main.async {
                    directoryOpenPanel.begin { result in
                        DispatchQueue.main.async {
                            defer {
                                group.leave()
                            }
                            if result == .OK, let path = directoryOpenPanel.url?.path {
                                actualPath = path
                            }
                        }
                    }
                }
                group.wait()
            }
        }
        else {
            actualPath = path!
        }
        if !actualPath.isEmpty {
            failed.append(contentsOf: papers.download(to: actualPath, classify: PFCreateFolder, showInFinder: PFOpenInFinder))
        }
        exitAction(actualPath, failed)
    }
}
