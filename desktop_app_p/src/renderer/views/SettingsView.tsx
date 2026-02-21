import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Server, Globe, RefreshCcw, Check, AlertCircle } from 'lucide-react'
import Header from '../components/Header'
import { apiClient } from '../services/APIClient'

interface Source {
    id: number
    name: string
    path: string
    source_type: string
}

function SettingsView() {
    const [backendUrl, setBackendUrl] = useState(apiClient.getBaseUrl())
    const [sources, setSources] = useState<Source[]>([])
    const [isHealthy, setIsHealthy] = useState<boolean | null>(null)
    const [isScanning, setIsScanning] = useState<number | null>(null)
    const navigate = useNavigate()

    const loadSources = async () => {
        try {
            const data = await apiClient.getSources()
            setSources(data)
        } catch (err) {
            console.error(err)
        }
    }

    const checkHealth = async () => {
        const healthy = await apiClient.checkHealth()
        setIsHealthy(healthy)
    }

    useEffect(() => {
        loadSources()
        checkHealth()
    }, [])

    const handleUrlChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setBackendUrl(e.target.value)
    }

    const saveUrl = () => {
        apiClient.setBaseUrl(backendUrl)
        checkHealth()
        loadSources()
    }

    const handleScan = async (sourceId: number) => {
        setIsScanning(sourceId)
        try {
            await apiClient.scanSource(sourceId)
            alert('Scan complete!')
            loadSources()
        } catch (err) {
            alert('Scan failed. Check backend.')
        } finally {
            setIsScanning(null)
        }
    }

    return (
        <>
            <Header title="Settings" />

            <main className="container fade-in">
                <button className="btn btn-ghost" onClick={() => navigate(-1)} style={{ marginBottom: '24px' }}>
                    <ArrowLeft size={20} /> Back
                </button>

                {/* Backend Configuration */}
                <div className="glass" style={{ padding: '24px', marginBottom: '32px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '24px' }}>
                        <Server size={24} color="var(--accent-color)" />
                        <h2 style={{ fontSize: '1.25rem' }}>Backend Configuration</h2>
                    </div>

                    <div style={{ display: 'flex', gap: '12px', marginBottom: '16px' }}>
                        <div style={{ flex: 1 }}>
                            <label style={{ display: 'block', fontSize: '0.9rem', color: 'var(--text-secondary)', marginBottom: '8px' }}>
                                Server URL
                            </label>
                            <input
                                type="text"
                                value={backendUrl}
                                onChange={handleUrlChange}
                                className="glass"
                                style={{
                                    width: '100%',
                                    padding: '12px',
                                    backgroundColor: 'rgba(0,0,0,0.2)',
                                    color: 'white',
                                    outline: 'none'
                                }}
                            />
                        </div>
                        <button
                            className="btn btn-primary"
                            onClick={saveUrl}
                            style={{ alignSelf: 'flex-end', height: '45px' }}
                        >
                            Save
                        </button>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.9rem' }}>
                        {isHealthy === true ? (
                            <><Check size={16} color="#10b981" /> <span style={{ color: '#10b981' }}>Connected to Backend</span></>
                        ) : isHealthy === false ? (
                            <><AlertCircle size={16} color="#ef4444" /> <span style={{ color: '#ef4444' }}>Could not connect to Backend</span></>
                        ) : (
                            <span style={{ color: 'var(--text-secondary)' }}>Checking connection...</span>
                        )}
                    </div>
                </div>

                {/* Sources Management */}
                <div className="glass" style={{ padding: '24px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '24px' }}>
                        <Globe size={24} color="var(--accent-color)" />
                        <h2 style={{ fontSize: '1.25rem' }}>Sources</h2>
                    </div>

                    {sources.length === 0 ? (
                        <p style={{ color: 'var(--text-secondary)', textAlign: 'center', padding: '20px' }}>
                            No sources found. Add them in the backend or mobile app.
                        </p>
                    ) : (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                            {sources.map(source => (
                                <div
                                    key={source.id}
                                    className="glass"
                                    style={{
                                        padding: '16px',
                                        display: 'flex',
                                        justifyContent: 'space-between',
                                        alignItems: 'center',
                                        backgroundColor: 'rgba(255,255,255,0.02)'
                                    }}
                                >
                                    <div>
                                        <div style={{ fontWeight: 600 }}>{source.name}</div>
                                        <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>{source.path}</div>
                                    </div>
                                    <button
                                        className="btn btn-ghost"
                                        onClick={() => handleScan(source.id)}
                                        disabled={isScanning === source.id}
                                    >
                                        <RefreshCcw size={18} className={isScanning === source.id ? 'animate-spin' : ''} />
                                        {isScanning === source.id ? 'Scanning...' : 'Scan Now'}
                                    </button>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                <div style={{ marginTop: '40px', textAlign: 'center' }}>
                    <p style={{ color: 'var(--text-secondary)', fontSize: '0.8rem' }}>
                        Comic Viewer Desktop v1.0.0
                    </p>
                </div>
            </main>
        </>
    )
}

export default SettingsView
