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
    card.className = 'group relative flex flex-col items-center';

    // Placeholder skeleton
    card.innerHTML = `
            <div class="w-full aspect-[2/3] bg-surface rounded-lg shadow-lg overflow-hidden relative mb-2">
                <div class="absolute inset-0 flex items-center justify-center text-text-muted/20 animate-pulse">Loading...</div>
                <img id="img-${item.id}" class="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105 opacity-0" />
                <div class="absolute top-2 right-2 px-2 py-1 bg-black/60 rounded text-xs text-white backdrop-blur-sm">
                    ${item.percent}%
                </div>
            </div>
            <h3 class="text-text-main text-center text-sm font-medium w-full truncate px-1">${item.title || item.name}</h3>
        `;
    contentGrid.appendChild(card);

    // Lazy load image from TMDB
    const isMovie = currentTab === 'movie' || (currentTab === 'queue' && item.media); // Adjust logic if queue items have 'media' prop properly set

    // Queue items might not store media type boolean clearly in all cases, relying on 'media' prop from interface
    const posterUrl = await TmdbService.getPosterPath(item.id, isMovie);

    const img = card.querySelector(`img#img-${item.id}`) as HTMLImageElement;
    if (img) {
      if (posterUrl) {
        img.src = posterUrl;
        img.onload = () => img.classList.remove('opacity-0');
      } else {
        // Fallback or keep placeholder
        img.parentElement!.classList.add('bg-surface');
        (img.previousElementSibling as HTMLElement).innerText = 'No Image';
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

// Logout Handler
logoutBtn.addEventListener('click', () => {
  authService.logout();
});
