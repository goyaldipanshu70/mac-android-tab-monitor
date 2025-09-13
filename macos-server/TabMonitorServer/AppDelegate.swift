import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var screenCapture: ScreenCapture!
    var networkServer: NetworkServer!
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupUI()
        setupServices()
    }
    
    private func setupUI() {
        // Create menu bar status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = "📺"
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Start Server", action: #selector(startServer), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Stop Server", action: #selector(stopServer), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    private func setupServices() {
        screenCapture = ScreenCapture()
        networkServer = NetworkServer()
        
        // Request screen recording permission
        requestScreenRecordingPermission()
    }
    
    private func requestScreenRecordingPermission() {
        // Check if we have screen recording permission
        let hasPermission = CGPreflightScreenCaptureAccess()
        if !hasPermission {
            // Request permission
            CGRequestScreenCaptureAccess()
        }
    }
    
    @objc private func startServer() {
        networkServer.start { [weak self] in
            self?.screenCapture.startCapture()
        }
        statusItem.button?.title = "🟢"
    }
    
    @objc private func stopServer() {
        screenCapture.stopCapture()
        networkServer.stop()
        statusItem.button?.title = "📺"
    }
    
    @objc private func quit() {
        stopServer()
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        stopServer()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
