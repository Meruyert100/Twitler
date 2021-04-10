//
//  Tweet.swift
//  Twitter
//
//  Created by Meruyert Tastandiyeva on 4/9/21.
//

import Foundation

struct Tweet: Codable {
    let key: String
    let username: String
    let body: String
    let date: String
    let userId: String
    let dateForSort: String
}
