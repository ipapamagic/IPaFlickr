//
//  IPaFlickr+Helper.swift
//  IPaFlickr
//
//  Created by IPa Chen on 2020/7/10.
//

import UIKit

extension String {
    var queryParams:[String:String] {
        get {
            let paramStrings = self.components(separatedBy: "&")
            var params = [String:String]()
            for param in paramStrings {
                let pairs = param.components(separatedBy: "=")
                guard pairs.count == 2 ,let key = pairs.first,let value = pairs.last  else {
                    continue
                }
                params[key] = value
            }
            return params
        }
    }
}
extension URL {
    var queryParams:[String:String] {
        get {
            return self.query?.queryParams ?? [String:String]()
        }
    }
}
