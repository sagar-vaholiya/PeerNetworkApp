//
//  PeerNetworkAppApp.swift
//  PeerNetworkApp
//
//  Created by Sagar Vaholiya on 23/06/25.
//

import SwiftUI

@main
struct PeerNetworkApp: App {
    var body: some Scene {
        WindowGroup(content: {
            VideoFeedView()
                .statusBar(hidden: true)
        })
    }
}
