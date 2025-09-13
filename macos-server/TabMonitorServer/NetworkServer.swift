import Foundation
import Network
import Combine

class NetworkServer: ObservableObject {
    
    private var listener: NWListener?
    private var connections: Set<NWConnection> = []
    private let queue = DispatchQueue(label: "NetworkServer")
    private var isRunning = false
    private let port: UInt16 = 8080
    
    @Published var connectedClients: Int = 0
    @Published var serverStatus: String = "Stopped"
    
    func start(completion: @escaping () -> Void) {
        guard !isRunning else { return }
        
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: port))
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    print("Server listening on port \(self?.port ?? 0)")
                    DispatchQueue.main.async {
                        self?.serverStatus = "Running on port \(self?.port ?? 0)"
                    }
                    completion()
                case .failed(let error):
                    print("Server failed: \(error)")
                    DispatchQueue.main.async {
                        self?.serverStatus = "Failed: \(error.localizedDescription)"
                    }
                case .cancelled:
                    print("Server cancelled")
                    DispatchQueue.main.async {
                        self?.serverStatus = "Stopped"
                    }
                default:
                    break
                }
            }
            
            listener?.start(queue: queue)
            isRunning = true
            
        } catch {
            print("Failed to start server: \(error)")
            serverStatus = "Failed to start: \(error.localizedDescription)"
        }
    }
    
    func stop() {
        guard isRunning else { return }
        
        // Close all connections
        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()
        
        listener?.cancel()
        listener = nil
        isRunning = false
        
        DispatchQueue.main.async {
            self.connectedClients = 0
            self.serverStatus = "Stopped"
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        connections.insert(connection)
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Client connected")
                DispatchQueue.main.async {
                    self?.connectedClients = self?.connections.count ?? 0
                }
                self?.setupDataReceiving(for: connection)
                
            case .cancelled, .failed:
                print("Client disconnected")
                self?.connections.remove(connection)
                DispatchQueue.main.async {
                    self?.connectedClients = self?.connections.count ?? 0
                }
                
            default:
                break
            }
        }
        
        connection.start(queue: queue)
    }
    
    private func setupDataReceiving(for connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                // Handle incoming data from client (e.g., touch events)
                self?.handleClientData(data, from: connection)
            }
            
            if !isComplete {
                self?.setupDataReceiving(for: connection)
            }
        }
    }
    
    private func handleClientData(_ data: Data, from connection: NWConnection) {
        // Parse client commands (mouse clicks, keyboard input, etc.)
        if let message = String(data: data, encoding: .utf8) {
            print("Received from client: \(message)")
            
            // Example: Handle mouse click events
            if message.hasPrefix("CLICK:") {
                let coordinates = message.replacingOccurrences(of: "CLICK:", with: "")
                let parts = coordinates.split(separator: ",")
                if parts.count == 2,
                   let x = Double(parts[0]),
                   let y = Double(parts[1]) {
                    simulateMouseClick(at: CGPoint(x: x, y: y))
                }
            }
        }
    }
    
    private func simulateMouseClick(at point: CGPoint) {
        // Simulate mouse click at the given coordinates
        let clickDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)
        let clickUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)
        
        clickDown?.post(tap: .cghidEventTap)
        clickUp?.post(tap: .cghidEventTap)
    }
    
    func broadcast(frameData: Data) {
        guard !connections.isEmpty else { return }
        
        // Create a simple protocol: 4 bytes for data length + data
        var lengthData = Data()
        let length = UInt32(frameData.count).bigEndian
        lengthData.append(Data(bytes: &length, count: 4))
        
        let packet = lengthData + frameData
        
        for connection in connections {
            connection.send(content: packet, completion: .contentProcessed { error in
                if let error = error {
                    print("Failed to send frame: \(error)")
                }
            })
        }
    }
    
    func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" || name == "en1" {  // WiFi or Ethernet
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                        break
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
}
