//
//  HomeViewController.swift
//  Twitter
//
//  Created by Meruyert Tastandiyeva on 4/9/21.
//

import UIKit
import Firebase

class HomeViewController: UIViewController {

    @IBOutlet weak var hashtagSearchBar: UISearchBar!
    @IBOutlet weak var tweetsTableView: UITableView!
    @IBOutlet weak var tweetTextField: UITextField!
    
    var mainUsername: String?
    
    var tweets: [Tweet] = []
    
    var ref: DatabaseReference!
    
    var searchedTweets: [Tweet] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        loadInfo()
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(logOutButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        loadTweets()

    }
    
    private func loadTweets() {

        ref = Database.database().reference().child("tweets")
        
        ref.observe(DataEventType.value, with: { (snapshot) in
            if let snap = snapshot.children.allObjects as? [DataSnapshot]{
                self.tweets = []

                for (_,val) in snap.enumerated(){
                    let key = val.key
                    let tweet: [String: Any] = val.value as! [String : Any]
                    let username = tweet["username"] as? String ?? ""
                    let content = tweet["tweet"] as? String ?? ""
                    let date = tweet["date"] as? String ?? ""
                    let id = tweet["uid"] as? String ?? ""
                    let sortDate = tweet["dateforsort"] as? String ?? ""
                    let tweetie = Tweet(key: key, username: username, body: content, date: date, userId: id, dateForSort: sortDate)
                    self.tweets.append(tweetie)
                    self.tweets.sort{"\($0.dateForSort)" > "\($1.dateForSort)"}
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
    
    private func createSortDate() -> String {
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = format.string(from: date)

        return timestamp
    }
    
    
    @IBAction func tweetButtonPressed(_ sender: Any) {
        addTweetToDB()
        loadTweets()
        tweetTextField.text = ""
    }
    
    private func addTweetToDB() {

        let uid = Auth.auth().currentUser!.uid
        
        let unique = uid + randomString(length: 3)
        
        let regObject: Dictionary<String, Any> = [
            "uid": uid,
            "username": mainUsername!,
            "tweet": tweetTextField.text!,
            "date": getDate(),
            "dateforsort": createSortDate()
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
                self.mainUsername = value?["username"] as? String
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
    
    private func searchTweets(string: String) {
        searchedTweets = []
        for tweet in tweets {
            if tweet.body.contains(string) || tweet.body.contains(string.lowercased()) {
                searchedTweets.append(tweet)
            }
        }
        tweets = searchedTweets
        tweetsTableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let destVC = segue.destination as? TweetDetailsViewController else { return }
        guard let cell = sender as? TweetTableViewCell,
              let indexPath = tweetsTableView.indexPath(for: cell) else { return }
        let tweet = tweets[indexPath.row]
        destVC.tweet = tweet
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}

extension HomeViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let searchText = searchBar.text!
        searchTweets(string: searchText)

    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil || searchBar.text == ""
        {
            searchBar.perform(#selector(self.resignFirstResponder), with: nil, afterDelay: 0)
            loadTweets()
        }
    }
}
