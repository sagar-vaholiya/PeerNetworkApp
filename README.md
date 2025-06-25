# PeerNetworkApp

This project is a SwiftUI-based TikTok/Instagram Reels-style video feed, built for iOS 17 and later. It simulates a short-form video browsing experience with autoplay, infinite scroll, error handling, and playback controls.

## Architecture

The app follows a lightweight MVVM structure with modular responsibilities:

## Why MVVM?

### Benefits:

- Separates UI from logic, keeping views simple while placing all complex logic inside ViewModels.
- Each video gets its own ViewModel to handle playback and state separately, avoiding conflicts.
- Business logic is separated, making it easier to write tests just for the ViewModels.
- SwiftUI updates the UI automatically thanks to `@Published` properties and `ObservableObject`.
- UI components like the video player and buttons are reusable and don’t depend on app-specific code.

Overall, MVVM helps keep the app scalable, easier to debug, and ready for adding new features down the line.

## Components

- **View (SwiftUI)**  
  Renders UI using `VideoCellView`, `VideoFeedView`, and reusable components like `IconLabelButton`.

- **VideoFeedViewModel**  
  - Manages API calls, pagination, error state, and loading indicators.  
  - Observes which video is active via `onAppear` and `GeometryReader`.
    
- **VideoCellViewModel**
  - Manages per-video playback state, controls, and visibility lifecycle.
  - Handles switching between short and full video versions.
  - Manages `AVPlayer` setup, teardown, progress tracking, and looping.
  - Controls like play/pause, seeker, fullscreen toggle, and error handling are tied to this view model.
  - Activated/deactivated via `setActive(_:)` when a video enters or exits the viewport.

- **Model (`VideoItem`, `Creator`)**  
  - Codable structs representing video and creator data.

- **Service (`MockAPIService`)**  
  - Simulates batched video loading (20 per request).  
  - Simulates a network error every 3rd request for robust error handling.  
  - Supports loading mock data from a bundled JSON file.

- **VideoPlayerView**  
  A `UIViewRepresentable` wrapper around `AVPlayerLayer` for smooth video rendering and control.

## Features

### Scrollable Feed

- Displays a scrollable list of short videos.
- Autoplay behavior when video is 50%+ visible.
- Infinite scrolling: loads 20 videos per batch.
- Pauses videos when they scroll out of the viewport.
- Empty state message: `"No videos available"`.

### Video Content Layout

Each video includes:  
- 👤 Creator avatar and name (top-left)  
- 🎬 Video content (centered, autoplay)  
- ❤️/👎/💬 Action buttons (bottom-right)  
- 📝 Description text (bottom-left)

---

## Enhancements

### 1. ❤️ Like Animation
- Double-tap gesture to like.
- Animated heart appears temporarily.

### 2. Short/Full Version Toggle
- Short version: looping, no controls.
- Full version includes:  
  - Playback controls  
  - Progress seeker  
  - Play/pause toggle  
  - Fullscreen orientation handling

### 3. Error Handling
- Every 3rd API call simulates a network error.
- Retry button and message shown on failure.
- UI disables interactions during error state.

---

## Tech Stack

**NOTE:** This demo is created with the following environment due to macOS/Xcode limitations.

- **IDE:** Xcode 16.2 (minimum required: Xcode 16)  
- **Language:** Swift 6  
- **iOS SDK:** 17.0 (targets iOS 17 and later)  
- **macOS:** Sonoma (macOS 14)

## How to Run the App

### Requirements

- Xcode 16 or later  
- iOS 17.0+ simulator or device

---

## Video

Video preview available at:  
[Sample Video](https://github.com/sagar-vaholiya/PeerNetworkApp/blob/main/sample_video_720.mp4)
