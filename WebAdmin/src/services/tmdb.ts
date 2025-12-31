import { CONFIG } from '../config';

export const TmdbService = {
    async getPosterPath(id: string, isMovie: boolean): Promise<string | null> {
        try {
            // TMDB ID is usually numeric, but our system might use strings.
            const url = `https://api.themoviedb.org/3/${isMovie ? 'movie' : 'tv'}/${id}?api_key=${CONFIG.TMDB_KEY}`;
            const response = await fetch(url);

            if (!response.ok) return null;

            const data = await response.json();
            if (data.poster_path) {
                return `${CONFIG.TMDB_IMAGE_BASE}${data.poster_path}`;
            }
            return null;
        } catch (error) {
            console.warn(`Failed to fetch TMDB image for ${id}:`, error);
            return null;
        }
    },

    /**
     * For items in 'queue' which are search results, they might not have a direct TMDB ID relationship 
     * exactly like downloaded content if the ID isn't stored. 
     * However, assuming 'id' in our DB corresponds to TMDB ID for Movies/TV.
     */
    getImageUrl(posterPath: string | null): string {
        if (!posterPath) return '/placeholder-image.png'; // Todo: Add placeholder
        return posterPath.startsWith('http') ? posterPath : `${CONFIG.TMDB_IMAGE_BASE}${posterPath}`;
    }
};
