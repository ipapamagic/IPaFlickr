//
//  IPaFlickr+Error.swift
//  IPaFlickr
//
//  Created by IPa Chen on 2020/7/9.
//

import UIKit

extension IPaFlickr {
    static let errorDomain = "com.ipaflickr.error"
    static let oauthRequestTokenUrlError:Error = NSError(domain: IPaFlickr.errorDomain, code: 1000, userInfo: [NSLocalizedDescriptionKey:"oauth token request url generate failed!"])
    static let oauthRequestTokenResponseError:Error = NSError(domain: IPaFlickr.errorDomain, code: 1001, userInfo: [NSLocalizedDescriptionKey:"oauth token request response error!"])
    static let oauthRequestNoTokenError:Error = NSError(domain: IPaFlickr.errorDomain, code: 1002, userInfo: [NSLocalizedDescriptionKey:"can not receive token from oauth token request!"])
    static let oauthAuthorizeUrlError:Error = NSError(domain: IPaFlickr.errorDomain, code: 1002, userInfo: [NSLocalizedDescriptionKey:"oauth authorize request generate failed!"])
    static let oauthAuthorizeVerifierError:Error = NSError(domain: IPaFlickr.errorDomain, code: 1003, userInfo: [NSLocalizedDescriptionKey:"can not obtain token/secret from auth request"])
    static let oauthAuthorizeVerifierUrlError:Error = NSError(domain: IPaFlickr.errorDomain, code: 1004, userInfo: [NSLocalizedDescriptionKey:"auth request url generate failed!"])
    static let oauthAuthorizeVerifierResponseError:Error = NSError(domain: IPaFlickr.errorDomain, code: 1005, userInfo: [NSLocalizedDescriptionKey:"auth request response error!"])
    static let oauthAuthorizeError:Error = NSError(domain: IPaFlickr.errorDomain, code: 1006, userInfo: [NSLocalizedDescriptionKey:"auth request response error!"])
    static let oauthNoTokenForCheckError:Error = NSError(domain: IPaFlickr.errorDomain, code: 1007, userInfo: [NSLocalizedDescriptionKey:"no token for check!"])
    static let oauthNoValidTokenError:Error = NSError(domain: IPaFlickr.errorDomain, code: 1008, userInfo: [NSLocalizedDescriptionKey:"current token is not valid!"])
}
