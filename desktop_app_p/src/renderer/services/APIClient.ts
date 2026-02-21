import axios from 'axios'

const DEFAULT_BASE_URL = 'http://localhost:8000'

class APIClient {
    private baseUrl: string

    constructor() {
        this.baseUrl = localStorage.getItem('backend_url') || DEFAULT_BASE_URL
    }

    setBaseUrl(url: string) {
        this.baseUrl = url.replace(/\/$/, '')
        localStorage.setItem('backend_url', this.baseUrl)
    }

    getBaseUrl() {
        return this.baseUrl
    }

    async getMangas() {
        const response = await axios.get(`${this.baseUrl}/api/mangas`)
        return response.data
    }

    async getManga(id: number) {
        const response = await axios.get(`${this.baseUrl}/api/mangas/${id}`)
        return response.data
    }

    async getChapter(id: number) {
        const response = await axios.get(`${this.baseUrl}/api/chapters/${id}`)
        return response.data
    }

    async getPages(chapterId: number) {
        const response = await axios.get(`${this.baseUrl}/api/chapters/${chapterId}/pages`)
        return response.data
    }

    getCoverUrl(mangaId: number) {
        return `${this.baseUrl}/api/mangas/${mangaId}/cover`
    }

    getPageUrl(chapterId: number, pageNumber: number) {
        return `${this.baseUrl}/api/chapters/${chapterId}/pages/${pageNumber}`
    }

    async getProgress(mangaId: number) {
        try {
            const response = await axios.get(`${this.baseUrl}/api/progress/${mangaId}`)
            return response.data
        } catch (error) {
            return null
        }
    }

    async updateProgress(mangaId: number, chapterId: number, currentPage: number, totalPages: number) {
        await axios.put(`${this.baseUrl}/api/progress/${mangaId}`, {
            chapter_id: chapterId,
            current_page: currentPage,
            total_pages: totalPages
        })
    }

    async getSources() {
        const response = await axios.get(`${this.baseUrl}/api/sources`)
        return response.data
    }

    async scanSource(id: number) {
        const response = await axios.post(`${this.baseUrl}/api/sources/${id}/scan`)
        return response.data
    }

    async checkHealth() {
        try {
            const response = await axios.get(`${this.baseUrl}/api/health`)
            return response.status === 200
        } catch {
            return false
        }
    }
}

export const apiClient = new APIClient()
