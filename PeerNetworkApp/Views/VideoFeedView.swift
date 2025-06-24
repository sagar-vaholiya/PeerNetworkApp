//
//  VideoPlayerHelper.swift
//  PeerNetworkApp
//
//  Created by Sagar Vaholiya on 23/06/25.
//

import SwiftUI

struct VideoFeedView: View {
    @StateObject private var viewModel = VideoFeedViewModel()
    @State private var isLandscape = false
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.videos.isEmpty && viewModel.errorMessage == nil {
                ProgressView("Loading...")
            } else if viewModel.videos.isEmpty && !viewModel.isLoading && viewModel.errorMessage == nil {
                VStack {
                    Text(viewModel.errorMessage ?? "No videos available")
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                                GeometryReader { geo in
                                    
                                    VideoCellView(video: video, isActive: isActive(geo: geo), isError: index != 0 && index % 3 == 0)
                                        .frame(height: UIScreen.main.bounds.height)
                                        .onAppear {
                                            if index >= viewModel.videos.count - 2 && viewModel.hasMoreVideos && !viewModel.isLoading {
                                                Task { await viewModel.loadMoreVideos() }
                                            }
                                        }
                                }
                                .frame(height: isLandscape ? UIScreen.main.bounds.width : UIScreen.main.bounds.height)
                            }
                        }
                    }
                    .scrollDisabled(isLandscape)
                    .scrollTargetBehavior(.paging)
                    .ignoresSafeArea()
                }
            }
        }
        .onAppear {
            updateOrientation()
            Task {
                await viewModel.loadMoreVideos()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateOrientation()
        }
    }
    
    private func updateOrientation() {
        let orientation = UIDevice.current.orientation
        let newIsLandscape = orientation.isValidInterfaceOrientation ? orientation.isLandscape : UIScreen.main.bounds.width > UIScreen.main.bounds.height
        
        if newIsLandscape != isLandscape {
            withAnimation(.easeInOut(duration: 0.2)) {
                isLandscape = newIsLandscape
            }
        }
    }
    
    private func isActive(geo: GeometryProxy) -> Bool {
        let minY = geo.frame(in: .global).minY
        let height = UIScreen.main.bounds.height
        return minY >= -height * 0.5 && minY <= height * 0.5
    }
}
