# TabMonitor - Android as Second Monitor for MacBook

Transform your Android device into a wireless second monitor for your MacBook M4. This project provides a complete solution with a macOS server application and Android client app.

## 🚀 Features

- **Real-time Screen Mirroring**: Stream your MacBook screen to Android devices
- **Touch Input Support**: Use your Android device as a touch-enabled second monitor
- **Low Latency**: Optimized for smooth, responsive interaction
- **Wireless Connection**: Works over WiFi - no cables needed
- **Fullscreen Mode**: Immersive second monitor experience
- **Multi-client Support**: Connect multiple Android devices simultaneously

## 📱 Screenshots

| macOS Server | Android Client | Fullscreen Mode |
|--------------|----------------|-----------------|
| *Server controls and status* | *Connection interface* | *Full second monitor* |

## 🏗️ Architecture

```
┌─────────────────┐    WiFi/Network    ┌─────────────────┐
│   MacBook M4    │ ◄─────────────────► │ Android Device  │
│                 │                     │                 │
│  ┌───────────┐  │    Screen Data      │  ┌───────────┐  │
│  │  Server   │  │ ──────────────────► │  │  Client   │  │
│  │    App    │  │                     │  │    App    │  │
│  └───────────┘  │    Touch Events     │  └───────────┘  │
│                 │ ◄────────────────── │                 │
└─────────────────┘                     └─────────────────┘
```

## 🛠️ System Requirements

### macOS Server
- **OS**: macOS 14.0 or later
- **Hardware**: MacBook M4 (optimized for Apple Silicon)
- **Permissions**: Screen Recording access
- **Network**: WiFi connection

### Android Client
- **OS**: Android 7.0 (API level 24) or later
- **RAM**: 2GB minimum, 4GB recommended
- **Network**: WiFi connection (same network as MacBook)
- **Storage**: 50MB for app installation

## 📦 Installation

### macOS Server Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/tab-monitor.git
   cd tab-monitor/macos-server
   ```

2. **Open in Xcode**:
   ```bash
   open TabMonitorServer.xcodeproj
   ```

3. **Build and Run**:
   - Select your target device
   - Press `Cmd + R` to build and run
   - Grant screen recording permissions when prompted

4. **Alternative: Build from Terminal**:
   ```bash
   xcodebuild -project TabMonitorServer.xcodeproj -scheme TabMonitorServer -configuration Release build
   ```

### Android Client Setup

1. **Open Android Studio**:
   - File → Open → Select `android-client` folder

2. **Build the APK**:
   ```bash
   cd android-client
   ./gradlew assembleRelease
   ```

3. **Install on Device**:
   - Enable Developer Options and USB Debugging on your Android device
   - Connect via USB or use wireless debugging
   ```bash
   adb install app/build/outputs/apk/release/app-release.apk
   ```

## 🚀 Quick Start

### 1. Start the macOS Server
1. Launch the TabMonitor Server app on your MacBook
2. Click "Start Server" 
3. Note the IP address displayed (e.g., `192.168.1.100:8080`)
4. Grant screen recording permission if prompted

### 2. Connect Android Client
1. Ensure your Android device is on the same WiFi network
2. Open the TabMonitor app
3. Enter the server IP address from step 1
4. Tap "Connect"
5. The screen should appear in the preview area

### 3. Enter Fullscreen Mode
1. Once connected, tap "Enter Fullscreen"
2. Your Android device now acts as a second monitor
3. Touch the screen to send mouse clicks to your MacBook
4. Use the "Exit" button to return to the main app

## ⚙️ Configuration

### Server Settings
The macOS server can be configured by modifying these parameters in `ScreenCapture.swift`:

```swift
// Frame rate (FPS)
configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30) // 30 FPS

// Resolution scaling
configuration.width = Int(display.width * 0.5) // 50% of original
configuration.height = Int(display.height * 0.5)

// JPEG compression quality
let jpegData = nsImage.jpegRepresentation(compressionFactor: 0.7) // 70% quality
```

### Network Settings
Default port can be changed in `NetworkServer.swift`:

```swift
private let port: UInt16 = 8080 // Change to desired port
```

## 🔧 Troubleshooting

### Common Issues

**"No screen data appears on Android"**
- Verify both devices are on the same WiFi network
- Check that screen recording permission is granted on macOS
- Ensure firewall isn't blocking port 8080

**"Connection failed"**
- Double-check the IP address entered in the Android app
- Try restarting both applications
- Verify the server is running and shows "Running on port 8080"

**"Touch events don't work"**
- Ensure the Android app is in fullscreen mode
- Check that the server is receiving touch events (check console logs)
- Verify accessibility permissions if touch simulation fails

**"Poor performance/lag"**
- Reduce the frame rate in server settings
- Lower the JPEG quality for faster transmission
- Ensure both devices have strong WiFi signal

### Debug Logs

**macOS Server Logs**:
- Open Console.app and filter for "TabMonitorServer"
- Look for connection and capture status messages

**Android Client Logs**:
```bash
adb logcat | grep TabMonitor
```

## 🔒 Privacy & Security

- **Local Network Only**: All communication happens over your local WiFi network
- **No Cloud Service**: No data is sent to external servers
- **Screen Recording**: The app only captures screen content while actively running
- **Permissions**: Only requests necessary permissions (screen recording on macOS, network access on Android)

## 🛣️ Roadmap

- [ ] **Audio Streaming**: Stream audio along with video
- [ ] **Keyboard Input**: Support for keyboard input from Android
- [ ] **Multi-monitor Support**: Choose which monitor to share
- [ ] **Quality Auto-adjustment**: Automatically adjust quality based on network conditions
- [ ] **Gesture Support**: Support for multi-touch gestures
- [ ] **iOS Client**: Native iOS client application

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Test thoroughly** on both macOS and Android
5. **Commit your changes**: `git commit -m 'Add amazing feature'`
6. **Push to the branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

### Code Style
- **Swift**: Follow Apple's Swift API Design Guidelines
- **Kotlin**: Follow Android Kotlin style guide
- **Comments**: Document public APIs and complex logic

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Apple ScreenCaptureKit**: For efficient screen capture on macOS
- **Android Material Design**: For beautiful UI components
- **OkHttp**: For reliable networking on Android

## 📞 Support

If you encounter any issues or have questions:

1. **Check the troubleshooting section** above
2. **Search existing issues** on GitHub
3. **Create a new issue** with detailed information:
   - Operating system versions
   - Device models
   - Steps to reproduce the problem
   - Error messages or logs

---

**Made with ❤️ for seamless multi-device productivity**
