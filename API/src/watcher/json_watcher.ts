import dotenv from 'dotenv';
import { qbittorrentAPI, removeFromJson, searchTorrent } from '../actions.js';
import { DataStructure } from '../interfaces.js';
import { db } from '../tools.js';

dotenv.config();
const DIRECTORY_TO_WATCH = process.env.CONTENT_FOLDER ?? "";

/////////////////////////////////////////////////////////////////////////////////
// fonction pour récupérer toutes les infos d'un torrent
async function getTorrentProgress(torrentName: string,): Promise<number | undefined> {
	try {
		const torrentHash = await searchTorrent(torrentName);
		if (torrentHash == "")
			return undefined;
		await qbittorrentAPI.post('/auth/login');
		const response = await qbittorrentAPI.get(`/torrents/properties`, {
			params: { hash: torrentHash }
		});
		if (response.data) {
			console.log(`\x1b[0mTorrent trouvé : ${response.data}\x1b[0m`);
			return parseFloat((response.data.total_downloaded * 100 / response.data.total_size).toFixed(2));
		} else {
			console.error(`\x1b[31mTorrent "${torrentName}" non trouvé.\x1b[0m`);
		}
	} catch (error) {
		console.error(`\x1b[31mErreur lors de la récupération de l\'état du torrent : ${error}\x1b[0m`);
	}
	return undefined; 
}

/////////////////////////////////////////////////////////////////////////////////
// fonction pour vérifer l'état des films dans la queu, l'enregistrer et déplacer si besoin les contenu  terminés
async function checkAndProcessQueue() {
	let countError: number = 0;
	try {
		db.read();
		const jsonData: DataStructure = db.data;
		if (Object.keys(jsonData.queue).length === 0) return;

		for (const key in jsonData.queue) {
			const item = jsonData.queue[key];
			const percent = await getTorrentProgress(item.name);
			if (percent !== undefined) {
				item.percent = percent;
				jsonData.queue[key].percent = percent;
			}
			else if (percent == undefined && countError !== 3) {
				countError++;
			} else {
				removeFromJson("queue", key, db);
			}
			if (item.percent >= 99.5) { 
				if (item.media) {
					jsonData.movie[key] = item;
				} else {
					jsonData.tv[key] = item;
				}
				delete jsonData.queue[key];
			} else {
				console.log(`\x1b[33mEncore du boulot : ${percent}\x1b[0m`);
			}
		}
		try {
			db.read();
			db.data = jsonData;
			db.write();
			console.log('\x1b[32mDB mise à jour avec succès\x1b[0m');
		} catch (err) {
			console.error(`\x1b[31mErreur lors de la mise à jour de la DB : ${err}\x1b[0m`);
		}
	} catch (err) {
		console.error(`\x1b[31mErreur lors de la lecture de la DB: ${err}\x1b[0m`);
	}
}

/////////////////////////////////////////////////////////////////////////////////
// lancement du listener
export function startJsonWatcher(): void {
	setInterval(checkAndProcessQueue, 4000);
	console.log(`Surveillance du dossier : ${DIRECTORY_TO_WATCH}`);
}
