<script lang="ts">
    import { onMount } from "svelte";
    import { page } from "$app/state";
    import { ArrowLeft, Play, Clock } from "lucide-react";
    import Header from "$lib/components/Header.svelte";
    import { apiClient } from "$lib/services/APIClient";

    const id = parseInt(page.params.id);

    let manga = $state<any>(null);
    let chapters = $state<any[]>([]);
    let progress = $state<any>(null);
    let isLoading = $state(true);

    async function loadMangaData() {
        isLoading = true;
        try {
            manga = await apiClient.getManga(id);
            chapters = manga.chapters || [];
            try {
                progress = await apiClient.getProgress(id);
            } catch (e) {
                // No progress yet
            }
        } catch (err) {
            console.error(err);
        } finally {
            isLoading = false;
        }
    }

    onMount(() => {
        loadMangaData();
    });

    let lastChapterId = $derived(
        progress?.chapter_id || (chapters.length > 0 ? chapters[0].id : null),
    );
    let lastPage = $derived(progress?.current_page || 0);

    function getProgressText() {
        if (!progress) return "Not started";
        const chapter = chapters.find((c) => c.id === progress.chapter_id);
        return `Chapter ${chapter?.chapter_number || "?"} - Page ${progress.current_page + 1}`;
    }
</script>

<Header title={manga?.title || "Details"} onRefresh={loadMangaData} />

<main class="fade-in px-4 pb-20">
    {#if isLoading}
        <div class="flex h-[60vh] items-center justify-center text-zinc-400">
            <p>Loading details...</p>
        </div>
    {:else if manga}
        <div class="mx-auto max-w-4xl pt-8">
            <!-- Manga Header Info -->
            <div class="flex flex-col gap-8 md:flex-row">
                <div class="manga-card w-full shrink-0 md:w-64">
                    <img
                        src={apiClient.getCoverUrl(manga.id)}
                        alt={manga.title}
                    />
                </div>

                <div class="flex flex-col justify-end gap-4">
                    <h2 class="text-3xl font-bold md:text-4xl">
                        {manga.title}
                    </h2>
                    <p class="text-xl text-zinc-400">{manga.author}</p>

                    <div class="mt-4 flex flex-wrap gap-4">
                        {#if lastChapterId}
                            <a
                                href="/reader/{manga.id}/{lastChapterId}?page={lastPage}"
                                class="flex items-center gap-2 rounded-full bg-indigo-600 px-8 py-3 font-semibold transition-all hover:scale-105 hover:bg-indigo-700 hover:shadow-lg hover:shadow-indigo-500/20"
                            >
                                <Play size={20} fill="currentColor" />
                                {progress
                                    ? "Continue Reading"
                                    : "Start Reading"}
                            </a>
                        {/if}
                    </div>
                </div>
            </div>

            <!-- Reading Progress Summary -->
            {#if progress}
                <div
                    class="glass mt-12 flex items-center gap-4 rounded-2xl p-6"
                >
                    <div
                        class="flex h-12 w-12 items-center justify-center rounded-xl bg-indigo-500/10 text-indigo-500"
                    >
                        <Clock size={24} />
                    </div>
                    <div>
                        <p
                            class="text-sm font-medium text-zinc-400 uppercase tracking-wider"
                        >
                            Last Read
                        </p>
                        <p class="text-lg font-semibold">{getProgressText()}</p>
                    </div>
                </div>
            {/if}

            <!-- Chapters List -->
            <div class="mt-12">
                <h3 class="mb-6 text-2xl font-bold">Chapters</h3>
                <div class="flex flex-col gap-3">
                    {#each chapters as chapter}
                        <a
                            href="/reader/{manga.id}/{chapter.id}"
                            class="glass flex items-center justify-between rounded-xl px-6 py-4 transition-all hover:bg-white/5 active:scale-[0.98]"
                        >
                            <span class="text-lg font-medium"
                                >Chapter {chapter.chapter_number}</span
                            >
                            <span class="text-sm text-zinc-500">Read Now</span>
                        </a>
                    {/each}
                </div>
            </div>
        </div>
    {/if}
</main>
