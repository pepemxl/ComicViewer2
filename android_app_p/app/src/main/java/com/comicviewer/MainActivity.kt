package com.comicviewer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.comicviewer.ui.navigation.AppNavigation
import com.comicviewer.ui.theme.ComicViewerTheme

/**
 * Single-activity entry point for Comic Viewer.
 *
 * Uses Jetpack Compose for the entire UI. Edge-to-edge rendering
 * is enabled for a modern, immersive look.
 */
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val appState = (application as ComicViewerApp).appState

        setContent {
            ComicViewerTheme {
                AppNavigation(appState = appState)
            }
        }
    }
}
