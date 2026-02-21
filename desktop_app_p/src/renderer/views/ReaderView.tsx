import { useState, useEffect, useRef } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, ChevronLeft, ChevronRight, Maximize2 } from 'lucide-react'
import { apiClient } from '../services/APIClient'

interface Chapter {
    id: number
    manga_id: number
    title: string
}

interface Page {
    page_number: number
    url: string
}

function ReaderView() {
    const { chapterId } = useParams<{ chapterId: string }>()
    const [chapter, setChapter] = useState<Chapter | null>(null)
    const [pages, setPages] = useState<Page[]>([])
    const [currentPage, setCurrentPage] = useState(0)
    const [isLoading, setIsLoading] = useState(true)
    const [showControls, setShowControls] = useState(true)
    const navigate = useNavigate()
    const controlsTimeout = useRef<NodeJS.Timeout | null>(null)

    const loadChapterData = async () => {
        if (!chapterId) return
        setIsLoading(true)
        try {
            const id = parseInt(chapterId)
            const [chapterData, pagesData] = await Promise.all([
                apiClient.getChapter(id),
                apiClient.getPages(id)
            ])
            setChapter(chapterData)
            setPages(pagesData.pages)

            // Load progress
            const progress = await apiClient.getProgress(chapterData.manga_id)
            if (progress && progress.chapter_id === id) {
                setCurrentPage(progress.current_page)
            }
        } catch (err) {
            console.error(err)
        } finally {
            setIsLoading(false)
        }
    }

    useEffect(() => {
        loadChapterData()
    }, [chapterId])

    useEffect(() => {
        if (chapter && pages.length > 0) {
            apiClient.updateProgress(chapter.manga_id, chapter.id, currentPage, pages.length)
        }
    }, [currentPage])

    const handleMouseMove = () => {
        setShowControls(true)
        if (controlsTimeout.current) clearTimeout(controlsTimeout.current)
        controlsTimeout.current = setTimeout(() => {
            setShowControls(false)
        }, 3000)
    }

    const nextPage = () => {
        if (currentPage < pages.length - 1) {
            setCurrentPage(prev => prev + 1)
            window.scrollTo(0, 0)
        }
    }

    const prevPage = () => {
        if (currentPage > 0) {
            setCurrentPage(prev => prev - 1)
            window.scrollTo(0, 0)
        }
    }

    if (isLoading) return <div style={{ background: '#000', height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>Loading...</div>
    if (pages.length === 0) return <div style={{ background: '#000', height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>No pages found.</div>

    return (
        <div
            style={{ background: '#000', minHeight: '100vh', position: 'relative' }}
            onMouseMove={handleMouseMove}
        >
            {/* Controls Header */}
            <div
                className="glass"
                style={{
                    position: 'fixed',
                    top: 0,
                    left: 0,
                    right: 0,
                    zIndex: 100,
                    padding: '16px 24px',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    transition: 'opacity 0.3s',
                    opacity: showControls ? 1 : 0,
                    pointerEvents: showControls ? 'all' : 'none',
                    borderRadius: 0,
                    borderTop: 'none',
                    borderLeft: 'none',
                    borderRight: 'none'
                }}
            >
                <button className="btn btn-ghost" onClick={() => navigate(`/manga/${chapter?.manga_id}`)}>
                    <ArrowLeft size={20} /> {chapter?.title}
                </button>
                <div style={{ color: 'var(--text-secondary)' }}>
                    Page {currentPage + 1} of {pages.length}
                </div>
                <button className="btn btn-ghost" onClick={() => { }}>
                    <Maximize2 size={20} />
                </button>
            </div>

            {/* Page Content */}
            <div
                style={{
                    display: 'flex',
                    justifyContent: 'center',
                    paddingTop: '60px',
                    paddingBottom: '80px',
                    cursor: 'pointer'
                }}
                onClick={(e) => {
                    const x = e.clientX
                    const width = window.innerWidth
                    if (x > width * 0.7) nextPage()
                    else if (x < width * 0.3) prevPage()
                    else setShowControls(prev => !prev)
                }}
            >
                <img
                    src={apiClient.getPageUrl(parseInt(chapterId!), currentPage)}
                    alt={`Page ${currentPage + 1}`}
                    style={{ maxWidth: '100%', maxHeight: 'calc(100vh - 80px)', objectFit: 'contain' }}
                />
            </div>

            {/* Navigation Footer */}
            <div
                style={{
                    position: 'fixed',
                    bottom: 24,
                    left: '50%',
                    transform: 'translateX(-50%)',
                    zIndex: 100,
                    display: 'flex',
                    gap: '24px',
                    opacity: showControls ? 1 : 0,
                    transition: 'opacity 0.3s',
                    pointerEvents: showControls ? 'all' : 'none'
                }}
            >
                <button
                    className="btn glass"
                    onClick={(e) => { e.stopPropagation(); prevPage(); }}
                    disabled={currentPage === 0}
                    style={{ width: '48px', height: '48px', display: 'flex', justifyContent: 'center' }}
                >
                    <ChevronLeft size={24} />
                </button>
                <div
                    className="glass"
                    style={{
                        padding: '12px 24px',
                        display: 'flex',
                        alignItems: 'center',
                        minWidth: '120px',
                        justifyContent: 'center'
                    }}
                >
                    {currentPage + 1} / {pages.length}
                </div>
                <button
                    className="btn glass"
                    onClick={(e) => { e.stopPropagation(); nextPage(); }}
                    disabled={currentPage === pages.length - 1}
                    style={{ width: '48px', height: '48px', display: 'flex', justifyContent: 'center' }}
                >
                    <ChevronRight size={24} />
                </button>
            </div>
        </div>
    )
}

export default ReaderView
