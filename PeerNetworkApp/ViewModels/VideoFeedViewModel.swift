//
//  VideoPlayerHelper.swift
//  PeerNetworkApp
//
//  Created by Sagar Vaholiya on 23/06/25.
//

import Foundation

@MainActor
class VideoFeedViewModel: ObservableObject {
    @Published var videos: [VideoItem] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var hasMoreVideos = true  // Track if more videos are available

    private var isFetching = false

    func loadMoreVideos() async {
        guard !isFetching && hasMoreVideos else {
            return
        }
        
        isFetching = true
        isLoading = true
        
        do {
            let newVideos = try await withCheckedThrowingContinuation { continuation in
                MockAPIService.fetchVideos { result in
                    continuation.resume(with: result)
                }
            }
            
            // If we receive an empty array, it means no more videos are available
            if newVideos.isEmpty {
                hasMoreVideos = false
            } else {
                videos.append(contentsOf: newVideos)
            }
            
            errorMessage = nil
            
        } catch {
            print("Error loading videos: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
        isFetching = false
    }

    func retry() {
        errorMessage = nil
        // Reset hasMoreVideos when retrying in case it was a network error
        hasMoreVideos = true
        Task { await loadMoreVideos() }
    }
}
