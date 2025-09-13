package com.tabmonitor.client

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import java.io.ByteArrayInputStream
import java.net.Socket
import java.nio.ByteBuffer
import java.util.concurrent.TimeUnit

class NetworkClient {
    
    private var socket: Socket? = null
    private var isRunning = false
    
    private val _isConnected = MutableStateFlow(false)
    val isConnected: StateFlow<Boolean> = _isConnected.asStateFlow()
    
    private val _frameData = MutableStateFlow<Bitmap?>(null)
    val frameData: StateFlow<Bitmap?> = _frameData.asStateFlow()
    
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()
    
    suspend fun connect(ipAddress: String, port: Int) = withContext(Dispatchers.IO) {
        try {
            disconnect() // Ensure clean state
            
            socket = Socket(ipAddress, port)
            socket?.soTimeout = 5000 // 5 second timeout
            
            _isConnected.value = true
            _error.value = null
            isRunning = true
            
            // Start receiving frames
            startReceivingFrames()
            
        } catch (e: Exception) {
            _error.value = "Connection failed: ${e.message}"
            _isConnected.value = false
            throw e
        }
    }
    
    fun disconnect() {
        isRunning = false
        socket?.close()
        socket = null
        _isConnected.value = false
        _frameData.value = null
    }
    
    private suspend fun startReceivingFrames() = withContext(Dispatchers.IO) {
        try {
            val inputStream = socket?.getInputStream()
            val buffer = ByteArray(8192)
            
            while (isRunning && socket?.isConnected == true) {
                try {
                    // Read frame length (4 bytes)
                    val lengthBytes = ByteArray(4)
                    var bytesRead = 0
                    while (bytesRead < 4 && isRunning) {
                        val read = inputStream?.read(lengthBytes, bytesRead, 4 - bytesRead) ?: -1
                        if (read == -1) break
                        bytesRead += read
                    }
                    
                    if (bytesRead < 4) break
                    
                    // Convert to frame length
                    val frameLength = ByteBuffer.wrap(lengthBytes).int
                    
                    if (frameLength <= 0 || frameLength > 10 * 1024 * 1024) { // Max 10MB frame
                        continue
                    }
                    
                    // Read frame data
                    val frameData = ByteArray(frameLength)
                    bytesRead = 0
                    while (bytesRead < frameLength && isRunning) {
                        val read = inputStream?.read(frameData, bytesRead, frameLength - bytesRead) ?: -1
                        if (read == -1) break
                        bytesRead += read
                    }
                    
                    if (bytesRead == frameLength) {
                        // Decode and update bitmap
                        val bitmap = BitmapFactory.decodeByteArray(frameData, 0, frameLength)
                        bitmap?.let {
                            withContext(Dispatchers.Main) {
                                _frameData.value = it
                            }
                        }
                    }
                    
                } catch (e: Exception) {
                    if (isRunning) {
                        withContext(Dispatchers.Main) {
                            _error.value = "Frame receive error: ${e.message}"
                        }
                    }
                    break
                }
            }
            
        } catch (e: Exception) {
            if (isRunning) {
                withContext(Dispatchers.Main) {
                    _error.value = "Stream error: ${e.message}"
                }
            }
        } finally {
            withContext(Dispatchers.Main) {
                _isConnected.value = false
            }
        }
    }
    
    fun sendTouchEvent(x: Float, y: Float) {
        try {
            socket?.let { socket ->
                val message = "CLICK:${x},${y}\n"
                socket.getOutputStream().write(message.toByteArray())
                socket.getOutputStream().flush()
            }
        } catch (e: Exception) {
            _error.value = "Failed to send touch event: ${e.message}"
        }
    }
}
