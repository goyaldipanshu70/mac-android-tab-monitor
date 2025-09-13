package com.tabmonitor.client

import android.app.Application
import android.content.Context

class TabMonitorApplication : Application() {
    
    companion object {
        lateinit var instance: TabMonitorApplication
            private set
        
        val appContext: Context
            get() = instance.applicationContext
    }
    
    override fun onCreate() {
        super.onCreate()
        instance = this
    }
}
