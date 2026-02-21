import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import LibraryView from './views/LibraryView'
import MangaDetailView from './views/MangaDetailView'
import ReaderView from './views/ReaderView'
import SettingsView from './views/SettingsView'

function App() {
    return (
        <Router>
            <div className="app-container">
                <Routes>
                    <Route path="/" element={<LibraryView />} />
                    <Route path="/manga/:id" element={<MangaDetailView />} />
                    <Route path="/reader/:chapterId" element={<ReaderView />} />
                    <Route path="/settings" element={<SettingsView />} />
                </Routes>
            </div>
        </Router>
    )
}

export default App
