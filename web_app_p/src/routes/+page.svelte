<script lang="ts">
    import { onMount } from "svelte";
    import { apiClient } from "$lib/services/APIClient";
    import Header from "$lib/components/Header.svelte";

    interface Manga {
        id: number;
        title: string;
        author: string;
        cover_path: string;
    }

    let mangas = $state<Manga[]>([]);
    let isLoading = $state(true);
    let error = $state<string | null>(null);

    async function loadMangas() {
        isLoading = true;
        try {
            mangas = await apiClient.getMangas();
            error = null;
        } catch (err) {
            error = "Could not connect to backend server. Check settings.";
            console.error(err);
        } finally {
            isLoading = false;
        }
    }

    onMount(() => {
        loadMangas();
    });
</script>

<svelte:head>
    <title>Library - Comic Viewer</title>
</svelte:head>

<Header onRefresh={loadMangas} />

<main class="fade-in">
    {#if isLoading}
        <div
            class="flex h-[60vh] flex-col items-center justify-center gap-4 text-zinc-400"
        >
            <div
                class="h-8 w-8 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent"
            ></div>
            <p>Loading your library...</p>
        </div>
    {:else if error}
        <div
            class="flex h-[60vh] flex-col items-center justify-center gap-4 text-center px-4"
        >
            <p class="text-rose-400">{error}</p>
            <button
                onclick={loadMangas}
                class="rounded-lg bg-indigo-600 px-6 py-2 font-medium transition-colors hover:bg-indigo-700"
            >
                Try Again
            </button>
        </div>
    {:else if mangas.length === 0}
        <div
            class="flex h-[60vh] flex-col items-center justify-center gap-4 text-zinc-400"
        >
            <p>No comics found.</p>
            <a href="/settings" class="text-indigo-500 hover:underline">
                Go to Settings to scan sources
            </a>
        </div>
    {:else}
        <div class="manga-grid">
            {#each mangas as manga}
                <a href="/manga/{manga.id}" class="manga-card">
                    <img
                        src={apiClient.getCoverUrl(manga.id)}
                        alt={manga.title}
                        loading="lazy"
                    />
                    <div class="manga-info text-white">
                        <h3 class="manga-title line-clamp-2">{manga.title}</h3>
                        <p class="manga-author line-clamp-1">{manga.author}</p>
                    </div>
                </a>
            {/each}
        </div>
    {/if}
</main>

<style>
    main {
        min-height: calc(100vh - 4rem);
    }
</style>
