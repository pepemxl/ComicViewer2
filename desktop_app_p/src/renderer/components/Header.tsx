import { useNavigate } from 'react-router-dom'
import { Book, Settings, RefreshCw } from 'lucide-react'

interface HeaderProps {
    title: string
    onRefresh?: () => void
    isRefreshing?: boolean
}

function Header({ title, onRefresh, isRefreshing }: HeaderProps) {
    const navigate = useNavigate()

    return (
        <header className="header glass fade-in">
            <div className="flex items-center gap-4" style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                <Book size={24} color="var(--accent-color)" />
                <h1 style={{ fontSize: '1.5rem', fontWeight: 700 }}>{title}</h1>
            </div>

            <div style={{ display: 'flex', gap: '12px' }}>
                {onRefresh && (
                    <button
                        className="btn btn-ghost"
                        onClick={onRefresh}
                        disabled={isRefreshing}
                    >
                        <RefreshCw size={20} className={isRefreshing ? 'animate-spin' : ''} />
                    </button>
                )}
                <button className="btn btn-ghost" onClick={() => navigate('/settings')}>
                    <Settings size={20} />
                </button>
            </div>
        </header>
    )
}

export default Header
