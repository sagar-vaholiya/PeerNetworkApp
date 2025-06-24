//
//  MockAPIService.swift
//  PeerNetworkApp
//
//  Created by Sagar Vaholiya on 23/06/25.
//

import Foundation

final class MockAPIService {
    static var requestCount = 0
    static var nextVideoIndex = 0  // Renamed for clarity - tracks next video to use from JSON
    static var totalUsersCreated = 0

    static func fetchVideos(batch: Int = 20, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        requestCount += 1

        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            // Simulate network error every 3rd request
            if requestCount % 3 == 0 {
                completion(.failure(NSError(domain: "", code: -1009, userInfo: [NSLocalizedDescriptionKey: "Simulated network error"])))
                return
            }
            
            var templateVideos: [VideoItem] = []
            
            // Load template data from JSON file
            guard let url = Bundle.main.url(forResource: "mock_response", withExtension: "json") else {
                completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "mock_response.json not found in bundle"])))
                return
            }

            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                templateVideos = try decoder.decode([VideoItem].self, from: data)
            } catch {
                completion(.failure(error))
                return
            }
            
            // Ensure we have template data
            guard !templateVideos.isEmpty else {
                completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "No template videos available"])))
                return
            }

            // Check if we've exhausted all videos
            guard nextVideoIndex < templateVideos.count else {
                // Return empty array when no more videos are available
                completion(.success([]))
                return
            }

            // Calculate how many videos we can actually return
            let remainingVideos = templateVideos.count - nextVideoIndex
            let actualBatchSize = min(batch, remainingVideos)
            
            // Generate mock videos using template data (without wrapping around)
            let mockVideos = (0..<actualBatchSize).map { i in
                let templateIndex = nextVideoIndex + i
                let template = templateVideos[templateIndex]
                let userNumber = totalUsersCreated + i + 1
                
                return VideoItem(
                    id: UUID().uuidString,
                    creator: Creator(
                        id: "user\(userNumber)",
                        name: "User \(userNumber)",
                        avatarURL: template.creator.avatarURL
                    ),
                    shortVideoURL: template.shortVideoURL,
                    fullVideoURL: template.fullVideoURL,
                    description: "\(template.description) - Video by User \(userNumber)",
                    likes: Int.random(in: 0...1000),
                    comments: Int.random(in: 0...100)
                )
            }
            
            // Update counters
            nextVideoIndex += actualBatchSize
            totalUsersCreated += actualBatchSize
            
            completion(.success(mockVideos))
        }
    }
}
