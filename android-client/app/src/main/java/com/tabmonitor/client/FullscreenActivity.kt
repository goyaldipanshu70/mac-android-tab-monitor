package com.tabmonitor.client

import android.os.Bundle
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import com.tabmonitor.client.databinding.ActivityFullscreenBinding
import kotlinx.coroutines.launch

class FullscreenActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityFullscreenBinding
    private val viewModel: MainViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityFullscreenBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupFullscreen()
        setupTouchHandling()
        observeViewModel()
    }
    
    private fun setupFullscreen() {
        // Hide system UI
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        windowInsetsController.hide(WindowInsetsCompat.Type.systemBars())
        
        // Keep screen on
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        
        // Exit fullscreen on back press
        binding.exitButton.setOnClickListener {
            finish()
        }
    }
    
    private fun setupTouchHandling() {
        binding.screenImageView.setOnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    // Calculate relative coordinates (0-1)
                    val relativeX = event.x / view.width
                    val relativeY = event.y / view.height
                    
                    // Send touch event to server
                    viewModel.sendTouchEvent(relativeX, relativeY)
                    true
                }
                else -> false
            }
        }
    }
    
    private fun observeViewModel() {
        lifecycleScope.launch {
            viewModel.currentFrame.collect { frame ->
                frame?.let {
                    binding.screenImageView.setImageBitmap(it)
                }
            }
        }
        
        lifecycleScope.launch {
            viewModel.isConnected.collect { isConnected ->
                if (!isConnected) {
                    // If disconnected, return to main activity
                    finish()
                }
            }
        }
    }
    
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            // Re-hide system UI when gaining focus
            val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
            windowInsetsController.hide(WindowInsetsCompat.Type.systemBars())
        }
    }
}
