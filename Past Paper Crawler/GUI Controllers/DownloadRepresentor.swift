//
//  DownloadRepresentor.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/10/2.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Cocoa

protocol DownloadRepresentor {
    
    var progressIndicator: NSProgressIndicator? { get }
    
    func pre(download files: [WebFile])
    
    func post(download files: [WebFile])
    
    func handle(failed files: [WebFile])
}

extension DownloadRepresentor {
    
    func download(files: [WebFile]) {
        pre(download: files)
        
        // start spinning
        progressIndicator?.startAnimation(nil)
        
        downloadProxy.downloadPapers(specifiedPapers: files, exitAction: {
            failed in
            
            // if all complished (might have another download mission), stop spinning
            if softwareDownloadStack == 0 {
                self.progressIndicator?.stopAnimation(nil)
            }
            
            if !failed.isEmpty {
                self.handle(failed: failed)
            }
            
            defer {
                self.post(download: files)
            }
        })
    }
}
