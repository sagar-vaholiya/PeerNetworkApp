//
//  VideoCellView.swift
//  PeerNetworkApp
//
//  Created by Sagar Vaholiya on 23/06/25.
//

import SwiftUI
import AVFoundation


struct VideoCellView: View {
    let video: VideoItem
    let isActive: Bool
    @StateObject private var viewModel: VideoCellViewModel

    init(video: VideoItem, isActive: Bool, isError: Bool) {
        self.video = video
        self.isActive = isActive
        _viewModel = StateObject(wrappedValue: VideoCellViewModel(video: video, isError: isError))
    }

    var body: some View {
        GeometryReader { geometry in
            let orientation = UIDevice.current.orientation
            ZStack(alignment: .topLeading) {
                if viewModel.isError {
                    ErrorView()
                } else if isActive {
                    ZStack {
                        VideoPlayerView(player: $viewModel.player)
                            .id(viewModel.retryToken)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onTapGesture(count: 2) {
                                withAnimation(.interpolatingSpring(stiffness: 100, damping: 8)) { viewModel.showHeart = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    viewModel.showHeart = false
                                }
                            }
                            .onTapGesture {
                                viewModel.toggleControls()
                            }

                        if viewModel.isVideoLoading {
                            Color.black.opacity(0.5)
                            ProgressView("Loading...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .foregroundColor(.white)
                        }
                    }

                    if viewModel.showHeart {
                        BouncyHeartView(isVisible: .constant(true))
                    }
                } else {
                    Color.black
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        AsyncImage(url: video.creator.avatarURL) { image in
                            image.resizable().clipShape(Circle())
                        } placeholder: {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                        }
                        .frame(width: 40, height: 40)

                        Text(video.creator.name)
                            .fontWeight(.bold)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        Spacer()
                        Button(viewModel.showFullVideo ? "Short" : "Full") {
                            viewModel.showFullVideo.toggle()
                            viewModel.showControls.toggle()
                            viewModel.switchVideoMode()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.5))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .disabled(viewModel.isError)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 25)
                    .padding(.horizontal, 12)
                    .opacity(viewModel.isFullscreen ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isFullscreen)

                    Spacer()

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading) {
                            if viewModel.showFullVideo && viewModel.showControls && !viewModel.isFullscreen {
                                playbackControls()
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Group {
                                    Text("This is title")
                                        .lineLimit(1)
                                        .font(.headline)
                                    Text(video.description)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(3)
                                }
                            }
                            .opacity(viewModel.isFullscreen ? 0 : 1)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.isFullscreen)
                        }
                        .padding(.leading, 0)

                        Spacer()

                        VStack(alignment: .leading, spacing: 15) {
                            Group {
                                IconLabelButton(systemImageName: "hand.thumbsup", label: "88") {}
                                IconLabelButton(systemImageName: "hand.thumbsdown", label: "2") {}
                                IconLabelButton(systemImageName: "quote.bubble", label: "35") {}
                            }
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .opacity(viewModel.isFullscreen ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isFullscreen)
                    }
                    .padding()
                    .padding(.horizontal, orientation.isLandscape || orientation == .portraitUpsideDown ? 36 : 0)
                }
                .foregroundStyle(.white)

                // Fullscreen Controls Overlay
                if viewModel.isFullscreen && viewModel.showControls {
                    fullscreenControlsOverlay()
                }
            }
            .background(Color.black)
            .ignoresSafeArea()
            .onChange(of: isActive) { newValue in
                viewModel.setActive(newValue)
            }
            .onChange(of: viewModel.isError) { isError in
                if isError {
                    viewModel.cleanupPlayer()
                }
            }
            .onAppear {
                viewModel.setActive(isActive)
            }
            .onDisappear {
                viewModel.setActive(false)
                // Complete cleanup on disappear to free memory
                viewModel.cleanupPlayer()
            }
            .onVisibilityChange { isVisible in
                if !isVisible || viewModel.isError {
                    viewModel.player?.pause()
                    viewModel.isPlaying = false
                } else if isActive && !viewModel.isError {
                    viewModel.player?.play()
                    viewModel.isPlaying = true
                }
            }
        }
    }

    private func ErrorView() -> some View {
        VStack {
            VStack {
                Spacer()
                Group {
                    Text("Error!")
                        .font(.title3)
                        .padding(.bottom, 20)
                    Text("Due to some issue, we are unable to load this video... \n 😥")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                }
                .foregroundColor(.black)
                Spacer()
                Button("Retry") {
                    viewModel.isVideoLoading = true
                    viewModel.retryToken = UUID()
                    viewModel.isError = false
                    viewModel.switchVideoMode()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .padding()
            .frame(width: 250, height: 250)
            .background(Color.white)
            .cornerRadius(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func fullscreenControlsOverlay() -> some View {
        VStack {
            // Top controls
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.isFullscreen = false
                    }
                    viewModel.autoHideControls()
                }) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)

            Spacer()

            // Video progress slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button(action: {
                        viewModel.togglePlayPause()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }

                    VStack {
                        Slider(
                            value: Binding(get: {
                                viewModel.currentTime
                            }, set: { newValue in
                                viewModel.currentTime = newValue
                            }),
                            in: 0...max(viewModel.duration, 1),
                            onEditingChanged: { editing in
                                viewModel.isSeeking = editing
                                if editing {
                                    viewModel.player?.pause()
                                    viewModel.isVideoLoading = true
                                } else {
                                    let seekTime = CMTime(seconds: viewModel.currentTime, preferredTimescale: 600)
                                    viewModel.player?.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                                        if viewModel.isActive {
                                            viewModel.player?.play()
                                            viewModel.isPlaying = true
                                        }
                                        viewModel.isVideoLoading = false
                                    }
                                }
                            }
                        )
                        .accentColor(.white)

                        HStack {
                            Text(viewModel.formatTime(viewModel.currentTime))
                                .font(.caption)
                                .foregroundColor(.white)
                            Spacer()
                            Text(viewModel.formatTime(viewModel.duration))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .padding(.top, 0)
        .transition(.opacity)
        .onAppear {
            viewModel.autoHideControls()
        }
    }

    private func playbackControls() -> some View {
        return VStack(alignment: .leading) {
            Spacer()
            VStack(spacing: 0) {
                HStack {
                    Slider(
                        value: Binding(get: {
                            viewModel.currentTime
                        }, set: { newValue in
                            viewModel.currentTime = newValue
                        }),
                        in: 0...max(viewModel.duration, 1),
                        onEditingChanged: { editing in
                            viewModel.isSeeking = editing
                            if editing {
                                viewModel.player?.pause()
                                viewModel.isVideoLoading = true
                            } else {
                                let seekTime = CMTime(seconds: viewModel.currentTime, preferredTimescale: 600)
                                viewModel.player?.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                                    if viewModel.isActive {
                                        viewModel.player?.play()
                                        viewModel.isPlaying = true
                                    }
                                    viewModel.isVideoLoading = false
                                }
                            }
                        }
                    )
                    .accentColor(.white)

                    // Fullscreen button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.isFullscreen = true
                        }
                        viewModel.autoHideControls()
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }

                HStack {
                    Text(viewModel.formatTime(viewModel.currentTime))
                    Spacer()
                    Button(action: {
                        viewModel.togglePlayPause()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                            .font(Font.system(size: 16))
                    }
                    Spacer()
                    Text(viewModel.formatTime(viewModel.duration))
                }
                .font(.footnote)
                .foregroundColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .transition(.opacity)
        .padding(.leading, 0)
    }
}
