package com.tabmonitor.client

import android.graphics.Bitmap
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class MainViewModel : ViewModel() {
    
    private val networkClient = NetworkClient()
    
    private val _isConnected = MutableStateFlow(false)
    val isConnected: StateFlow<Boolean> = _isConnected.asStateFlow()
    
    private val _currentFrame = MutableStateFlow<Bitmap?>(null)
    val currentFrame: StateFlow<Bitmap?> = _currentFrame.asStateFlow()
    
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()
    
    init {
        // Observe connection state
        viewModelScope.launch {
            networkClient.isConnected.collect { connected ->
                _isConnected.value = connected
            }
        }
        
        // Observe frames
        viewModelScope.launch {
            networkClient.frameData.collect { frame ->
                _currentFrame.value = frame
            }
        }
        
        // Observe errors
        viewModelScope.launch {
            networkClient.error.collect { errorMessage ->
                _error.value = errorMessage
            }
        }
    }
    
    suspend fun connect(ipAddress: String, port: Int) {
        try {
            networkClient.connect(ipAddress, port)
        } catch (e: Exception) {
            _error.value = "Failed to connect: ${e.message}"
        }
    }
    
    fun disconnect() {
        networkClient.disconnect()
    }
    
    fun sendTouchEvent(x: Float, y: Float) {
        if (_isConnected.value) {
            networkClient.sendTouchEvent(x, y)
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        networkClient.disconnect()
    }
}
