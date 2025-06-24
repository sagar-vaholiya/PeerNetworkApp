//
//  VideoItem.swift
//  PeerNetworkApp
//
//  Created by Sagar Vaholiya on 23/06/25.
//

import Foundation

struct VideoItem: Identifiable, Equatable, Codable {
    let id: String
    let creator: Creator
    let shortVideoURL: URL
    let fullVideoURL: URL
    let description: String
    let likes: Int
    let comments: Int
    
    static func == (lhs: VideoItem, rhs: VideoItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct Creator: Codable, Equatable {
    let id: String
    let name: String
    let avatarURL: URL
}
