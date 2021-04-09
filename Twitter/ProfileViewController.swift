//
//  ProfileViewController.swift
//  Twitter
//
//  Created by Meruyert Tastandiyeva on 4/9/21.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var birthdayTextField: UITextField!
    
    var imageURL = ""
    var username = "Name"
    var birthday = "Day"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadInfo()
    }

    private func loadInfo() {
        let userID = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(userID!)

        DispatchQueue.main.async {
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                self.imageURL = value?["profimage"] as? String ?? ""
                self.usernameTextField.text = value?["username"] as? String
                self.birthdayTextField.text = value?["dateofbirth"] as? String
                self.loadAvatar(imageUrl: self.imageURL)
              }) { (error) in
                print(error.localizedDescription)
            }
            
        }
        
    }
    
    private func loadAvatar(imageUrl: String) {
        guard let url = URL(string: imageURL) else { return }
        
        guard let imageData = try? Data(contentsOf: url) else { return }
        
        let image = UIImage(data: imageData)
        DispatchQueue.main.async {
            self.avatarImageView.image = image
        }
    }

}
