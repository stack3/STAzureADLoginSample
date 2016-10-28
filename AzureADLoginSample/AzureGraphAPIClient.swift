//
//  AzureAPIClient.swift
//  AzureADLoginSample
//
//  Created by EIMEI on 2016/10/27.
//  Copyright © 2016 Stack3. All rights reserved.
//

import UIKit

class AzureGraphAPIClient: NSObject {
    enum APIError: Error {
        case invalidResponse
        case internalError
    }
    
    ///
    /// Azure ADへログインしてアクセストークンを取得する
    ///
    func getToken(parent: UIViewController,
                  completionHandler completionBlock: @escaping ((ADUserInformation?, NSError?) -> Void)) {
        let config = AzureConfig.shared
        var error: ADAuthenticationError?
        let authContext = ADAuthenticationContext(
            authority: config.authority,
            sharedGroup: config.keychain,
            error: &error)
        if error != nil {
            completionBlock(nil, error)
            return
        }

        authContext!.parentController = parent
        let redirectUri = URL(string: config.redirectUriString)!
        let initialUserId = ""

        ADAuthenticationSettings.sharedInstance().enableFullScreen = true
        authContext?.acquireToken(
            withResource: config.resourceId,
            clientId: config.clientId,
            redirectUri: redirectUri,
            promptBehavior: AD_PROMPT_AUTO,
            userId: initialUserId,
            extraQueryParameters: "nux=1", // if this strikes you as strange it was legacy to display the correct mobile UX. You most likely won't need it in your code.
            completionBlock: { (result) in
                if result == nil {
                    return
                }
                if result!.status != AD_SUCCEEDED {
                    completionBlock(nil, result!.error)
                } else {
                    config.accessToken = result!.tokenCacheItem.accessToken
                    completionBlock(result!.tokenCacheItem.userInformation, nil)
                }
        })
    }

    ///
    /// トークンのキャッシュをクリアする。
    /// これを行うとgetTokenでキャッシュを使わないため、再度パスワード入力が要求される
    ///
    func clearTokenCache() {
        let config = AzureConfig.shared
        if let tokenCache = ADKeychainTokenCache(group: config.keychain) {
            var error: ADAuthenticationError?
            tokenCache.removeAll(forClientId: config.clientId, error: &error)
        }
    }

    ///
    /// ユーザー情報を取得する
    /// Azure AD Graph APIのリファレンスはこちら
    /// https://msdn.microsoft.com/Library/Azure/Ad/Graph/api/api-catalog
    ///
    func getUser(_ completeHandler: @escaping (([User], Error?) -> Void)) {
        let config = AzureConfig.shared
        if config.accessToken == nil {
            return
        }

        var error: NSError?

        //
        // Graph APIのURLおよびURLRequestを生成
        // https://graph.windows.net/myorganization/users?api-version[&$filter]
        //
        let params = NSMutableDictionary()
        params.setObject(config.graphApiVersion, forKey: "api-version" as NSString)
        let ser = AFHTTPRequestSerializer()
        let graphURL = config.graphApiUrlString + "users"
        let request = ser.request(withMethod: "GET", urlString: graphURL, parameters: params, error:&error)
        //
        // Authorizationヘッダにアクセストークンを渡す
        //
        let header = "Bearer \(config.accessToken!)"
        request.setValue(header, forHTTPHeaderField:"Authorization")

        let manager = AFHTTPSessionManager()
        let task = manager.dataTask(with: request as URLRequest) { (response, responseObject, error) in
            var users = [User]()
            if error != nil {
                completeHandler(users, error)
                return
            }

            if responseObject as? [String: Any]? == nil {
                completeHandler(users, APIError.invalidResponse)
                return
            }

            let jsonObject = responseObject as! [String: Any]
            let userDataArray = jsonObject["value"] as? [[String: Any]]
            if userDataArray == nil {
                completeHandler(users, error);
                return
            }
            for userData in userDataArray! {
                let user = User()
                if let upn = userData["userPrincipalName"] as? String {
                    user.upn = upn
                }
                if let name = userData["displayName"] as? String {
                    user.name = name
                }
                if let mail = userData["mail"] as? String {
                    user.mail = mail
                }
                users.append(user)
            }
            completeHandler(users, nil)
        }
        task.resume()
    }

}
