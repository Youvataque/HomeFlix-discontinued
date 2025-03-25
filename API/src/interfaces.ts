/////////////////////////////////////////////////////////////////////////////////
// interfaces json watcher
export interface MediaItem {
	title: string;
	originalTitle: string;
	name: string;
	media: boolean;
	path: string;
	percent:number;
	date: string;
	seasons: Record<string, any>
}

export interface DataStructure {
	tv: Record<string, MediaItem>;
	movie: Record<string, MediaItem>;
	queue: Record<string, MediaItem>;
}

/////////////////////////////////////////////////////////////////////////////////
// interface spec watcher
export interface InfoSpec {
	cpu: string, 
	fan: string,
	ram: string,
	storage: string
}

export interface SpecItem {
	cpu:string,
	fan:string,
	ram: string,
	storage: string
	dlSpeed:string,
	vpnActive: boolean,
	nbUser: string
}

/////////////////////////////////////////////////////////////////////////////////
// interface vpn watcher
export interface NameVpn {
	running: String,
	selected: String
}

/////////////////////////////////////////////////////////////////////////////////
// interface actions
export interface SearchResult {
	hash: string;
	percent: number;
	name : string;
}

/////////////////////////////////////////////////////////////////////////////////
// interface tools
export interface FileSystemItem {
    name: string;
    type: 'file' | 'directory';
}

/////////////////////////////////////////////////////////////////////////////////
// interface torrents tools
export interface MovieCheck {
	poss1: SearchResult;
	poss2: SearchResult;
}

export interface SerieCheck {
	poss1: SearchResult;
	poss2: SearchResult;
	poss3: SearchResult;
	poss4: SearchResult;
	poss5: SearchResult;
	poss6: SearchResult;
}

export interface ContentDetails {
	addition_date: number;
	comment: string;
	completion_date: number;
	created_by: string;
	creation_date: number;
	dl_limit: number;
	dl_speed: number;
	dl_speed_avg: number;
	download_path: string;
	eta: number;
	has_metadata: boolean;
	hash: string;
	infohash_v1: string;
	infohash_v2: string;
	is_private: boolean;
	last_seen: number;
	name: string;
	nb_connections: number;
	nb_connections_limit: number;
	peers: number;
	peers_total: number;
	piece_size: number;
	pieces_have: number;
	pieces_num: number;
	popularity: number;
	private: boolean;
	reannounce: number;
	save_path: string;
	seeding_time: number;
	seeds: number;
	seeds_total: number;
	share_ratio: number;
	time_elapsed: number;
	total_downloaded: number;
	total_downloaded_session: number;
	total_size: number;
	total_uploaded: number;
	total_uploaded_session: number;
	total_wasted: number;
	up_limit: number;
	up_speed: number;
	up_speed_avg: number;
}


/////////////////////////////////////////////////////////////////////////////////
// interface pathSystem

export interface SearchInfos {
	season: number;
	episode: number;
	id: string;
	movie: boolean;
}