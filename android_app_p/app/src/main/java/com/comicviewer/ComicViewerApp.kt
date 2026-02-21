package com.comicviewer

import android.app.Application

/**
 * Application class for Comic Viewer.
 *
 * Initializes global singletons (database, preferences) at app startup.
 */
class ComicViewerApp : Application() {

    /** Global application state (server URL, API client, database). */
    lateinit var appState: AppState
        private set

    override fun onCreate() {
        super.onCreate()
        instance = this
        appState = AppState(this)
    }

    companion object {
        /** Singleton application instance for global access. */
        lateinit var instance: ComicViewerApp
            private set
    }
}
