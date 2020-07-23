//
//  IPaFlickrURLResourceUI.swift
//  IPaFlickr
//
//  Created by IPa Chen on 2020/7/11.
//

import UIKit
import IPaURLResourceUI
class IPaFlickrURLResourceUI: IPaURLResourceUI {
    
    override func urlString(for getApi:String!, params:[String:Any]?) -> String! {
        let params = params ?? [String:Any]()
        let baseUrl = self.baseURL + getApi
        var urlString:String
        if IPaFlickr.shared.authorized {
            urlString = IPaFlickr.shared.oauthUrl(from: baseUrl, method: "GET", params: params)
        }
        else {
            urlString = baseUrl + "?" + IPaFlickr.shared.signedQueryString(params)
            
        }
        return urlString
    }
    open override func apiUploadOperation(_ api:String,method:String,params:[String:Any],files:[IPaMultipartFile],complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        var newParams = params
        let apiUrl = self.urlString(for: api)
        if IPaFlickr.shared.authorized {
            newParams = IPaFlickr.shared.signedOAuth(apiUrl, method: method, params: params)
        }
        else {
            let paramPairs = IPaFlickr.shared.signedArgumentComponent(params)
            newParams = paramPairs.reduce([:]) {
                var dict:[String:Any] = $0
                dict[$1.0] = $1.1
                return dict
            }
        }
        return super.apiUploadOperation(api, method: method, params: newParams, files: files, complete: complete)
    }
    override func apiPerformOperation(_ api:String,method:String,headerFields:[String:String]? = nil,params:[String:Any]?,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataOperation

    {
        let method = method.uppercased()
        let apiURL = urlString(for: api)
        
        var params = params ?? [String:Any]()
        if IPaFlickr.shared.authorized {
            params = IPaFlickr.shared.signedOAuth(apiURL, method: method, params: params)
        }
        else {
            _ = IPaFlickr.shared.signed(params, onProcessParam: { (key, value) in
                params[key] = value
                return (key,value)
            }) as [(String,String)]
        }
        
        var request = URLRequest(url: URL(string: apiURL)!)
        let valuePairs:[String] = params.map { (key,value) in
            let value = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "\(key)=\(value)"
        }
        let postString = valuePairs.joined(separator: "&")
        request.httpBody = postString.data(using: String.Encoding.utf8, allowLossyConversion: false)
    
        request.httpMethod = method
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        if let fields = headerFields {
            for (key,value) in fields {
                request.setValue(value,forHTTPHeaderField: key)
            }
        }
        return self.apiDataOperation(with:request,complete:complete)
    }
}
