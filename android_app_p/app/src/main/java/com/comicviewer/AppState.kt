package com.comicviewer

import android.content.Context
import android.content.SharedPreferences
import com.comicviewer.data.local.AppDatabase
import com.comicviewer.data.remote.ApiClient

/**
 * Global application state.
 *
 * Holds references to the API client, local database, and persisted
 * server URL. Acts as a simple service locator (matching the iOS
 * AppState pattern).
 *
 * @param context Application context for SharedPreferences and Room.
 */
class AppState(context: Context) {

    /** SharedPreferences for persisting user settings. */
    private val prefs: SharedPreferences =
        context.getSharedPreferences("comic_viewer_prefs", Context.MODE_PRIVATE)

    /** Base URL of the Python backend server. */
    var serverURL: String
        get() = prefs.getString(KEY_SERVER_URL, DEFAULT_SERVER_URL)
            ?: DEFAULT_SERVER_URL
        set(value) {
            prefs.edit().putString(KEY_SERVER_URL, value).apply()
            _apiClient = ApiClient.create(value)
        }

    /** Retrofit-based API client targeting the current server URL. */
    private var _apiClient: ApiClient = ApiClient.create(serverURL)
    val apiClient: ApiClient get() = _apiClient

    /** Room database for offline caching and progress tracking. */
    val database: AppDatabase = AppDatabase.getInstance(context)

    companion object {
        private const val KEY_SERVER_URL = "server_url"
        private const val DEFAULT_SERVER_URL = "http://10.0.2.2:8000"
    }
}
