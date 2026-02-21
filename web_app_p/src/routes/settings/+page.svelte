<script lang="ts">
    import { onMount } from "svelte";
    import {
        Server,
        Database,
        Activity,
        RefreshCcw,
        Plus,
        Trash2,
    } from "lucide-react";
    import Header from "$lib/components/Header.svelte";
    import { apiClient } from "$lib/services/APIClient";

    let backendUrl = $state(apiClient.getBaseUrl());
    let sources = $state<any[]>([]);
    let health = $state<any>(null);
    let isLoading = $state(false);
    let isScanning = $state<number | null>(null);

    let newSourceName = $state("");
    let newSourcePath = $state("");

    async function loadSettings() {
        isLoading = true;
        try {
            sources = await apiClient.getSources();
            health = await apiClient.checkHealth();
        } catch (err) {
            console.error(err);
        } finally {
            isLoading = false;
        }
    }

    function updateUrl() {
        apiClient.setBaseUrl(backendUrl);
        loadSettings();
    }

    async function addSource() {
        if (!newSourceName || !newSourcePath) return;
        try {
            await apiClient.addSource(newSourceName, newSourcePath);
            newSourceName = "";
            newSourcePath = "";
            loadSettings();
        } catch (err) {
            alert("Failed to add source");
        }
    }

    async function scanSource(id: number) {
        isScanning = id;
        try {
            await apiClient.scanSource(id);
            alert("Scan complete");
        } catch (err) {
            alert("Scan failed");
        } finally {
            isScanning = null;
        }
    }

    onMount(() => {
        loadSettings();
    });
</script>

<Header title="Settings" />

<main class="fade-in mx-auto max-w-3xl px-6 pb-20 pt-8">
    <!-- Backend Configuration -->
    <section class="mb-12">
        <div class="mb-6 flex items-center gap-3 text-indigo-500">
            <Server size={24} />
            <h3 class="text-xl font-bold text-white">Backend Server</h3>
        </div>

        <div class="glass rounded-2xl p-6">
            <div class="flex flex-col gap-4 md:flex-row">
                <input
                    type="text"
                    bind:value={backendUrl}
                    placeholder="http://localhost:8000"
                    class="flex-1 rounded-xl bg-white/5 border border-white/10 px-4 py-3 text-lg outline-none focus:border-indigo-500/50"
                />
                <button
                    onclick={updateUrl}
                    class="rounded-xl bg-indigo-600 px-8 py-3 font-semibold transition-colors hover:bg-indigo-700"
                >
                    Update
                </button>
            </div>

            {#if health}
                <div class="mt-4 flex items-center gap-2 text-emerald-400">
                    <Activity size={16} />
                    <span class="text-sm"
                        >Server is online v{health.version || "1.0"}</span
                    >
                </div>
            {/if}
        </div>
    </section>

    <!-- Sources Management -->
    <section>
        <div class="mb-6 flex items-center gap-3 text-indigo-500">
            <Database size={24} />
            <h3 class="text-xl font-bold text-white">Manga Sources</h3>
        </div>

        <div class="flex flex-col gap-4">
            {#each sources as source}
                <div
                    class="glass flex items-center justify-between rounded-2xl p-6"
                >
                    <div>
                        <h4 class="text-lg font-bold">{source.name}</h4>
                        <p class="text-sm text-zinc-400">{source.path}</p>
                    </div>
                    <button
                        onclick={() => scanSource(source.id)}
                        disabled={isScanning === source.id}
                        class="flex h-12 w-12 items-center justify-center rounded-xl bg-indigo-600/10 text-indigo-500 transition-colors hover:bg-indigo-600/20 disabled:opacity-50"
                    >
                        <RefreshCcw
                            size={20}
                            class={isScanning === source.id
                                ? "animate-spin"
                                : ""}
                        />
                    </button>
                </div>
            {/each}

            <!-- Add New Source -->
            <div class="glass rounded-2xl p-6">
                <h4 class="mb-4 font-bold">Add Source</h4>
                <div class="flex flex-col gap-4">
                    <input
                        type="text"
                        bind:value={newSourceName}
                        placeholder="Source Name (e.g. My Comics)"
                        class="rounded-xl bg-white/5 border border-white/10 px-4 py-3 outline-none focus:border-indigo-500/50"
                    />
                    <input
                        type="text"
                        bind:value={newSourcePath}
                        placeholder="Full Path (e.g. D:\Comics)"
                        class="rounded-xl bg-white/5 border border-white/10 px-4 py-3 outline-none focus:border-indigo-500/50"
                    />
                    <button
                        onclick={addSource}
                        class="flex items-center justify-center gap-2 rounded-xl bg-white/10 px-8 py-3 font-bold transition-colors hover:bg-white/15"
                    >
                        <Plus size={20} />
                        Add Source
                    </button>
                </div>
            </div>
        </div>
    </section>
</main>
