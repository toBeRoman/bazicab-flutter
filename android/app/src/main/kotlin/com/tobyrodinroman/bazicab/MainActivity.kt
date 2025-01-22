package com.tobyrodinroman.bazicab

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Remove splash screen before super.onCreate()
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView -> 
                splashScreenView.remove()
            }
        }
        super.onCreate(savedInstanceState)
    }
} 