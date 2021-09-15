//
//  IPaFlickrURLResourceUI.swift
//  IPaFlickr
//
//  Created by IPa Chen on 2020/7/11.
//

import UIKit
import IPaURLResourceUI
class IPaFlickrURLResourceUI: IPaURLResourceUI {
    override func generateQueryUrl(_ apiURL:URL,params:[String:Any]?)->URL {
    
        let params = params ?? [String:Any]()
        let baseUrl = apiURL.absoluteString
        var urlString:String
        if IPaFlickr.shared.authorized {
            urlString = IPaFlickr.shared.oauthUrl(from: baseUrl, method: "GET", params: params)
        }
        else {
            urlString = baseUrl + "?" + IPaFlickr.shared.signedQueryString(params)
            
        }
        return URL(string:urlString)!
    }
    override
    public func apiFormDataUploadOperation(_ api:String,method:IPaURLResourceUI.HttpMethod,headerFields:[String:String]?, params:[String:Any]?,files:[IPaMultipartFile],complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestFormDataUploadTaskOperation {
        var newParams = params ?? [String:Any]()
        
        let apiUrl:URL = self.baseUrl.appendingPathComponent(api)
        if IPaFlickr.shared.authorized {
            newParams = IPaFlickr.shared.signedOAuth(apiUrl.absoluteString, method: method.rawValue, params: params)
        }
        else {
            let paramPairs = IPaFlickr.shared.signedArgumentComponent(newParams)
            newParams = paramPairs.reduce([:]) {
                var dict:[String:Any] = $0
                dict[$1.0] = $1.1
                return dict
            }
        }
        return super.apiFormDataUploadOperation(api, method: method, headerFields: nil, params: newParams, files: files, complete: complete)
    }
    override func apiData(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,params:[String:Any]? = nil,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataTaskOperation {
        let method = method.rawValue.uppercased()
        let apiUrl:URL = self.baseUrl.appendingPathComponent(api)
        
        var params = params ?? [String:Any]()
        if IPaFlickr.shared.authorized {
            params = IPaFlickr.shared.signedOAuth(apiUrl.absoluteString, method: method, params: params)
        }
        else {
            _ = IPaFlickr.shared.signed(params, onProcessParam: { (key, value) in
                params[key] = value
                return (key,value)
            }) as [(String,String)]
        }
        
        var request = URLRequest(url: apiUrl)
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
        return self.apiData(with:request,complete:complete)
    }
}
