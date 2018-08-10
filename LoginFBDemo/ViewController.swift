//
//  ViewController.swift
//  LoginFBDemo
//
//  Created by Đừng xóa on 8/7/18.
//  Copyright © 2018 Đừng xóa. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
typealias DICT = Dictionary<AnyHashable, Any>

class ViewController: UIViewController, FBSDKLoginButtonDelegate {
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var avarImage: UIImageView!
    var dispatchWorkItem: DispatchWorkItem?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let loginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["public_profile","email"]
        loginButton.delegate = self
        loginButton.center = self.view.center
        view.addSubview(loginButton)
        
        if FBSDKAccessToken.current() != nil {
            statusLabel.text = "Logged in"
            print("Logged in")
        } else {
            statusLabel.text = "not Logged in"
            print("not Logged in")
        }
        
        let customFBButton = UIButton(type: .system)
        customFBButton.backgroundColor = .blue
        customFBButton.frame = CGRect(x: 16, y: 116, width: view.frame.width - 32, height: 50)
        customFBButton.setTitle("Custom FB Login Button", for: .normal)
        customFBButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        customFBButton.setTitleColor(.white, for: .normal)
        view.addSubview(customFBButton)
        
        customFBButton.addTarget(self, action: #selector(handleCustomFBButton), for: .touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print(error.localizedDescription)
        } else if result.isCancelled {
            statusLabel.text = "Cancelled"
            print("Cancelled")
        } else {
            statusLabel.text = "User logged in"
            print("User logged in")
            getEmail()
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        statusLabel.text = "Logged out"
        emailLabel.text = "No data"
        avarImage.image = #imageLiteral(resourceName: "NoPhoto")
        print("Logged out")
    }
    
    @objc func handleCustomFBButton() {
        FBSDKLoginManager().logIn(withReadPermissions: ["public_profile","email"], from: self) { (result, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
//            print(result?.token.tokenString)
            self.getEmail()
        }
    }
    
    func getEmail() {
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name , email, picture.type(large)"]).start { (connection, result, err) in
            if err != nil {
                print(err!.localizedDescription)
            }

            guard let userData = result as? DICT else {return}
            let email = userData["email"] as? String
            self.emailLabel.text = email
            let picture = userData["picture"] as? DICT ?? [:]
            let data = picture["data"] as? DICT ?? [:]
            let url = data["url"] as? String
            self.getAvar(from: url!, completedHandler: { (image) in
                self.avarImage.image = image
            })
        }
    }
    
    func getAvar(from urlString: String, completedHandler: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {return}
        var image: UIImage?
        dispatchWorkItem = DispatchWorkItem(block: {
            if let data = try? Data(contentsOf: url) {
                image = UIImage(data: data)
            }
        })
        DispatchQueue.global().async {
            self.dispatchWorkItem?.perform()
            DispatchQueue.main.async {
                completedHandler(image)
            }
        }
    }
}

