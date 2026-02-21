import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Play, Clock } from 'lucide-react'
import Header from '../components/Header'
import { apiClient } from '../services/APIClient'

interface Chapter {
    id: number
    title: string
    chapter_number: number
}

interface Manga {
    id: number
    title: string
    description?: string
    chapters: Chapter[]
}

interface Progress {
    chapter_id: number | null
    current_page: number
    total_pages: number
}

function MangaDetailView() {
    const { id } = useParams<{ id: string }>()
    const [manga, setManga] = useState<Manga | null>(null)
    const [progress, setProgress] = useState<Progress | null>(null)
    const [isLoading, setIsLoading] = useState(true)
    const navigate = useNavigate()

    const loadData = async () => {
        if (!id) return
        setIsLoading(true)
        try {
            const [mangaData, progressData] = await Promise.all([
                apiClient.getManga(parseInt(id)),
                apiClient.getProgress(parseInt(id))
            ])
            setManga(mangaData)
            setProgress(progressData)
        } catch (err) {
            console.error(err)
        } finally {
            setIsLoading(false)
        }
    }

    useEffect(() => {
        loadData()
    }, [id])

    if (isLoading) return <div className="container" style={{ textAlign: 'center', marginTop: '100px' }}>Loading...</div>
    if (!manga) return <div className="container" style={{ textAlign: 'center', marginTop: '100px' }}>Manga not found.</div>

    const continueChapterId = progress?.chapter_id || (manga.chapters.length > 0 ? manga.chapters[0].id : null)

    return (
        <>
            <Header title={manga.title} />

            <main className="container fade-in">
                <button className="btn btn-ghost" onClick={() => navigate('/')} style={{ marginBottom: '24px' }}>
                    <ArrowLeft size={20} /> Back to Library
                </button>

                <div className="glass" style={{ display: 'flex', gap: '32px', padding: '32px', marginBottom: '40px' }}>
                    <img
                        src={apiClient.getCoverUrl(manga.id)}
                        alt={manga.title}
                        style={{ width: '240px', borderRadius: '12px', boxShadow: '0 8px 16px rgba(0,0,0,0.4)' }}
                    />
                    <div style={{ flex: 1 }}>
                        <h2 style={{ fontSize: '2rem', marginBottom: '16px' }}>{manga.title}</h2>
                        <p style={{ color: 'var(--text-secondary)', marginBottom: '32px', lineHeight: '1.6' }}>
                            {manga.description || 'No description available for this manga.'}
                        </p>

                        <div style={{ display: 'flex', gap: '16px' }}>
                            {continueChapterId && (
                                <button
                                    className="btn btn-primary"
                                    onClick={() => navigate(`/reader/${continueChapterId}`)}
                                    style={{ padding: '12px 24px', fontSize: '1.1rem' }}
                                >
                                    <Play size={20} fill="currentColor" />
                                    {progress?.chapter_id ? 'Continue Reading' : 'Start Reading'}
                                </button>
                            )}
                        </div>

                        {progress?.chapter_id && (
                            <div style={{ marginTop: '24px', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <Clock size={16} />
                                <span>Last read: Page {progress.current_page + 1} of chapter {manga.chapters.find(c => c.id === progress.chapter_id)?.title}</span>
                            </div>
                        )}
                    </div>
                </div>

                <h3 style={{ fontSize: '1.5rem', marginBottom: '24px' }}>Chapters</h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                    {manga.chapters.map((chapter) => (
                        <div
                            key={chapter.id}
                            className="glass"
                            style={{
                                padding: '16px 24px',
                                display: 'flex',
                                justifyContent: 'space-between',
                                alignItems: 'center',
                                cursor: 'pointer',
                                transition: 'background 0.2s'
                            }}
                            onClick={() => navigate(`/reader/${chapter.id}`)}
                            onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.05)'}
                            onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                        >
                            <span style={{ fontWeight: 500 }}>{chapter.title}</span>
                            {progress?.chapter_id === chapter.id && (
                                <span style={{ fontSize: '0.8rem', color: 'var(--accent-color)', fontWeight: 600 }}>IN PROGRESS</span>
                            )}
                        </div>
                    ))}
                </div>
            </main>
        </>
    )
}

export default MangaDetailView
