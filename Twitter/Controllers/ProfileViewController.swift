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
    var imageName = ""
    var username = "Name"
    var birthday = "Day"
    
    let imagePicker = UIImagePickerController()
    
    var imageFilePath = ""
    var newImageFilePath = ""
    
    var newImageName = ""
    
    var imageIsChanged = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Home", style: .plain, target: self, action: #selector(homeButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = .white
        loadInfo()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGestureRecognizer)
        
        imagePicker.delegate = self
    }

    private func loadInfo() {
        let userID = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(userID!)

        DispatchQueue.main.async {
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                self.imageURL = value?["profimage"] as? String ?? ""
                self.imageName = value?["imagename"] as? String ?? ""
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

    @objc func homeButtonPressed() {
        if newImageFilePath != "" || !imageIsChanged {
            saveChanges()
        } else {
            let alert = UIAlertController(title: "Please wait", message: "Your image has not finished uploading yet, please wait...", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        navigationController?.popViewController(animated: true)
    }
    
    private func saveChanges() {
        var values: [String: Any]?
        if imageIsChanged {
            values = ["username": usernameTextField.text! , "dateofbirth": birthdayTextField.text!, "profimage": newImageFilePath, "imagename": newImageName] as [String : Any]
        } else {
            values = ["username": usernameTextField.text! , "dateofbirth": birthdayTextField.text!] as [String : Any]
        }
        let _ = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).updateChildValues(values!)
        updateTweets()
    }
    
    private func updateTweets() {

        let ref = Database.database().reference().child("tweets")
        
        ref.observe(DataEventType.value, with: { (snapshot) in
            if let snap = snapshot.children.allObjects as? [DataSnapshot]{

                for (_,val) in snap.enumerated(){
                    let key = val.key
                    let tweet: [String: Any] = val.value as! [String : Any]
                    let id = tweet["uid"] as? String ?? ""
                    if id == Auth.auth().currentUser!.uid {
                        let _ = Database.database().reference().child("tweets").child(key).updateChildValues(["username": self.usernameTextField.text!])
                    }
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    
    }
    
    private func getDate() -> String {
        let timestamp = DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .medium, timeStyle: .short)
        return timestamp
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        imageIsChanged = true
        _ = tapGestureRecognizer.view as! UIImageView

        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            imagePicker.allowsEditing = true
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    private func deleteLastImage() {
        
        let storageRef = Storage.storage().reference()
        let desertRef = storageRef.child("profile_images").child(imageName)
        desertRef.delete { error in
          if let error = error {
            print("error \(error)")
          } else {
            print("deleted")
          }
        }
    }
    
    private func saveUserImage() {
        let image = avatarImageView.image
        newImageName = NSUUID().uuidString
        let profileImagesRef = Storage.storage().reference().child("profile_images/\(newImageName)")
        
        guard let uploadData = image?.jpegData(compressionQuality: 0.3) else {
            return
        }
        
        profileImagesRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
            if error != nil {
                return
            }
            
            profileImagesRef.downloadURL(completion: { [self] (downloadURL, error) in
                if error != nil {
                    return
                }
                
                guard let downloadURL = downloadURL else {
                    return
                }
                
                self.newImageFilePath = downloadURL.absoluteString
            })
        })
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.originalImage.rawValue)] as? UIImage {
            DispatchQueue.main.async {
                self.deleteLastImage()
                self.avatarImageView.image = pickedImage
                self.saveUserImage()
            }
        }
        picker.dismiss(animated: true, completion: nil)

    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

