//
//  VideoCellViewModel.swift
//  PeerNetworkApp
//
//  Created by Sagar Vaholiya on 24/06/25.
//

import SwiftUI
import AVFoundation

class VideoCellViewModel: ObservableObject {
    let video: VideoItem

    @Published var isError: Bool
    @Published var showFullVideo = false
    @Published var showHeart = false
    @Published var player: AVPlayer?
    @Published var observedPlayer: AVPlayer?
    @Published var isPlaying = true
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var showControls = false
    @Published var isFullscreen = false
    @Published var retryToken = UUID()
    @Published var isVideoLoading = true
    @Published var isSeeking = false

    var timeObserver: Any?
    var controlsHideTask: DispatchWorkItem?
    var isActive = false
    private var hasBeenSetup = false

    init(video: VideoItem, isError: Bool) {
        self.video = video
        self.isError = isError
    }

    deinit {
        cleanupPlayer()
    }

    func setActive(_ active: Bool) {
        guard isActive != active else { return }
        isActive = active
        
        if active && !isError {
            if !hasBeenSetup || player == nil {
                hasBeenSetup = true
                switchVideoMode()
            } else {
                // Resume existing player
                player?.play()
                isPlaying = true
            }
        } else {
            // Pause when not active, error state, or being cleaned up
            player?.pause()
            isPlaying = false
        }
    }

    func switchVideoMode() {
        // Don't setup video if in error state
        guard !isError else { return }
        
        // Always cleanup previous player completely before creating new one
        cleanupPlayer()
        
        let url = showFullVideo ? video.fullVideoURL : video.shortVideoURL

        Task {
            let asset = AVURLAsset(url: url)
            do {
                let newItem = AVPlayerItem(asset: asset)
                newItem.preferredForwardBufferDuration = 0

                await MainActor.run {
                    self.isVideoLoading = true

                    // Create new player
                    self.player = AVPlayer(playerItem: newItem)
                    self.player?.automaticallyWaitsToMinimizeStalling = false
                    
                    // Only start playing if this view is active and not in error state
                    if self.isActive && !self.isError {
                        self.player?.play()
                        self.isPlaying = true
                    } else {
                        self.isPlaying = false
                    }

                    Task {
                        do {
                            let assetDuration = try await asset.load(.duration)
                            await MainActor.run {
                                self.duration = CMTimeGetSeconds(assetDuration)
                            }
                        } catch {
                            await MainActor.run {
                                self.duration = 0
                            }
                        }
                    }

                    // Setup time observer
                    if let player = self.player {
                        self.timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.033, preferredTimescale: 600), queue: .main) { time in
                            self.currentTime = time.seconds
                            self.isVideoLoading = (player.timeControlStatus != .playing && self.isActive && !self.isError)
                        }
                        self.observedPlayer = player
                    }

                    // Setup loop for short videos only
                    if !self.showFullVideo {
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: newItem, queue: .main) { _ in
                            if self.isActive && !self.isError {
                                self.player?.seek(to: .zero)
                                self.player?.play()
                            }
                        }
                    }

                    NotificationCenter.default.addObserver(forName: .AVPlayerItemNewAccessLogEntry, object: newItem, queue: .main) { _ in
                        if !self.isError {
                            self.isVideoLoading = false
                        }
                    }
                }
            } catch {
                print("Failed to preload asset: \(error)")
            }
        }
    }

    func cleanupPlayer() {
        // Pause and stop the player immediately
        player?.pause()
        player?.rate = 0
        
        // Remove time observer
        if let observer = timeObserver, let oldPlayer = observedPlayer {
            oldPlayer.removeTimeObserver(observer)
        }
        timeObserver = nil
        observedPlayer = nil

        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        // Cancel any pending tasks
        controlsHideTask?.cancel()
        controlsHideTask = nil

        // Clear player reference
        player = nil
        currentTime = 0
        duration = 1
        isPlaying = false
    }

    func togglePlayPause() {
        guard let player = player, isActive, !isError else { return }
        isPlaying.toggle()
        isPlaying ? player.play() : player.pause()
        autoHideControls()
    }

    func toggleControls() {
        withAnimation { showControls.toggle() }
        if showControls { autoHideControls() }
    }

    func autoHideControls() {
        controlsHideTask?.cancel()
        let task = DispatchWorkItem {
            withAnimation { self.showControls = false }
        }
        controlsHideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: task)
    }

    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
