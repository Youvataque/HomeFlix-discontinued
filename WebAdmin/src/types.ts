export interface MediaItem {
    title: string;
    originalTitle: string;
    name: string;
    media: boolean;
    path: string;
    percent: number;
    date: string;
    seasons: Record<string, any>;
    user?: string;
    id: string; // Id key from Record
}

export interface DataStructure {
    tv: Record<string, MediaItem>;
    movie: Record<string, MediaItem>;
    queue: Record<string, MediaItem>;
}
