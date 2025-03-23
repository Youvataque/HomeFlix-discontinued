import dotenv from 'dotenv';
import { DataStructure } from '../interfaces.js';
import { db, writeTheTime } from '../tools.js';
import chalk from 'chalk';
import { contentBestHash } from '../pathSystem.js';
import { qbittorrentAPI } from '../torrentTools.js';
import { removeFromJson } from '../actions.js';

dotenv.config();

/////////////////////////////////////////////////////////////////////////////////
// fonction pour récupérer toutes les infos d'un torrent
async function getTorrentProgress(name: string, originalName: string, movie: boolean): Promise<number | undefined> {
	try {
		const torrentHash = (await contentBestHash(name, originalName, movie)).hash;
		if (torrentHash == "")
			return undefined;
		await qbittorrentAPI.post('/auth/login');
		const response = await qbittorrentAPI.get(`/torrents/properties`, {
			params: { hash: torrentHash }
		});
		if (response.data) {
			writeTheTime(chalk.green(`Torrent trouvé : ${response.data}`));
			return parseFloat((response.data.total_downloaded * 100 / response.data.total_size).toFixed(2));
		} else {
			writeTheTime(chalk.red(`Torrent "${name}" non trouvé.`));
		}
	} catch (error) {
		writeTheTime(chalk.red(`Erreur lors de la récupération de l'état du torrent : ${error}`));
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
			const percent = await getTorrentProgress(item.title, item.originalTitle, item.media);
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
				writeTheTime(chalk.yellow(`Encore du boulot : ${percent}`));
			}
		}
		try {
			db.read();
			db.data = jsonData;
			db.write();
			writeTheTime(chalk.green('DB mise à jour avec succès'));
		} catch (err) {
			writeTheTime(chalk.red(`Erreur lors de la mise à jour de la DB : ${err}`));
		}
	} catch (err) {
		writeTheTime(chalk.red(`Erreur lors de la lecture de la DB: ${err}`));
	}
}

/////////////////////////////////////////////////////////////////////////////////
// lancement du listener
export function startJsonWatcher(): void {
	setInterval(checkAndProcessQueue, 4000);
	writeTheTime(chalk.blue(`Surveillance de la base de donnée.`));
}
