//
//  IPaFlickr.swift
//  IPaFlickr
//
//  Created by IPa Chen on 2020/7/7.
//

import UIKit
import IPaSecurity
import IPaLog
import IPaURLResourceUI
import IPaKeyChain
open class IPaFlickr: NSObject {
    public struct UserInfo {
        var fullName:String
        var nsId:String
        var userName:String
    }
    public enum SaftyLevel:Int {
        case safe = 1
        case parentsStronglyCautioned = 2
        case restricted = 3
    }
    public enum ContentType:Int {
        case photo = 1
        case screenCapture = 2
        case others = 3
    }
    public static let shared = IPaFlickr()
    static let oauthCallback = "ipaflickr://auth"
    var apiKey:String!
    var apiSecret:String!
    var authToken:String?
    var authSecret:String?
    var authorized = false
    var userInfo:UserInfo?
    public var isLogin:Bool {
        return self.authorized
    }
    lazy var resourceUI:IPaFlickrURLResourceUI = {
        var resourceUI = IPaFlickrURLResourceUI()
        resourceUI.baseURL = "https://api.flickr.com/services/"
        return resourceUI
    }()
    lazy var upResourceUI:IPaFlickrURLResourceUI = {
        var resourceUI = IPaFlickrURLResourceUI(IPaURLXMLResponseHandler())
        resourceUI.baseURL = "https://up.flickr.com/services/"
        return resourceUI
    }()
    public enum Permission:String {
        case read = "read"
        case write = "write"
        case delete = "delete"
    }
    open func register(_ apiKey:String,apiSecret:String) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.checkAuth { (result) in
            print(result)
        }
    }
    open func auth(from viewController:UIViewController,permission:Permission,complete:@escaping (Result<UserInfo,Error>)->()) {
        let params = ["oauth_callback": IPaFlickr.oauthCallback]
        let requestTokenUrlString = "https://www.flickr.com/services/oauth/request_token"
        let oauthRequestUrlString = oauthUrl(from: requestTokenUrlString, method: "GET", params: params)
        guard let oauthRequestUrl = URL(string:oauthRequestUrlString) else {
            complete(.failure(IPaFlickr.oauthRequestTokenUrlError))
            return
        }
        let task = URLSession.shared.dataTask(with: oauthRequestUrl) { (responseData, response, error) in
            guard let _ = response,let responseData = responseData ,let responseString = String(data: responseData, encoding: .utf8) else {
                if let error = error {
                    IPaLog(error.localizedDescription)
                    
                }
                complete(.failure(error ?? IPaFlickr.oauthRequestTokenResponseError))
                return
            }
            let oaParams = responseString.queryParams
            guard let oauth_token = oaParams["oauth_token"],let oauth_token_secret = oaParams["oauth_token_secret"] else {
                IPaLog("IPaFlickr: can not receive oauth_token info!")
                complete(.failure(IPaFlickr.oauthRequestNoTokenError))
                return
            }
            self.authToken = oauth_token
            self.authSecret = oauth_token_secret
              
            
            
            guard let beginAuthUrl = URL(string:"https://www.flickr.com/services/oauth/authorize?oauth_token=\(oauth_token)&perms=\(permission.rawValue)") else {
                IPaLog("IPaFlickr: can not receive oauth_token info!")
                complete(.failure(IPaFlickr.oauthAuthorizeUrlError))
                return
            }
            
            DispatchQueue.main.async {
                let webViewController = IPaFlickrWebViewController()
                webViewController.request = URLRequest(url: beginAuthUrl)
                let navigationController = UINavigationController(rootViewController: webViewController)
                webViewController.complete = complete
                viewController.present(navigationController, animated: true, completion: nil)
                
            }
            
        }
        task.resume()
        
    }
    open func checkAuth(_ complete:@escaping (Result<UserInfo,Error>)->()) {
        let query = IPaKeyChainGenericPassword()
        query.secAttrService = IPaFlickr.flickrKeyChainService
        query.matchLimit = .one
        query.secReturnAttributes = true
        query.secReturnData = true
        var data:AnyObject?
        let checkStatus = query.secItemCopyMatching(&data)
        if checkStatus == errSecSuccess {
            let result = IPaKeyChainGenericPassword(data:data as! [String:Any])
            
            if let token = result.secAttrAccount,let secretData = result.secValueData,let secret = String(data: secretData as Data, encoding: String.Encoding.utf8)  {
                
                self.apiFlickrGet("flickr.auth.oauth.checkToken", params: ["oauth_token": token]) { result in
                    switch result {
                    case .success(let (_,responseData)):
                        guard let data = responseData as? [String:Any],let stat = data["stat"] as? String,stat == "ok",let oauth = data["oauth"] as? [String:Any],let user = oauth["user"] as? [String:Any],let nsid = user["nsid"] as? String,let userName = user["username"] as? String,let fullame = user["fullname"] as? String else {
                            complete(.failure(IPaFlickr.oauthNoValidTokenError))
                            return
                        }
                        self.authorized = true
                        self.authToken = token
                        self.authSecret = secret
                        let userInfo = UserInfo(fullName: fullame, nsId: nsid, userName: userName)
                        self.userInfo = userInfo
                        complete(.success(userInfo))
                    case .failure(let error):
                        complete(.failure(error))
                    }
                    
                    
//                    self.authSecret = secret
//                    self.authToken = token
                }
                
                
                return
            }
        }
        
        
        complete(.failure(IPaFlickr.oauthNoTokenForCheckError))
    }
    
    open func logout() {
        self.authorized = false
        self.authSecret = nil
        self.authToken = nil
        let bundleId = Bundle.main.bundleIdentifier ?? "com.IPaFlickr"
        let delChainQuery = IPaKeyChainGenericPassword()
        delChainQuery.secAttrService = bundleId
        _ = delChainQuery.secItemDelete()
    }
    open func getMyPhotoLink(_ photoId:String) -> String? {
        guard let userInfo = userInfo else {
            return nil
        }
        return "https://www.flickr.com/photos/\(userInfo.nsId)/\(photoId)"
    }
    open func photosGetSizes(_ photoId:String,complete:@escaping ([[String:Any]])->()) {
        self.apiFlickrGet("flickr.photos.getSizes", params: ["photo_id":photoId]) { (result) in
            switch result {
            case .success(let (_ ,responseData)):
                guard let data = responseData as? [String:Any],let sizes = data["sizes"] as? [String:Any],let size = sizes["size"] as? [[String:Any]] else {
                    complete([[String:Any]]())
                    return
                }
                complete(size)
            case .failure(_):
                complete([[String:Any]]())
            }
            
        }
    }
    open func upload(_ image:UIImage,quality:CGFloat,title:String? = nil,description:String? = nil,tags:[String]? = nil,isPublic:Bool = false,isFriend:Bool = false,isFamily:Bool = false,safetyLevel:SaftyLevel? = nil,contentType:ContentType?,hidden:ContentType?,complete:@escaping (String?)->()) {
        
        var uploadArgs = [String:Any]()
        if let title = title {
            uploadArgs["title"] = title
        }
        if let description = description {
            uploadArgs["description"] = description
        }
        if let tags = tags {
            uploadArgs["tags"] = tags.joined(separator: ",")
        }
        uploadArgs["is_public"] = (isPublic) ? "1" : "0"
        uploadArgs["is_friend"] = (isFriend) ? "1" : "0"
        uploadArgs["is_family"] = (isFamily) ? "1" : "0"
        if let safetyLevel = safetyLevel {
            uploadArgs["safety_level"] = safetyLevel.rawValue
        }
        if let contentType = contentType {
            uploadArgs["content_type"] = contentType.rawValue
        }
        
        if let hidden = hidden {
            uploadArgs["hidden"] = hidden.rawValue
        }
        guard let data = image.jpegData(compressionQuality: quality) else {
            complete(nil)
            return
        }
        
        self.apiFlickrUpload(data, params: uploadArgs, complete: {
            result in
            switch result {
            case .success(let (_,responseData)):
                guard let data = responseData as? [String:Any],let rsp = data["rsp"] as? [String:Any],let photo = rsp["photoid"] as? [String:String],let photoId = photo["_content"] else {
                    complete(nil)
                    return
                }
                complete(photoId)
            case .failure(_):
                complete(nil)
            }
        })
        
    }
}

//OAuth
