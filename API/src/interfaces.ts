/////////////////////////////////////////////////////////////////////////////////
// interfaces json watcher
export interface MediaItem {
	title: string;
	originalTitle: string;
	name: string;
	media: boolean;
	percent:number;
	seasons: Record<string, unknown>
}

export interface DataStructure {
	tv: Record<string, MediaItem>;
	movie: Record<string, MediaItem>;
	queue: Record<string, MediaItem>;
}

/////////////////////////////////////////////////////////////////////////////////
// interface spec watcher
export interface infoSpec {
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
export interface nameVpn {
	running: String,
	selected: String
}

/////////////////////////////////////////////////////////////////////////////////
// interface tools
export interface FileSystemItem {
    name: string;
    type: 'file' | 'directory';
}