//
//  ViewController.swift
//  Twitter
//
//  Created by Meruyert Tastandiyeva on 4/9/21.
//

import UIKit
import Firebase

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var lastnameTextField: UITextField!
    @IBOutlet weak var datePickerView: UIDatePicker!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    let imagePicker = UIImagePickerController()
    
    var dateOfBirth: String?
    
    var imageFilePath = ""
    
    var fileName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Login", style: .plain, target: self, action: #selector(logInButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = .white
        imagePicker.delegate = self
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        
        formatDate()
       
        if let name = nameTextField.text, let lastname = lastnameTextField.text, let email = emailTextField.text, let password = passwordTextField.text {
            
            if (self.imageFilePath != "") {
                Auth.auth().createUser(withEmail: email, password: password) { result, error in
                    if let e = error {
                        print(e)
                    } else {
                        
                        if let uid = Auth.auth().currentUser?.uid {
                            
                            let regObject: Dictionary<String, Any> = [
                                "uid" : uid,
                                "username" : name + " " + lastname,
                                "dateofbirth" : self.dateOfBirth!,
                                "profimage" : self.imageFilePath,
                                "imagename" : self.fileName,
                            ]
                            Database.database().reference().child("users").child(uid).setValue(regObject)
                        }
                        
                        
                        self.performSegue(withIdentifier: Twitler.registerSegue, sender: self)
                    }
                }
            } else {
                let alert = UIAlertController(title: "Try again", message: "Your image has not finished uploading yet, please wait...", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
            
        }
    }
    
    private func saveUserImage() {
        let image = userImageView.image
        fileName = NSUUID().uuidString
        let profileImagesRef = Storage.storage().reference().child("profile_images/\(fileName)")
        
        guard let uploadData = image!.jpegData(compressionQuality: 0.3) else {
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
                
                self.imageFilePath = downloadURL.absoluteString
 
            })
        })
    }
    
    @IBAction func cameraButtonPressed(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func galleryButtonPressed(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            imagePicker.allowsEditing = true
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    private func formatDate() {
        let formatter = DateFormatter()
        formatter.calendar = datePickerView.calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        dateOfBirth = formatter.string(from: datePickerView.date)
    }
    
    @objc func logInButtonPressed() {
        navigationController?.popViewController(animated: true)
    }
    
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.originalImage.rawValue)] as? UIImage {
            DispatchQueue.main.async {
                self.userImageView.image = pickedImage
                self.saveUserImage()
            }
        }
        picker.dismiss(animated: true, completion: nil)

    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

