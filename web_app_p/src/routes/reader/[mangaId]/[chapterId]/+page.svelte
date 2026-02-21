<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import { page } from "$app/state";
    import {
        ArrowLeft,
        ChevronLeft,
        ChevronRight,
        Maximize2,
    } from "lucide-react";
    import { apiClient } from "$lib/services/APIClient";

    const mangaId = parseInt(page.params.mangaId);
    const chapterId = parseInt(page.params.chapterId);
    const initialPage = parseInt(page.url.searchParams.get("page") || "0");

    let pages = $state<any[]>([]);
    let currentPage = $state(initialPage);
    let isLoading = $state(true);
    let showControls = $state(true);
    let controlsTimeout: any;

    async function loadPages() {
        isLoading = true;
        try {
            pages = await apiClient.getPages(chapterId);
        } catch (err) {
            console.error(err);
        } finally {
            isLoading = false;
        }
    }

    function handleMouseMove() {
        showControls = true;
        if (controlsTimeout) clearTimeout(controlsTimeout);
        controlsTimeout = setTimeout(() => {
            showControls = false;
        }, 3000);
    }

    async function navigatePage(direction: number) {
        const newPage = currentPage + direction;
        if (newPage >= 0 && newPage < pages.length) {
            currentPage = newPage;
            await apiClient.updateProgress(mangaId, chapterId, currentPage);
        }
    }

    onMount(() => {
        loadPages();
        window.addEventListener("mousemove", handleMouseMove);
    });

    onDestroy(() => {
        if (controlsTimeout) clearTimeout(controlsTimeout);
        window.removeEventListener("mousemove", handleMouseMove);
    });
</script>

<svelte:window
    onkeydown={(e) => {
        if (e.key === "ArrowLeft") navigatePage(-1);
        if (e.key === "ArrowRight") navigatePage(1);
    }}
/>

<div class="fixed inset-0 z-50 overflow-hidden bg-black text-white">
    <!-- Page Image -->
    <div
        class="h-full w-full flex items-center justify-center p-2"
        onclick={() => (showControls = !showControls)}
    >
        {#if isLoading}
            <div
                class="h-8 w-8 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent"
            ></div>
        {:else if pages.length > 0}
            <img
                src={apiClient.getPageUrl(chapterId, currentPage)}
                alt="Page {currentPage + 1}"
                class="max-h-full max-w-full object-contain shadow-2xl"
            />
        {/if}
    </div>

    <!-- Controls Overlay -->
    <div
        class="pointer-events-none absolute inset-0 flex flex-col justify-between transition-opacity duration-500"
        class:opacity-100={showControls}
        class:opacity-0={!showControls}
    >
        <!-- Top Bar -->
        <div
            class="pointer-events-auto flex h-16 items-center justify-between bg-gradient-to-b from-black/80 to-transparent px-6"
        >
            <a
                href="/manga/{mangaId}"
                class="flex items-center gap-2 rounded-lg p-2 transition-colors hover:bg-white/10"
            >
                <ArrowLeft size={24} />
                <span class="font-medium">Back</span>
            </a>
            <div class="flex items-center gap-4">
                <span class="text-sm font-medium text-zinc-300">
                    Page {currentPage + 1} / {pages.length}
                </span>
                <button
                    class="rounded-lg p-2 transition-colors hover:bg-white/10"
                >
                    <Maximize2 size={20} />
                </button>
            </div>
        </div>

        <!-- Mid Navigation Area (Invisible buttons) -->
        <div class="flex flex-1 items-stretch">
            <button
                onclick={() => navigatePage(-1)}
                class="pointer-events-auto w-1/4 transition-colors hover:bg-white/5 flex items-center justify-start px-4 group"
            >
                <div
                    class="opacity-0 group-hover:opacity-100 transition-opacity bg-black/40 rounded-full p-4"
                >
                    <ChevronLeft size={48} />
                </div>
            </button>
            <div class="flex-1"></div>
            <button
                onclick={() => navigatePage(1)}
                class="pointer-events-auto w-1/4 transition-colors hover:bg-white/5 flex items-center justify-end px-4 group"
            >
                <div
                    class="opacity-0 group-hover:opacity-100 transition-opacity bg-black/40 rounded-full p-4"
                >
                    <ChevronRight size={48} />
                </div>
            </button>
        </div>

        <!-- Bottom Bar (Seeker) -->
        <div
            class="pointer-events-auto bg-gradient-to-t from-black/80 to-transparent p-8"
        >
            <div class="mx-auto max-w-3xl">
                <input
                    type="range"
                    min="0"
                    max={pages.length - 1}
                    bind:value={currentPage}
                    onchange={() =>
                        apiClient.updateProgress(
                            mangaId,
                            chapterId,
                            currentPage,
                        )}
                    class="accent-indigo-500 w-full h-1 bg-zinc-700 rounded-lg appearance-none cursor-pointer"
                />
            </div>
        </div>
    </div>
</div>
