//
//  TweetDetailsViewController.swift
//  Twitter
//
//  Created by Meruyert Tastandiyeva on 4/10/21.
//

import UIKit
import Firebase

class TweetDetailsViewController: UIViewController {

    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet weak var tweetTextField: UITextField!
    
    var tweet: Tweet?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Home", style: .plain, target: self, action: #selector(homeButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = .white
        loadInfo()
    }
    
    private func loadInfo() {
        usernameLabel.text = tweet?.username
        tweetTextField.text = tweet?.body
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        let values = ["tweet": tweetTextField.text! , "date": getDate()] as [String : Any]
        let _ = Database.database().reference().child("tweets").child(tweet!.key).updateChildValues(values)
        navigationController?.popViewController(animated: true)
    }
    
    private func getDate() -> String {
        let timestamp = DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .medium, timeStyle: .short)
        return timestamp
    }

    @IBAction func trashButtonPressed(_ sender: Any) {
        let _ = Database.database().reference().child("tweets").child(tweet!.key).removeValue()
        navigationController?.popViewController(animated: true)
    }
    
    @objc func homeButtonPressed() {
        navigationController?.popViewController(animated: true)
    }
}
