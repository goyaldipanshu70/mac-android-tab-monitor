<!-- TabMonitor - Android as Second Monitor for macOS -->

This project creates a solution for using Android devices as a second monitor for MacBook M4. It consists of:

1. **macOS Server Application** - Captures screen content and streams it over the network
2. **Android Client Application** - Receives and displays the screen content from the macOS server

## Project Structure
- `macos-server/` - Swift/Objective-C application for macOS
- `android-client/` - Kotlin/Java application for Android
- `shared/` - Common protocol definitions and utilities

## Development Guidelines
- Use Swift for macOS development with Screen Capture APIs
- Use Kotlin for Android development with modern UI components
- Implement efficient video streaming protocol (H.264/WebRTC)
- Focus on low latency and high quality display
- Ensure secure communication between devices

## Key Features
- Real-time screen sharing from macOS to Android
- Touch input from Android back to macOS (optional)
- Automatic device discovery on local network
- Adjustable quality settings for different network conditions
