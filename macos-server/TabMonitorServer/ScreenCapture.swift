import Cocoa
import ScreenCaptureKit
import VideoToolbox
import CoreMedia

class ScreenCapture: NSObject, SCStreamDelegate {
    
    private var stream: SCStream?
    private var isCapturing = false
    private var displays: [SCDisplay] = []
    private var onFrameCallback: ((Data) -> Void)?
    
    override init() {
        super.init()
        getAvailableDisplays()
    }
    
    func setFrameCallback(_ callback: @escaping (Data) -> Void) {
        self.onFrameCallback = callback
    }
    
    private func getAvailableDisplays() {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                self.displays = content.displays
            } catch {
                print("Failed to get displays: \(error)")
            }
        }
    }
    
    func startCapture() {
        guard !isCapturing else { return }
        guard let display = displays.first else {
            print("No displays available")
            return
        }
        
        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        
        let configuration = SCStreamConfiguration()
        configuration.width = Int(display.width * 0.5) // Reduce resolution for better performance
        configuration.height = Int(display.height * 0.5)
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30) // 30 FPS
        configuration.queueDepth = 5
        configuration.showsCursor = true
        configuration.capturesAudio = false
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        
        stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        
        do {
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: DispatchQueue.global(qos: .userInteractive))
            stream?.startCapture()
            isCapturing = true
            print("Screen capture started")
        } catch {
            print("Failed to start capture: \(error)")
        }
    }
    
    func stopCapture() {
        guard isCapturing else { return }
        
        stream?.stopCapture()
        stream = nil
        isCapturing = false
        print("Screen capture stopped")
    }
    
    // MARK: - SCStreamDelegate
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("Stream stopped with error: \(error)")
        isCapturing = false
    }
}

// MARK: - SCStreamOutput

extension ScreenCapture: SCStreamOutput {
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        
        // Convert CMSampleBuffer to compressed image data
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else { return }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        guard let context = CGContext(data: baseAddress,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: bitmapInfo.rawValue) else { return }
        
        guard let cgImage = context.makeImage() else { return }
        
        // Convert to JPEG for transmission
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
        guard let jpegData = nsImage.jpegRepresentation(compressionFactor: 0.7) else { return }
        
        onFrameCallback?(jpegData)
    }
}

// MARK: - NSImage Extension

extension NSImage {
    func jpegRepresentation(compressionFactor: CGFloat) -> Data? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionFactor])
    }
}
