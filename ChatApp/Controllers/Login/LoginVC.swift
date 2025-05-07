//
//  LoginVC.swift
//  ChatApp
//
//  Created by Emirhan İpek on 17.04.2025.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginVC: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = .chatLogo
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Email Adress..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .white
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Password..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .white
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let fbLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private let googleLogInButton = GIDSignInButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Register",
            style: .done,
            target: self,
            action: #selector(didTapRegister)
        )
        
        loginButton.addTarget(
            self,
            action: #selector(loginButtonTapped),
            for: .touchUpInside
        )
        
        googleLogInButton.addTarget(self, action: #selector(googleSignInTapped), for: .touchUpInside)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        fbLoginButton.delegate = self
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(fbLoginButton)
        scrollView.addSubview(googleLogInButton)
        
        fbLoginButton.center = view.center
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(
            x: (scrollView.width-size)/2,
            y: 20,
            width: size,
            height: size
        )
        emailTextField.frame = CGRect(
            x: 30,
            y: imageView.bottom+10,
            width: scrollView.width-60,
            height: 52
        )
        passwordTextField.frame = CGRect(
            x: 30,
            y: emailTextField.bottom+10,
            width: scrollView.width-60,
            height: 52
        )
        loginButton.frame = CGRect(
            x: 30,
            y: passwordTextField.bottom+10,
            width: scrollView.width-60,
            height: 52
        )
        fbLoginButton.frame = CGRect(
            x: 30,
            y: loginButton.bottom+10,
            width: scrollView.width-60,
            height: 52
        )
        googleLogInButton.frame = CGRect(
            x: 30,
            y: fbLoginButton.bottom+10,
            width: scrollView.width-60,
            height: 52
        )
    }
    
    @objc private func loginButtonTapped() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        guard let email = emailTextField.text, let password = passwordTextField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        // Firebase Log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            
            let user = result.user
            print("Logged In User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true)
        })
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(
            title: "Login Error",
            message: "Please enter a valid email and password.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterVC()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func googleSignInTapped() {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            guard error == nil else { return }
            guard let signInResult = signInResult else { return }
            
            print("Did sign in with Google: \(signInResult)")
            
            let user = signInResult.user
            guard let email = user.profile?.email,
                  let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName else { return }
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    // insert to database
                    DatabaseManager.shared.insertUser(with: ChatAppUser(
                        firstName: firstName,
                        lastName: lastName,
                        emailAddress: email)
                    )
                }
            })
            
            signInResult.user.refreshTokensIfNeeded { user, error in
                guard error == nil else { return }
                guard let user = user else { return }
                guard let idToken = user.idToken else { return }
                
                let accessToken = user.accessToken
                let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
                
                FirebaseAuth.Auth.auth().signIn(with: credential, completion: { authResult, error in
                    guard authResult != nil, error == nil else {
                        print("failed to log in with google credential")
                        return
                    }
                    
                    print("Successfully logged in with google credential")
                    self.navigationController?.dismiss(animated: true)
                })
            }
        }
    }
}

extension LoginVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            loginButtonTapped()
        }
        return true
    }
}

extension LoginVC: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        // no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(
            graphPath: "me",
            parameters: ["fields": "email, name"],
            tokenString: token,
            version: nil,
            httpMethod: .get
        )
        
        facebookRequest.start(
            completion: {
                _,
                result,
                error in
                guard let result = result as? [String: Any],
                      error == nil else {
                    print("Failed to make facebook graph request")
                    return
                }
                
                guard let userName = result["name"] as? String,
                      let email = result["email"] as? String else {
                    print("Failed to extract email or name from facebook result")
                    return
                }
                
                let nameComponents = userName.split(separator: " ")
                guard nameComponents.count == 2 else {
                    return
                }
                
                let firstName = String(nameComponents[0])
                let lastName = String(nameComponents[1])
                
                DatabaseManager.shared.userExists(
                    with: email,
                    completion: { exists in
                        if !exists {
                            DatabaseManager.shared.insertUser(
                                with: ChatAppUser(
                                    firstName: firstName,
                                    lastName: lastName,
                                    emailAddress: email
                                )
                            )
                        }
                    })
                
                let credential = FacebookAuthProvider.credential(withAccessToken: token)
                
                FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                    guard let strongSelf = self else { return }
                    
                    guard authResult != nil, error == nil else {
                        if let error = error {
                            print("Facebook credential login failed, MFA may be needed - \(error)")
                        }
                        return
                    }
                    
                    print("Successfully logged in with facebook")
                    strongSelf.navigationController?.dismiss(animated: true)
                })
            })
    }
}
