# TabMonitor Communication Protocol

## Overview
The TabMonitor system uses a simple TCP-based protocol for communication between the macOS server and Android client.

## Connection
- **Protocol**: TCP
- **Default Port**: 8080
- **Connection Type**: Long-lived persistent connection

## Data Formats

### Screen Frame Transmission (Server → Client)
```
[4 bytes: Frame Length (Big Endian)] + [Frame Data (JPEG)]
```

1. **Frame Length**: 4-byte unsigned integer in big-endian format indicating the size of the following frame data
2. **Frame Data**: JPEG-encoded image data of the screen capture

### Touch Event Transmission (Client → Server)
```
CLICK:x,y\n
```

- **Format**: ASCII text message
- **x**: Relative X coordinate (0.0 to 1.0)
- **y**: Relative Y coordinate (0.0 to 1.0)
- **Terminator**: Newline character (`\n`)

## Connection Flow

1. **Connection Establishment**
   - Client connects to server IP address on port 8080
   - Server accepts connection and adds client to active connections list

2. **Screen Streaming**
   - Server captures screen at 30 FPS (configurable)
   - Each frame is compressed to JPEG (70% quality)
   - Server broadcasts frame to all connected clients
   - Frame format: [Length][JPEG Data]

3. **Touch Input**
   - Client detects touch events on the displayed image
   - Converts touch coordinates to relative values (0.0-1.0)
   - Sends touch command to server: `CLICK:x,y\n`
   - Server converts relative coordinates to absolute screen coordinates
   - Server simulates mouse click at calculated position

4. **Connection Termination**
   - Client can disconnect at any time
   - Server detects disconnection and removes client from list
   - Server continues serving other connected clients

## Error Handling

- **Connection Errors**: Client displays error message and allows reconnection
- **Frame Decode Errors**: Client skips corrupted frames and continues
- **Touch Event Errors**: Server logs errors but continues operation

## Performance Considerations

- **Frame Rate**: 30 FPS maximum, adjustable based on network conditions
- **Compression**: JPEG compression at 70% quality for balance of quality/performance
- **Resolution**: Server automatically scales down capture to 50% of original resolution
- **Buffer Management**: 5-frame queue depth to handle network variations
