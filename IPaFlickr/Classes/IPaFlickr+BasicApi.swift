//
//  IPaFlickr+BasicApi.swift
//  IPaFlickr
//
//  Created by IPa Chen on 2020/7/19.
//

import UIKit
import IPaURLResourceUI
extension IPaFlickr {
    open func apiFlickrGet(_ api:String,params:[String:Any],complete:@escaping IPaURLResourceUIResultHandler) {
        var params = params
        params["method"] = api
        params["format"] = "json"
        params["nojsoncallback"] = "1"
        _ = self.resourceUI.apiGet("rest", params: params, complete: complete)
    }
    open func apiFlickrUpload(_ image:Data,params:[String:Any],complete:@escaping IPaURLResourceUIResultHandler) {
        var params = params
        params["title"] = "photo"

        let file = IPaMultipartFile(name: "photo", mime: "image/jpeg", fileName: "photo.jpg", fileData: image)
        _ = self.upResourceUI.apiUpload("upload", method: "POST",headerFields: nil, params: params, file: file, complete: complete)
        
        
    }
}
