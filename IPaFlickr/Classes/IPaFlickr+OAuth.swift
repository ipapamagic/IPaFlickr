//
//  IPaFlickr+OAuth.swift
//  IPaFlickr
//
//  Created by IPa Chen on 2020/7/9.
//

import UIKit
import CommonCrypto
import IPaKeyChain
import IPaLog
import IPaSecurity
extension IPaFlickr {
    static let flickrKeyChainService = "com.IPaFlickr." + (Bundle.main.bundleIdentifier ?? "")
    static let urlEscapeEncodeAllowCharacter = CharacterSet(charactersIn: "`~!@#$^&*()=+[]\\{}|;':\",/<>?% \n").inverted
    func oauthUrl(from baseUrlString:String,method:String,params:[String:Any]) -> String {
        let newParams = self.signedOAuth(baseUrlString, method: method, params: params)
        let query:[String] = newParams.compactMap { (key,value) in
            guard let valueString =  "\(value)".addingPercentEncoding(withAllowedCharacters: IPaFlickr.urlEscapeEncodeAllowCharacter) else {
                return nil
            }
            return "\(key)=\(valueString)"
        }
        return baseUrlString + "?" + query.joined(separator: "&")
        
    }
    func signedOAuth(_ baseUrlString:String,method:String, params:[String:Any]?) -> [String:Any] {
        var newParams = params ?? [String:Any]()
        let uuidString = UUID().uuidString
        newParams["oauth_nonce"] = uuidString[..<uuidString.index(uuidString.startIndex, offsetBy: 8)]
            
        let time = Date().timeIntervalSince1970

        newParams["oauth_timestamp"] = String(format: "%f", time)
        newParams["oauth_version"] = "1.0";
        newParams["oauth_signature_method"] = "HMAC-SHA1";
        newParams["oauth_consumer_key"] = self.apiKey;
        if let authToken = self.authToken,params?["oauth_token"] == nil {
            newParams["oauth_token"] = authToken
        }
        let signatureKey:String = apiSecret + "&" + (self.authSecret ?? "")
        var baseString = "\(method)&" + (baseUrlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "") + "&"
        let sortedKeys = newParams.keys.sorted(by: <)
        var baseStrArgs = [String]()
        
        for key in sortedKeys {
            guard let value = newParams[key] ,let valueString = "\(value)".addingPercentEncoding(withAllowedCharacters: IPaFlickr.urlEscapeEncodeAllowCharacter) else {
                continue
            }
            baseStrArgs.append("\(key)=\(valueString)")
        }
        
        baseString += (baseStrArgs.joined(separator: "&").addingPercentEncoding(withAllowedCharacters: IPaFlickr.urlEscapeEncodeAllowCharacter) ?? "")
        

        if let cKey = signatureKey.cString(using: .ascii),let cData = baseString.cString(using: .ascii) {
            //sha1
            var result: [CUnsignedChar] = Array(repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
            
            CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), cKey, strlen(cKey), cData, strlen(cData), &result)
            let data = Data(bytes: result, count: result.count)
            newParams["oauth_signature"] = data.base64EncodedString()
            
        }
        return newParams
    }
    func signed<T>(_ params:[String:Any],onProcessParam:(String,String)->T) -> [T] {
        var newParams = params
        var returnValue = [T]()
        newParams["api_key"] = self.apiKey
        var signString:String = self.apiSecret
        let sortedKeys = newParams.keys.sorted(by:<) as [String]
        for key in sortedKeys {
            guard let value = newParams[key] as? String else {
                continue
            }
            signString += "\(key)\(value)"
            let processedValue = onProcessParam("\(key)",value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")
            returnValue.append(processedValue)
        }
        let processedValue = onProcessParam("api_sig",signString.md5String ?? "")
        returnValue.append(processedValue)
        return returnValue
    }
    func signedQueryString(_ params:[String:Any]) -> String {
        let queryStrings = self.signed(params) { (key, value) in
            return "\(key)=\(value)"
        }
        return queryStrings.joined(separator: "&")
    }
    func signedArgumentComponent(_ params:[String:Any]) -> [(String,String)] {
        let argComponents = self.signed(params) { (key, value) in
            return (key,value)
        }
        return argComponents
    }
    func completeAuth(_ url:URL,complete:@escaping (Result<UserInfo,Error>)->()) {
        let oaParams = url.queryParams
        
        guard let token = oaParams["oauth_token"],let verifier = oaParams["oauth_verifier"] else {
            complete(.failure(IPaFlickr.oauthAuthorizeVerifierError))
            return
        }
        let params = ["oauth_token":token,"oauth_verifier":verifier]
        let urlString = "https://www.flickr.com/services/oauth/access_token"
        let requestUrlString = oauthUrl(from: urlString, method: "GET", params: params)
        guard let requestUrl = URL(string:requestUrlString) else {
            complete(.failure(IPaFlickr.oauthAuthorizeVerifierUrlError))
            return
        }
        let task = URLSession.shared.dataTask(with: requestUrl) { (responseData, response, error) in
            if let error = error {
                complete(.failure(error))
                return
            }
            guard let responseData = responseData, let _ = response,let responseString = String(data: responseData, encoding: .utf8) else {
                complete(.failure(IPaFlickr.oauthAuthorizeVerifierResponseError))
                return
            }
            let decodeString = responseString.removingPercentEncoding
            if decodeString?.hasPrefix("oauth_problem=") ?? true {
                self.authorized = false
                self.authToken = nil
                self.authSecret = nil
                complete(.failure(NSError(domain: IPaFlickr.errorDomain, code: 2000, userInfo: [NSLocalizedDescriptionKey:responseString])))
                return
            }
            guard let params = decodeString?.queryParams, let fullName = params["fullname"],let oauth_token = params["oauth_token"],let oauth_token_secret = params["oauth_token_secret"],let user_nsid = params["user_nsid"],let userName = params["username"] else {
                complete(.failure(NSError(domain: IPaFlickr.errorDomain, code: 2001, userInfo: [NSLocalizedDescriptionKey:responseString])))
                return
            }
            self.authorized = true
            self.authToken = oauth_token
            self.authSecret = oauth_token_secret
            
            
            let delChainQuery = IPaKeyChainGenericPassword()
            delChainQuery.secAttrService = IPaFlickr.flickrKeyChainService
            _ = delChainQuery.secItemDelete()
            let addQuery = IPaKeyChainGenericPassword()
            addQuery.secAttrService = IPaFlickr.flickrKeyChainService
            addQuery.secAttrAccount = oauth_token
            addQuery.secValueData = oauth_token_secret.data(using: String.Encoding.utf8)
            var data:AnyObject?
            if addQuery.secItemAdd(&data) == errSecSuccess {
                IPaLog("token saved!")
            }
            
            let userInfo = UserInfo(fullName: fullName, nsId: user_nsid, userName: userName)
            self.userInfo = userInfo
            complete(.success(userInfo))
        }
        task.resume()
    }
}
