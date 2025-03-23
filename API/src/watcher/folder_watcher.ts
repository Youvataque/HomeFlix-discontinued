import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import FormData from 'form-data';
import chalk from 'chalk';
import { writeTheTime } from '../tools.js';
import { qbittorrentAPI } from '../torrentTools.js';

dotenv.config();
const DIRECTORY_TO_WATCH = process.env.TORRENT_FOLDER ?? "";

/////////////////////////////////////////////////////////////////////////////////
// Fonction pour ouvrir le fichier après l'écriture complète
function openFileWhenComplete(filepath: string): void {
	let lastSize = -1;

	const checkFileComplete = setInterval(() => {
		const currentSize = fs.statSync(filepath).size;

		if (currentSize === lastSize) {
			clearInterval(checkFileComplete);
			writeTheTime(chalk.green(`Fichier complet : ${filepath}`));

			const formData = new FormData();
			formData.append('torrents', fs.createReadStream(filepath));
			qbittorrentAPI
				.post('/torrents/add', formData, {
					headers: formData.getHeaders(),
				})
				.then(() => {
					writeTheTime(chalk.green(`Torrent ajouté avec succès : ${path.basename(filepath)}`));
				})
				.catch((error) => {
					writeTheTime(chalk.red(`Erreur lors de l'ajout du torrent : ${error.response?.data || error.message}`));
				});
		} else {
			lastSize = currentSize;
		}
	}, 1000);
}

/////////////////////////////////////////////////////////////////////////////////
// Fonction pour commencer à surveiller le dossier
export function startFolderWatcher(): void {
	fs.watch(DIRECTORY_TO_WATCH, (eventType, filename) => {
		if (eventType === 'rename' && filename) {
			const filepath = path.join(DIRECTORY_TO_WATCH, filename);

			if (fs.existsSync(filepath) && !fs.lstatSync(filepath).isDirectory()) {
				writeTheTime(`Fichier détecté : ${filepath}`);
				openFileWhenComplete(filepath);
			}
		}
	});
    writeTheTime(chalk.blue(`Surveillance du dossier -> ${DIRECTORY_TO_WATCH}`));
}