#!/bin/bash

# TabMonitor Android Setup Script

echo "🤖 TabMonitor Android Client Setup"
echo "=================================="

# Check if Android SDK is available
if command -v adb &> /dev/null; then
    echo "✅ ADB found"
    
    # Check if device is connected
    if adb devices | grep -q "device$"; then
        echo "✅ Android device connected"
        
        # Build the APK
        echo "🔨 Building Android APK..."
        cd android-client
        
        if command -v ./gradlew &> /dev/null; then
            ./gradlew assembleDebug
            
            if [ $? -eq 0 ]; then
                echo "✅ APK built successfully"
                
                # Install the APK
                echo "📱 Installing on device..."
                adb install app/build/outputs/apk/debug/app-debug.apk
                
                if [ $? -eq 0 ]; then
                    echo "🎉 TabMonitor installed successfully!"
                    echo ""
                    echo "📋 Next Steps:"
                    echo "1. Open TabMonitor app on your Android tablet"
                    echo "2. Enter server IP: 192.168.1.70"
                    echo "3. Tap Connect"
                else
                    echo "❌ Installation failed"
                fi
            else
                echo "❌ Build failed"
            fi
        else
            echo "❌ Gradle wrapper not found"
            echo "💡 Please install Android Studio and try again"
        fi
    else
        echo "❌ No Android device connected"
        echo "💡 Please connect your tablet via USB and enable USB debugging"
    fi
else
    echo "❌ ADB not found"
    echo "💡 Please install Android Studio first"
fi
