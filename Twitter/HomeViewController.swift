//
//  HomeViewController.swift
//  Twitter
//
//  Created by Meruyert Tastandiyeva on 4/9/21.
//

import UIKit
import Firebase

protocol UserDetails {
    
}

class HomeViewController: UIViewController {

    @IBOutlet weak var hashtagSearchBar: UISearchBar!
    @IBOutlet weak var tweetsTableView: UITableView!
    @IBOutlet weak var tweetTextField: UITextField!
    
    var username: String?
    
    var tweets: [Tweet] = []
    
    var ref: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadInfo()
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(logOutButtonPressed))
        
        loadTweets()

    }
    
    private func loadTweets() {

        ref = Database.database().reference().child("tweets")
        
        ref.observe(DataEventType.value, with: { (snapshot) in
            if let snap = snapshot.children.allObjects as? [DataSnapshot]{
                self.tweets = []

                for (_,val) in snap.enumerated(){
                    let tweet: [String: Any] = val.value as! [String : Any]
                    let username = tweet["username"] as? String ?? ""
                    let content = tweet["tweet"] as? String ?? ""
                    let date = tweet["date"] as? String ?? ""
                    let tweetie = Tweet(username: username, body: content, date: date)
                    self.tweets.append(tweetie)
                    
                    DispatchQueue.main.async {
                        self.tweetsTableView.reloadData()
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
    
    
    @IBAction func tweetButtonPressed(_ sender: Any) {
        addTweetToDB()
        loadTweets()
    }
    
    private func addTweetToDB() {

        let uid = Auth.auth().currentUser!.uid
        
        let unique = uid + randomString(length: 3)
        
        let regObject: Dictionary<String, Any> = [
            "uid" : uid,
            "username" : username!,
            "tweet": tweetTextField.text!,
            "date": getDate()
        ]
        
        Database.database().reference().child("tweets").child(unique).setValue(regObject)

    }
    
    private func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    private func loadInfo() {
        let userID = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(userID!)

        DispatchQueue.main.async {
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                self.username = value?["username"] as? String
              }) { (error) in
                print(error.localizedDescription)
            }
            
        }
    }
   
    @objc func logOutButtonPressed() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Twitler.cellIdentifier, for: indexPath) as! TweetTableViewCell
        cell.dateLabel.text = tweets[indexPath.row].date
        cell.usernameLabel.text = tweets[indexPath.row].username
        cell.tweetLabel.text = tweets[indexPath.row].body
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    
}
