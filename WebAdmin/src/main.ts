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
  <div id="edit-modal" class="fixed inset-0 bg-black/80 backdrop-blur-sm z-[100] hidden flex items-center justify-center opacity-0 transition-opacity duration-200">
    <div class="bg-surface border border-divider rounded-xl p-6 w-full max-w-lg shadow-2xl transform scale-95 transition-transform duration-200" id="modal-content">
        <h2 id="modal-title" class="text-xl font-bold text-white mb-6">Modifier</h2>
        <form id="edit-form" class="space-y-4">
            <input type="hidden" id="edit-id">
            <input type="hidden" id="edit-media-type">
            
            <div>
                <label class="block text-text-muted text-sm mb-1 font-medium">Nom</label>
                <input type="text" id="edit-name" class="w-full px-4 py-2 rounded-lg bg-background border border-divider text-white focus:outline-none focus:border-primary placeholder-text-muted/50 transition-colors">
            </div>
             <div>
                <label class="block text-text-muted text-sm mb-1 font-medium">Chemin du fichier</label>
                <input type="text" id="edit-path" class="w-full px-4 py-2 rounded-lg bg-background border border-divider text-white focus:outline-none focus:border-primary placeholder-text-muted/50 transition-colors">
            </div>
            
            <div id="season-container" class="hidden">
                 <label class="block text-text-muted text-sm mb-2 font-medium">Saisons (Cliquer pour supprimer)</label>
                 <div id="season-list" class="max-h-40 overflow-y-auto space-y-2 pr-2 custom-scrollbar">
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
const logoutBtn = document.getElementById('logout-btn')!;
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
      btn.classList.add('bg-primary/10', 'text-primary');
      btn.classList.remove('text-text-muted', 'hover:bg-white/5');
    } else {
      btn.classList.remove('bg-primary/10', 'text-primary');
      btn.classList.add('text-text-muted', 'hover:bg-white/5');
    }
  });
}

function renderContent() {
  contentGrid.innerHTML = '';

  if (!contentData) {
    contentGrid.innerHTML = `<div class="col-span-full text-center text-red-500 bg-red-500/10 p-4 rounded-lg">
            <p class="font-bold">Erreur de chargement des données</p>
            <p class="text-sm mt-2">${(window as any).lastError?.message || 'Erreur inconnue (Vérifiez la console)'}</p>
        </div>`;
    return;
  }

  const itemsMap = contentData[currentTab];
  // Convert Record<string, MediaItem> to Array and sort by date desc
  const items = Object.entries(itemsMap || {})
    .map(([id, item]) => ({ ...item, id })) // Ensure ID is part of object if not already
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

  if (items.length === 0) {
    emptyState.classList.remove('hidden');
    return;
  } else {
    emptyState.classList.add('hidden');
  }

  items.forEach(async (item) => {
    const card = document.createElement('div');
    card.className = 'group relative flex flex-col items-center cursor-pointer'; // Added cursor-pointer

    // Check if it's a downloading item
    const isDownloading = currentTab === 'queue';

    // Different click action based on tab
    if (!isDownloading) {
      card.onclick = () => {
        console.log("Card clicked:", item);
        openEditModal(item);
      };
    }

    // Placeholder skeleton
    const deleteButtonHtml = isDownloading ?
      `<button class="absolute top-2 right-2 z-10 p-1.5 bg-red-500 rounded-full hover:bg-red-600 transition-colors shadow-lg text-white" onclick="event.stopPropagation(); window.deleteDownloading('${item.id}')">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
        </button>` : '';

    const percentBadge = item.percent !== undefined ?
      `<div class="absolute bottom-2 right-2 px-2 py-1 bg-black/60 rounded text-xs text-white backdrop-blur-sm border border-white/10">
            ${item.percent}%
        </div>` : '';

    card.innerHTML = `
            <div class="w-full aspect-2/3 bg-surface rounded-lg shadow-lg overflow-hidden relative mb-3 ring-1 ring-white/5 group-hover:ring-primary/50 transition-all duration-300">
                <div class="absolute inset-0 flex items-center justify-center text-text-muted/20 animate-pulse">Loading...</div>
                <img id="img-${item.id}" class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105 opacity-0" />
                <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-60"></div>
                ${deleteButtonHtml}
                ${percentBadge}
            </div>
            <h3 class="text-text-main text-center text-sm font-medium w-full truncate px-2 group-hover:text-primary transition-colors">${item.title || item.name}</h3>
        `;
    contentGrid.appendChild(card);

    // Lazy load image from TMDB
    const isMovie = currentTab === 'movie' || (currentTab === 'queue' && (item.media === true || item.media === undefined && true)); // Default to movie if undefined in queue for image, or checking type

    const posterUrl = await TmdbService.getPosterPath(item.id, isMovie);

    const img = card.querySelector(`img#img-${item.id}`) as HTMLImageElement;
    if (img) {
      if (posterUrl) {
        img.src = posterUrl;
        img.onload = () => img.classList.remove('opacity-0');
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
  });
}

async function loadData() {
  try {
    contentData = await ApiService.fetchContentStatus();
    renderContent();
  } catch (e: any) {
    console.error("Error loading data:", e);
    (window as any).lastError = e;
    contentGrid.innerHTML = `<div class="col-span-full text-center text-red-500 bg-red-500/10 p-4 rounded-lg">
            <p class="font-bold">Erreur de chargement des données</p>
            <p class="text-sm mt-2">${e.message}</p>
        </div>`;
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
  } else {
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
  editPathInput.value = item.path || '';
  editIdInput.value = item.id;
  editMediaTypeInput.value = currentTab === 'movie' ? 'true' : 'false';

  // Handle Seasons if TV Show
  if (currentTab === 'tv' && item.seasons) {
    seasonContainer.classList.remove('hidden');
    seasonList.innerHTML = '';
    Object.keys(item.seasons).forEach(seasonKey => {
      const div = document.createElement('div');
      div.className = 'flex justify-between items-center p-2 bg-background rounded-lg border border-divider/50 hover:border-red-500/50 transition-colors group cursor-pointer';
      div.innerHTML = `
                <span class="text-sm text-text-main">Saison ${seasonKey}</span>
                <span class="text-xs text-red-500 opacity-0 group-hover:opacity-100 transition-opacity">Supprimer</span>
            `;
      div.onclick = () => deleteSeason(item.id, seasonKey);
      seasonList.appendChild(div);
    });
  } else {
    seasonContainer.classList.add('hidden');
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

async function deleteSeason(itemId: string, seasonKey: string) {
  if (!confirm(`Supprimer la Saison ${seasonKey} ?`)) return;
  try {
    await ApiService.editContent(itemId, false, 'removeSeason', { seasonKey });
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
