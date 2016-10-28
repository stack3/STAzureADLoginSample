//
//  MainViewController.swift
//  AzureADLoginSample
//
//  Created by EIMEI on 2016/10/27.
//  Copyright © 2016 Stack3. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    @IBOutlet private weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func didTapLoginButton(sender: Any) {
        let apiClient = AzureGraphAPIClient()
        apiClient.getToken(parent: self) { (userInformation, error) in
            if error != nil {
                let con = UIAlertController(title: "Error",
                                            message: error!.localizedDescription,
                                            preferredStyle: .alert)
                con.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(con, animated: true, completion: nil)
            } else {
                let con = UIAlertController(title: "Success",
                                            message: "",
                                            preferredStyle: .alert)
                con.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(con, animated: true, completion: nil)
            }
        }
    }

    @IBAction func didTapGetUserButton(sender: Any) {
        let apiClient = AzureGraphAPIClient()
        apiClient.getUser { (users, error) in
            var text = ""
            for user in users {
                text += "[upn]\n\(user.upn)\n"
                text += "[name]\n\(user.name)\n"
                text += "[mail]\n\(user.mail)\n"
                text += "----------\n"
            }
            self.textView.text = text
        }
    }

    @IBAction func didTapClearLoginCacheButton(sender: Any) {
        let apiClient = AzureGraphAPIClient()
        apiClient.clearTokenCache()
    }
}
