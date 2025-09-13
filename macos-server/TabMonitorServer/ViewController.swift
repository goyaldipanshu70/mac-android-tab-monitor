import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var statusLabel: NSLabel!
    @IBOutlet weak var ipAddressLabel: NSLabel!
    @IBOutlet weak var connectedClientsLabel: NSLabel!
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    
    private var appDelegate: AppDelegate {
        return NSApplication.shared.delegate as! AppDelegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
    }
    
    private func setupUI() {
        startButton.isEnabled = true
        stopButton.isEnabled = false
        
        // Display local IP address
        if let ipAddress = appDelegate.networkServer.getLocalIPAddress() {
            ipAddressLabel.stringValue = "Server IP: \(ipAddress):8080"
        } else {
            ipAddressLabel.stringValue = "Server IP: Unable to determine"
        }
    }
    
    private func updateUI() {
        // Update UI based on server status
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let isRunning = self.appDelegate.networkServer.serverStatus.contains("Running")
            self.startButton.isEnabled = !isRunning
            self.stopButton.isEnabled = isRunning
            
            self.statusLabel.stringValue = "Status: \(self.appDelegate.networkServer.serverStatus)"
            self.connectedClientsLabel.stringValue = "Connected Clients: \(self.appDelegate.networkServer.connectedClients)"
        }
        
        // Schedule next update
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateUI()
        }
    }
    
    @IBAction func startServerClicked(_ sender: NSButton) {
        appDelegate.startServer()
        
        // Setup frame callback
        appDelegate.screenCapture.setFrameCallback { [weak self] frameData in
            self?.appDelegate.networkServer.broadcast(frameData: frameData)
        }
    }
    
    @IBAction func stopServerClicked(_ sender: NSButton) {
        appDelegate.stopServer()
    }
}
