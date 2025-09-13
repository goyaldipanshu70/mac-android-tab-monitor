package com.tabmonitor.client

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import com.tabmonitor.client.databinding.ActivityMainBinding
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    private val viewModel: MainViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupUI()
        observeViewModel()
    }
    
    private fun setupUI() {
        binding.connectButton.setOnClickListener {
            val ipAddress = binding.ipAddressEditText.text.toString().trim()
            if (ipAddress.isNotEmpty()) {
                connectToServer(ipAddress)
            } else {
                Toast.makeText(this, "Please enter a valid IP address", Toast.LENGTH_SHORT).show()
            }
        }
        
        binding.disconnectButton.setOnClickListener {
            viewModel.disconnect()
        }
        
        binding.fullscreenButton.setOnClickListener {
            if (viewModel.isConnected.value == true) {
                startFullscreenMode()
            } else {
                Toast.makeText(this, "Please connect to server first", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    private fun observeViewModel() {
        lifecycleScope.launch {
            viewModel.isConnected.collect { isConnected ->
                binding.connectButton.isEnabled = !isConnected
                binding.disconnectButton.isEnabled = isConnected
                binding.connectionStatus.text = if (isConnected) "Connected" else "Disconnected"
            }
        }
        
        lifecycleScope.launch {
            viewModel.currentFrame.collect { frame ->
                frame?.let {
                    binding.screenImageView.setImageBitmap(it)
                }
            }
        }
        
        lifecycleScope.launch {
            viewModel.error.collect { error ->
                error?.let {
                    Toast.makeText(this@MainActivity, it, Toast.LENGTH_LONG).show()
                }
            }
        }
    }
    
    private fun connectToServer(ipAddress: String) {
        lifecycleScope.launch {
            viewModel.connect(ipAddress, 8080)
        }
    }
    
    private fun startFullscreenMode() {
        val intent = Intent(this, FullscreenActivity::class.java)
        startActivity(intent)
    }
}
