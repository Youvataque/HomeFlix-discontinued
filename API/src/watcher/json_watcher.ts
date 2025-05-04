import dotenv from 'dotenv';
import { DataStructure } from '../interfaces.js';
import { db, writeTheTime } from '../tools.js';
import chalk from 'chalk';
import { contentBestHash } from '../pathSystem.js';
import { qbittorrentAPI } from '../torrentTools.js';
import { removeFromJson } from '../actions.js';
import { writeGoodPath } from '../pathWriteSystem.js';
import { setTimeout as sleep } from 'timers/promises';

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
	let countError = 0;
	const completedItems: { key: string; item: any; type: 'movie' | 'tv' }[] = [];

	try {
		db.read();
		const jsonData: DataStructure = db.data;

		for (const key in jsonData.queue) {
			const item = jsonData.queue[key];
			await sleep(2000);
			const percent = await getTorrentProgress(item.title, item.originalTitle, item.media);

			if (percent !== undefined) {
				item.percent = percent;
			} else if (++countError >= 3) {
				await removeFromJson("queue", key, db);
				continue;
			} else {
				continue;
			}
			if (item.percent >= 99) {
				delete jsonData.queue[key];
				completedItems.push({ key, item, type: item.media ? 'movie' : 'tv' });
			} else {
				writeTheTime(chalk.yellow(`Encore du boulot : ${percent}`));
			}
		}
		db.data = jsonData;
		db.write();
		writeTheTime(chalk.green('DB mise à jour avec succès'));
	} catch (err) {
		writeTheTime(chalk.red(`Erreur lors du traitement de la file : ${err}`));
		return;
	}
	for (const { key, item, type } of completedItems) {
		try {
			const newItem = await writeGoodPath(item);
			db.read();
			db.data[type][key] = newItem;
			db.write();
			writeTheTime(chalk.cyan(`Path ajouté avec succès pour ${key}`));
		} catch (err) {
			writeTheTime(chalk.red(`Erreur lors du traitement du path pour ${key} : ${err}`));
		}
	}
}

/////////////////////////////////////////////////////////////////////////////////
// lancement du listener
export function startJsonWatcher(): void {
	setInterval(checkAndProcessQueue, 4000);
	writeTheTime(chalk.blue(`Surveillance de la base de donnée.`));
}
