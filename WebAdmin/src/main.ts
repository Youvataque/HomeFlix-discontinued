import './style.css'
import { authService } from './auth';
import { ApiService } from './services/api';
import { TmdbService } from './services/tmdb';
import type { DataStructure } from './types';

// State
let contentData: DataStructure | null = null;
let currentTab: 'movie' | 'tv' | 'queue' = 'movie';

// DOM Elements
const app = document.querySelector<HTMLDivElement>('#app')!;

// Initial Layout
app.innerHTML = `
  <div id="loader" class="flex justify-center items-center h-screen">
    <div class="animate-spin rounded-full h-32 w-32 border-t-2 border-b-2 border-primary"></div>
  </div>
  
  <div id="auth-container" style="display: none;" class="flex flex-col items-center justify-center min-h-screen bg-background text-primary p-4">
    <img src="/logo.png" alt="HomeFlix Logo" class="w-40 h-40 mb-10" />
    <div class="w-full max-w-xs space-y-6"> 
        <form id="login-form" class="space-y-5">
            <div>
                <input type="email" id="email" required 
                    class="w-full px-4 py-3 rounded-xl bg-background border border-text-main/50 text-primary placeholder-primary focus:outline-none focus:border-primary focus:ring-0 caret-surface transition-colors"
                    placeholder="Votre email">
            </div>
            <div>
                <input type="password" id="password" required 
                    class="w-full px-4 py-3 rounded-xl bg-background border border-text-main/50 text-primary placeholder-primary focus:outline-none focus:border-primary focus:ring-0 caret-surface transition-colors"
                    placeholder="Votre mot de passe">
            </div>
            <div id="error-message" class="text-red-500 text-sm h-5 text-center hidden"></div>
            
            <div class="flex justify-end">
                <button type="button" class="text-text-main text-sm hover:underline">Un oublie ?</button>
            </div>

            <button type="submit" 
                class="w-full bg-primary hover:bg-primary/90 text-surface font-bold py-3 px-4 rounded-xl transition duration-200 mt-8">
                Se connecter
            </button>
        </form>
    </div>
  </div>

  <!-- Edit Modal -->
  <div id="edit-modal" class="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 hidden flex items-center justify-center opacity-0 transition-opacity duration-200">
    <div class="bg-surface border border-divider rounded-xl p-6 w-full max-w-lg shadow-2xl transform scale-95 transition-transform duration-200" id="modal-content">
        <h2 id="modal-title" class="text-xl font-bold text-text-main mb-6">Modifier</h2>
        <form id="edit-form" class="space-y-4">
            <input type="hidden" id="edit-id">
            <input type="hidden" id="edit-media-type">
            
            <div>
                <label class="block text-text-muted text-sm mb-1 font-medium">Nom</label>
                <input type="text" id="edit-name" class="w-full px-4 py-2 rounded-lg bg-background border border-divider text-text-main focus:outline-none focus:border-primary placeholder-text-muted/50 transition-colors">
            </div>
             <div>
                <label class="block text-text-muted text-sm mb-1 font-medium">Chemin du fichier</label>
                <input type="text" id="edit-path" class="w-full px-4 py-2 rounded-lg bg-background border border-divider text-text-main focus:outline-none focus:border-primary placeholder-text-muted/50 transition-colors">
            </div>
            
            <div id="season-container" class="hidden">
                 <label class="block text-text-muted text-sm mb-2 font-medium">Saisons (Cliquer pour supprimer)</label>
                 <div id="season-list" class="max-h-60 overflow-y-auto space-y-2 pr-2 custom-scrollbar">
                    <!-- Season items injected here -->
                 </div>
            </div>

            <div class="flex justify-between items-center pt-6 border-t border-divider mt-6">
                 <button type="button" id="delete-btn" class="px-4 py-2 bg-red-500/10 text-red-500 hover:bg-red-500/20 rounded-lg transition-colors text-sm font-medium">Supprimer Tout</button>
                 <div class="flex space-x-3">
                    <button type="button" id="cancel-btn" class="px-4 py-2 text-text-muted hover:text-white transition-colors text-sm font-medium">Annuler</button>
                    <button type="submit" class="px-6 py-2 bg-primary text-surface font-bold rounded-lg hover:bg-primary/90 transition-colors text-sm">Sauvegarder</button>
                 </div>
            </div>
        </form>
    </div>
  </div>

  <div id="dashboard" style="display: none;" class="min-h-screen bg-background">
    <nav class="bg-surface/80 backdrop-blur-md border-b border-divider px-6 py-4 flex justify-between items-center sticky top-0 z-50 transition-all duration-300">
        <div class="flex items-center space-x-4">
             <img src="/logo.png" alt="Logo" class="w-10 h-10" />
             <h1 class="text-xl font-bold text-primary hidden md:block">HomeFlix Admin</h1>
        </div>
        
        <div class="flex space-x-2">
            <button class="tab-btn px-4 py-2 rounded-lg text-sm font-medium transition-colors text-text-muted hover:text-text-main hover:bg-white/5" data-tab="movie">Films</button>
            <button class="tab-btn px-4 py-2 rounded-lg text-sm font-medium transition-colors text-text-muted hover:text-text-main hover:bg-white/5" data-tab="tv">Séries</button>
            <button class="tab-btn px-4 py-2 rounded-lg text-sm font-medium transition-colors text-text-muted hover:text-text-main hover:bg-white/5" data-tab="queue">Téléchargements</button>
        </div>

        <button id="logout-btn" class="text-text-muted hover:text-white transition-colors text-sm">Déconnexion</button>
    </nav>
    <main class="p-4 md:p-8">
        <div id="content-grid" class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-6">
            <!-- Content Injected Here -->
        </div>
        <div id="empty-state" class="hidden text-center mt-20">
            <p class="text-text-muted text-xl">Aucun contenu trouvé.</p>
        </div>
    </main>
  </div>
`;

// Elements References
const loader = document.getElementById('loader')!;
const authContainer = document.getElementById('auth-container')!;
const dashboard = document.getElementById('dashboard')!;
const loginForm = document.getElementById('login-form') as HTMLFormElement;
const errorMessage = document.getElementById('error-message')!;
// const logoutBtn = document.getElementById('logout-btn')!; // Defined below at 116, this block was messed up.
// Let's clean this block entirely.
const logoutBtn = document.getElementById('logout-btn')!; // Re-adding this as it is actually used in the event listener I previously removed but should have kept? Wait.
// I removed the duplicate listener in step 519. The original listener was at line 220.
// Let's check where the listener is now.
// In the current file content (step 553), the listener is absent?
// No, looking at step 553 content, I see:
// 293: logoutBtn.addEventListener('click', () => { ... })
// So it IS used. Why did TS fail?
// Ah, allow me to re-read the error.
// "src/main.ts:115:7 - error TS6133: 'logoutBtn' is declared but its value is never read."
// This implies the usage at line 293 might have been lost or I'm misreading the file state.
// Let's re-read the file to be 100% sure before editing.

const contentGrid = document.getElementById('content-grid')!;
const emptyState = document.getElementById('empty-state')!;
const tabButtons = document.querySelectorAll('.tab-btn');

// Modal Elements
const editModal = document.getElementById('edit-modal')!;
const modalContent = document.getElementById('modal-content')!;
const editForm = document.getElementById('edit-form') as HTMLFormElement;
const editTitle = document.getElementById('modal-title')!;
const editNameInput = document.getElementById('edit-name') as HTMLInputElement;
const editPathInput = document.getElementById('edit-path') as HTMLInputElement;
const editIdInput = document.getElementById('edit-id') as HTMLInputElement;
const editMediaTypeInput = document.getElementById('edit-media-type') as HTMLInputElement;
const seasonContainer = document.getElementById('season-container')!;
const seasonList = document.getElementById('season-list')!;
const deleteBtn = document.getElementById('delete-btn')!;
const cancelBtn = document.getElementById('cancel-btn')!;

// --- Functions ---

function updateTabs() {
  tabButtons.forEach(btn => {
    const tab = (btn as HTMLElement).dataset.tab;
    if (tab === currentTab) {
      btn.classList.add('bg-primary/10', 'text-primary', 'border-primary', 'border');
      btn.classList.remove('text-text-muted', 'hover:bg-white/5', 'border-transparent');
    } else {
      btn.classList.remove('bg-primary/10', 'text-primary', 'border-primary', 'border');
      btn.classList.add('text-text-muted', 'hover:bg-white/5', 'border-transparent');
    }
  });
}

function createCard(item: any): HTMLDivElement {
  const card = document.createElement('div');
  card.className = 'group relative flex flex-col items-center cursor-pointer';
  card.dataset.id = item.id;

  const isDownloading = currentTab === 'queue';

  if (!isDownloading) {
    card.onclick = () => {
      openEditModal(item);
    };
  }

  card.innerHTML = getCardInnerHtml(item, isDownloading);

  loadCardImage(card, item);

  return card;
}

function getCardInnerHtml(item: any, isDownloading: boolean): string {
  const deleteButtonHtml = isDownloading ?
    `<button class="absolute top-2 right-2 z-10 p-1.5 bg-red-500 rounded-full hover:bg-red-600 transition-colors shadow-lg text-white" onclick="event.stopPropagation(); window.deleteDownloading('${item.id}')">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
        </button>` : '';

  const percentBadge = item.percent !== undefined ?
    `<div class="absolute bottom-2 right-2 px-2 py-1 bg-black/60 rounded text-xs text-white backdrop-blur-sm border border-white/10" id="badge-${item.id}">
            ${item.percent}%
        </div>` : '';

  return `
            <div class="w-full aspect-2/3 bg-surface rounded-lg shadow-lg overflow-hidden relative mb-3 ring-1 ring-white/5 group-hover:ring-primary/50 transition-all duration-300">
                <div class="absolute inset-0 flex items-center justify-center text-text-muted/20 animate-pulse skeleton">Loading...</div>
                <img id="img-${item.id}" class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105 opacity-0" />
                <div class="absolute inset-0 bg-linear-to-t from-black/80 via-transparent to-transparent opacity-60"></div>
                ${deleteButtonHtml}
                ${percentBadge}
            </div>
            <h3 class="text-text-main text-center text-sm font-medium w-full truncate px-2 group-hover:text-primary transition-colors" id="title-${item.id}">${item.title || item.name}</h3>
        `;
}

function updateCard(card: HTMLDivElement, item: any) {
  const titleEl = card.querySelector(`#title-${item.id}`);
  if (titleEl && titleEl.textContent !== (item.title || item.name)) {
    titleEl.textContent = item.title || item.name;
  }

  if (item.percent !== undefined) {
    const badge = card.querySelector(`#badge-${item.id}`);
    if (badge) {
      badge.textContent = `${item.percent}%`;
    }
  }
}

async function loadCardImage(card: HTMLDivElement, item: any) {
  const isMovie = currentTab === 'movie' || (currentTab === 'queue' && (item.media === true || item.media === undefined && true));
  const posterUrl = await TmdbService.getPosterPath(item.id, isMovie);
  const img = card.querySelector(`img#img-${item.id}`) as HTMLImageElement;
  if (img) {
    if (posterUrl) {
      img.src = posterUrl;
      img.onload = () => {
        img.classList.remove('opacity-0');
        const skel = card.querySelector('.skeleton');
        if (skel) skel.remove();
      };
    } else {
      img.parentElement!.classList.add('bg-surface');
      const fallback = document.createElement('div');
      fallback.className = 'absolute inset-0 flex flex-col items-center justify-center text-text-muted p-4 text-center';
      fallback.innerHTML = `
            <svg class="w-10 h-10 mb-2 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
            <span class="text-xs">No Image</span>`;
      img.replaceWith(fallback);
    }
  }
}

function renderContent() {
  if (!contentData) {
    contentGrid.innerHTML = `<div class="col-span-full text-center text-red-500 bg-red-500/10 p-4 rounded-lg">
            <p class="font-bold">Erreur de chargement des données</p>
            <p class="text-sm mt-2">${(window as any).lastError?.message || 'Erreur inconnue (Vérifiez la console)'}</p>
        </div>`;
    return;
  }

  const itemsMap = contentData[currentTab];
  const items = Object.entries(itemsMap || {})
    .map(([id, item]) => ({ ...item, id }))
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

  if (items.length === 0) {
    emptyState.classList.remove('hidden');
    contentGrid.innerHTML = '';
    return;
  } else {
    emptyState.classList.add('hidden');
  }

  const existingNodes = new Map<string, HTMLDivElement>();
  Array.from(contentGrid.children).forEach(child => {
    if (child instanceof HTMLDivElement && child.dataset.id) {
      existingNodes.set(child.dataset.id, child);
    } else {
      child.remove();
    }
  });

  items.forEach(item => {
    let card = existingNodes.get(item.id);
    if (card) {
      updateCard(card, item);
      existingNodes.delete(item.id);
    } else {
      card = createCard(item);
    }
    contentGrid.appendChild(card);
  });

  existingNodes.forEach(node => node.remove());
}

async function loadData() {
  try {
    contentData = await ApiService.fetchContentStatus();
    renderContent();
  } catch (e: any) {
    console.error("Error loading data:", e);
    if (!contentData) {
      (window as any).lastError = e;
      contentGrid.innerHTML = `<div class="col-span-full text-center text-red-500 bg-red-500/10 p-4 rounded-lg">
                <p class="font-bold">Erreur de chargement des données</p>
                <p class="text-sm mt-2">${e.message}</p>
            </div>`;
    }
  }
}

let refreshInterval: any = null;

function startAutoRefresh() {
  if (refreshInterval) clearInterval(refreshInterval);
  refreshInterval = setInterval(() => {
    loadData();
  }, 5000);
}

function stopAutoRefresh() {
  if (refreshInterval) {
    clearInterval(refreshInterval);
    refreshInterval = null;
  }
}


// --- Event Listeners ---

// Tabs
tabButtons.forEach(btn => {
  btn.addEventListener('click', (e) => {
    currentTab = ((e.currentTarget as HTMLElement).dataset.tab as 'movie' | 'tv' | 'queue');
    updateTabs();
    renderContent();
  });
});

// Auth Listener
authService.addListener(async (user) => {
  loader.style.display = 'none';
  if (user) {
    authContainer.style.display = 'none';
    dashboard.style.display = 'block';
    updateTabs();
    loadData(); // Fetch data on login
    startAutoRefresh(); // Start polling
  } else {
    stopAutoRefresh(); // Stop polling
    dashboard.style.display = 'none';
    authContainer.style.display = 'flex';
    contentData = null; // Clear data on logout
  }
});

// Login Handler
loginForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = (document.getElementById('email') as HTMLInputElement).value;
  const password = (document.getElementById('password') as HTMLInputElement).value;

  errorMessage.classList.add('hidden');
  errorMessage.textContent = '';

  try {
    await authService.login(email, password);
  } catch (error: any) {
    errorMessage.textContent = "Échec de l'authentification. Vérifiez vos identifiants.";
    errorMessage.classList.remove('hidden');
  }
});

// Logout Listener
logoutBtn.addEventListener('click', () => {
  authService.logout();
});

// --- Modal & Action Functions ---

function openEditModal(item: any) {
  console.log("Opening edit modal for:", item);
  editModal.classList.remove('hidden');
  // Small delay to allow display:block to apply before opacity transition
  setTimeout(() => {
    editModal.classList.remove('opacity-0');
    modalContent.classList.remove('scale-95');
    modalContent.classList.add('scale-100');
  }, 10);

  editTitle.textContent = `Modifier : ${item.title || item.name}`;
  editNameInput.value = item.name || item.title || '';
  editNameInput.classList.add('focus:border-primary', 'focus:ring-1', 'focus:ring-primary/50'); // Ensure focus style

  editPathInput.value = item.path || '';
  editPathInput.classList.remove('hidden'); // Default show
  (editPathInput.previousElementSibling as HTMLElement).classList.remove('hidden'); // Label

  editIdInput.value = item.id;
  editMediaTypeInput.value = currentTab === 'movie' ? 'true' : 'false';

  // Handle Seasons if TV Show
  if (currentTab === 'tv' && item.seasons) {
    seasonContainer.classList.remove('hidden');
    seasonList.innerHTML = '';

    // Hide global path input for Series as they use episode paths
    editPathInput.classList.add('hidden');
    (editPathInput.previousElementSibling as HTMLElement).classList.add('hidden');

    // Add Season UI
    const addSeasonDiv = document.createElement('div');
    addSeasonDiv.className = 'mb-4 border-b border-divider/30 pb-4';
    addSeasonDiv.innerHTML = `
        <button type="button" id="toggle-add-season-btn" class="text-sm text-primary font-medium hover:underline mb-2 flex items-center gap-1">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
            Ajouter une saison manuellement
        </button>
        <div id="add-season-form" class="hidden space-y-3 bg-surface/30 p-3 rounded-lg border border-divider">
            <div>
                <label class="block text-xs text-text-muted mb-1">Numéro de saison</label>
                <input type="number" id="new-season-num" class="w-full px-2 py-1.5 text-sm rounded bg-background border border-divider text-main focus:outline-none focus:border-primary placeholder-text-muted/30" placeholder="ex: 3">
            </div>
            <div>
                <label class="block text-xs text-text-muted mb-1">Chemin du dossier serveur</label>
                <input type="text" id="new-season-path" class="w-full px-2 py-1.5 text-sm rounded bg-background border border-divider text-main focus:outline-none focus:border-primary placeholder-text-muted/30" placeholder="/mnt/series/ma_serie/saison_3">
            </div>
            <button type="button" id="submit-add-season" class="w-full py-1.5 bg-primary/20 text-primary hover:bg-primary/30 rounded font-medium text-sm transition-colors">Scanner et Ajouter</button>
        </div>
    `;
    seasonList.prepend(addSeasonDiv);

    const toggleBtn = addSeasonDiv.querySelector('#toggle-add-season-btn') as HTMLButtonElement;
    const formDiv = addSeasonDiv.querySelector('#add-season-form') as HTMLDivElement;
    const submitBtn = addSeasonDiv.querySelector('#submit-add-season') as HTMLButtonElement;
    const numInput = addSeasonDiv.querySelector('#new-season-num') as HTMLInputElement;
    const pathInput = addSeasonDiv.querySelector('#new-season-path') as HTMLInputElement;

    toggleBtn.onclick = () => formDiv.classList.toggle('hidden');

    submitBtn.onclick = async () => {
      const num = parseInt(numInput.value);
      const path = pathInput.value.trim();
      if (!num || !path) {
        alert('Veuillez remplir le numéro et le chemin.');
        return;
      }
      await addSeason(item.id, num, path);
    };

    Object.keys(item.seasons).sort().forEach(seasonKey => {
      const seasonData = item.seasons[seasonKey];
      const paths = seasonData.paths || []; // array of strings

      const seasonDiv = document.createElement('div');
      seasonDiv.className = 'mb-2 rounded-lg border border-divider/30 overflow-hidden';

      const header = document.createElement('div');
      header.className = 'p-3 bg-background flex justify-between items-center cursor-pointer hover:bg-white/5 transition-colors';
      header.innerHTML = `<span class="font-medium text-primary">Saison ${seasonKey.replace('S', '')}</span> <span class="text-xs text-text-muted">${paths.length} épisodes</span>`;

      const episodesDiv = document.createElement('div');
      episodesDiv.className = 'hidden p-3 space-y-3 bg-surface/50 border-t border-divider/30';

      // Toggle accordion
      header.onclick = () => episodesDiv.classList.toggle('hidden');

      // Add "Delete Season" button at top of season
      const deleteSeasonBtn = document.createElement('button');
      deleteSeasonBtn.type = 'button';
      deleteSeasonBtn.className = 'w-full py-1.5 mb-3 text-xs text-red-500 bg-red-500/10 hover:bg-red-500/20 rounded border border-red-500/20 transition-colors';
      deleteSeasonBtn.innerText = `Supprimer toute la Saison ${seasonKey.replace('S', '')}`;
      deleteSeasonBtn.onclick = (e) => { e.stopPropagation(); deleteSeason(item.id, seasonKey); };
      episodesDiv.appendChild(deleteSeasonBtn);

      // List Episodes
      if (Array.isArray(paths)) {
        paths.forEach((pathVal: string, index: number) => {
          const epRow = document.createElement('div');
          epRow.className = 'flex gap-2 items-center';

          const label = document.createElement('span');
          label.className = 'text-xs text-text-muted w-8 shrink-0';
          label.innerText = `Ep ${index + 1}`;

          const input = document.createElement('input');
          input.type = 'text';
          input.value = pathVal;
          input.className = 'flex-1 min-w-0 px-2 py-1.5 text-sm rounded bg-background border border-divider text-main focus:outline-none focus:border-primary placeholder-text-muted/30 transition-colors';

          const saveBtn = document.createElement('button');
          saveBtn.type = 'button';
          saveBtn.innerHTML = `<svg class="w-4 h-4 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>`;
          saveBtn.className = 'p-1.5 hover:bg-primary/10 rounded transition-colors';
          saveBtn.title = 'Sauvegarder le chemin';
          saveBtn.onclick = () => updateEpisode(item.id, seasonKey.replace('S', ''), index + 1, input.value);

          const delEpBtn = document.createElement('button');
          delEpBtn.type = 'button';
          delEpBtn.innerHTML = `<svg class="w-4 h-4 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>`;
          delEpBtn.className = 'p-1.5 hover:bg-red-500/10 rounded transition-colors';
          delEpBtn.title = 'Supprimer l\'épisode';
          delEpBtn.onclick = () => deleteEpisode(item.id, seasonKey.replace('S', ''), index + 1);

          epRow.append(label, input, saveBtn, delEpBtn);
          episodesDiv.appendChild(epRow);
        });
      }

      seasonDiv.append(header, episodesDiv);
      seasonList.appendChild(seasonDiv);
    });
  } else {
    seasonContainer.classList.add('hidden');
    editPathInput.classList.remove('hidden');
    (editPathInput.previousElementSibling as HTMLElement).classList.remove('hidden');
  }
}

function closeEditModal() {
  editModal.classList.add('opacity-0');
  modalContent.classList.remove('scale-100');
  modalContent.classList.add('scale-95');
  setTimeout(() => {
    editModal.classList.add('hidden');
  }, 200);
}

// Global function for delete button in Queue
(window as any).deleteDownloading = async (id: string) => {
  if (!confirm('Voulez-vous vraiment annuler ce téléchargement ?')) return;
  try {
    await ApiService.deleteDownloading(id);
    await loadData(); // Reload data
  } catch (e: any) {
    alert(e.message);
  }
};

async function addSeason(itemId: string, seasonNum: number, folderPath: string) {
  try {
    const res = await ApiService.editContent(itemId, false, 'addSeason', {
      seasonNumber: seasonNum,
      folderPath: folderPath
    });
    alert(res.message);
    closeEditModal();
    await loadData();
  } catch (e: any) {
    alert(e.message);
  }
}

async function deleteSeason(itemId: string, seasonKey: string) {
  if (!confirm(`Supprimer la Saison ${seasonKey} ?`)) return;
  try {
    await ApiService.editContent(itemId, false, 'removeSeason', { seasonKey });
    // Don't close modal, just reload data and re-render modal content? 
    // For simplicity, close and reload
    closeEditModal();
    await loadData();
  } catch (e: any) {
    alert(e.message);
  }
}

async function updateEpisode(itemId: string, seasonNum: string, episodeNum: number, newPath: string) {
  try {
    await ApiService.editContent(itemId, false, 'updateEpisodePath', {
      season: parseInt(seasonNum),
      episode: episodeNum,
      newPath
    });
    // Feedback visual?
    alert('Chemin mis à jour !');
  } catch (e: any) {
    alert(e.message);
  }
}

async function deleteEpisode(itemId: string, seasonNum: string, episodeNum: number) {
  if (!confirm(`Supprimer l'épisode ${episodeNum} ?`)) return;
  try {
    await ApiService.editContent(itemId, false, 'removeEpisode', {
      season: parseInt(seasonNum),
      episode: episodeNum
    });
    closeEditModal();
    await loadData();
  } catch (e: any) {
    alert(e.message);
  }
}

// Modal Listeners
cancelBtn.onclick = closeEditModal;

editForm.onsubmit = async (e) => {
  e.preventDefault();
  const id = editIdInput.value;
  const isMovie = editMediaTypeInput.value === 'true';
  const newName = editNameInput.value;
  const newPath = editPathInput.value;

  try {
    // Update Name
    await ApiService.editContent(id, isMovie, 'updateName', { name: newName });
    // Update Path
    if (newPath) {
      await ApiService.editContent(id, isMovie, 'updatePath', { path: newPath });
    }
    closeEditModal();
    await loadData();
  } catch (e: any) {
    alert(e.message);
  }
};

deleteBtn.onclick = async () => {
  const id = editIdInput.value;
  const isMovie = editMediaTypeInput.value === 'true';
  if (!confirm('Voulez-vous vraiment supprimer tout ce contenu ? Cette action est irréversible.')) return;

  try {
    await ApiService.editContent(id, isMovie, 'deleteItem', {});
    closeEditModal();
    await loadData();
  } catch (e: any) {
    alert(e.message);
  }
};
