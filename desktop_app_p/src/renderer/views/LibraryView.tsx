import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import Header from '../components/Header'
import { apiClient } from '../services/APIClient'

interface Manga {
    id: number
    title: string
    total_chapters: number
    cover_path: string
}

function LibraryView() {
    const [mangas, setMangas] = useState<Manga[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)
    const navigate = useNavigate()

    const loadMangas = async () => {
        setIsLoading(true)
        try {
            const data = await apiClient.getMangas()
            setMangas(data)
            setError(null)
        } catch (err) {
            setError('Could not connect to backend server. Check settings.')
        } finally {
            setIsLoading(false)
        }
    }

    useEffect(() => {
        loadMangas()
    }, [])

    return (
        <>
            <Header title="Library" onRefresh={loadMangas} isRefreshing={isLoading} />

            <main className="container">
                {error && (
                    <div className="glass" style={{ padding: '24px', textAlign: 'center', marginTop: '40px', borderColor: '#ef4444' }}>
                        <p style={{ color: '#ef4444', marginBottom: '16px' }}>{error}</p>
                        <button className="btn btn-primary" onClick={() => navigate('/settings')}>Go to Settings</button>
                    </div>
                )}

                {isLoading && mangas.length === 0 ? (
                    <div style={{ textAlign: 'center', marginTop: '100px', color: 'var(--text-secondary)' }}>
                        <p>Loading your library...</p>
                    </div>
                ) : mangas.length === 0 && !error ? (
                    <div className="glass" style={{ padding: '40px', textAlign: 'center', marginTop: '40px' }}>
                        <h2 style={{ marginBottom: '8px' }}>No Mangas Found</h2>
                        <p style={{ color: 'var(--text-secondary)', marginBottom: '24px' }}>Add a source in settings to get started.</p>
                        <button className="btn btn-primary" onClick={() => navigate('/settings')}>Settings</button>
                    </div>
                ) : (
                    <div className="manga-grid fade-in">
                        {mangas.map((manga) => (
                            <div
                                key={manga.id}
                                className="manga-card glass"
                                onClick={() => navigate(`/manga/${manga.id}`)}
                            >
                                <img
                                    src={apiClient.getCoverUrl(manga.id)}
                                    alt={manga.title}
                                    className="manga-cover"
                                    onError={(e) => {
                                        (e.target as HTMLImageElement).src = 'https://via.placeholder.com/200x300?text=No+Cover'
                                    }}
                                />
                                <div className="manga-info" style={{ padding: '12px' }}>
                                    <h3 className="manga-title" title={manga.title}>{manga.title}</h3>
                                    <p className="manga-chapters">{manga.total_chapters} chapters</p>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </main>
        </>
    )
}

export default LibraryView
