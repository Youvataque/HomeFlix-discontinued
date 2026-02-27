import { Router, Request, Response } from 'express';
import dotenv from 'dotenv';
import authMiddleware from './authMiddleware.js';
import { fetchSourceFunc, fetchSrcUrl, writeTheTime, db, getActualTime, isMovie, extractParsedInfo } from '../tools.js';
import path from 'path';
import fs from 'fs';
import axios from 'axios';
import { fileURLToPath } from 'url';
import chalk from 'chalk';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();
const router: Router = Router();

/////////////////////////////////////////////////////////////////////////////////
// route pour récupérer la liste des contenu pour un nom et une page donnée
// depuis une source (server C en intermédiaire entre B et la source)
router.get('/fetchTorrentContent', authMiddleware, async (req: Request, res: Response) => {
	const name: string = req.query.name as string || "";
	const page: number = parseInt(req.query.page as string) || 1;

	const result = await fetchSourceFunc(page, name);
	res.json(result);
})

/////////////////////////////////////////////////////////////////////////////////
// Route pour récupérer le requète de téléchargement du content
router.post('/contentDl', authMiddleware, async (req: Request, res: Response) => {
	const { id, filename } = req.body;

	if (!id) {
		writeTheTime(chalk.red('L\'id du fichier est requise.'));
		return res.status(400).json({ message: 'L\'id du fichier est requise.' });
	}

	const urlData: Record<string, string> = await fetchSrcUrl(id);
	const downloadUrl = urlData['url'];

	if (!downloadUrl || downloadUrl === 'none') {
		writeTheTime(chalk.yellow(`Pas de lien de téléchargement trouvé pour l'id : ${id}`));
		return res.status(404).json({ message: 'Aucun lien de téléchargement disponible.' });
	}

	try {
		const response = await axios({
			method: 'GET',
			url: downloadUrl,
			responseType: 'stream',
			headers: {
				'Accept': '*/*',
				'User-Agent': 'Mozilla/5.0'
			},
			validateStatus: () => true
		});

		if (response.status !== 200) {
			writeTheTime(chalk.red(`Téléchargement refusé par la source (code ${response.status})`));
			return res.status(response.status).json({ message: 'Téléchargement refusé par la source distante.' });
		}

		let finalFilename = filename || 'downloaded_file.torrent';
		if (!filename) {
			const contentDisposition = response.headers['content-disposition'];
			if (contentDisposition) {
				const match = contentDisposition.match(/filename\*?=['"]?(.+?)['"]?$/);
				if (match) {
					finalFilename = decodeURIComponent(match[1]);
				}
			}
		}
		if (!finalFilename.endsWith('.torrent')) {
			finalFilename += '.torrent';
		}

		// Sanitize filename: replace path separators and invalid characters
		finalFilename = finalFilename.replace(/[/\\|<>:"?*]/g, '-').replace(/-{2,}/g, '-');

		const filePath = path.resolve(__dirname, process.env.TORRENT_FOLDER ?? "", finalFilename);
		const writer = fs.createWriteStream(filePath);

		response.data.pipe(writer);
		writer.on('finish', () => {
			writeTheTime(chalk.green('Fichier téléchargé avec succès.'));

			try {
				const info = extractParsedInfo(finalFilename);
				const isMediaMovie = isMovie(info.title);

				db.read();
				if (!db.data.queue[id]) {
					db.data.queue[id] = {
						title: info.title,
						originalTitle: info.title,
						name: info.title,
						media: isMediaMovie,
						percent: 0,
						path: "",
						date: getActualTime(),
						seasons: info.season ? { [info.season]: { paths: [] } } : {},
						user: req.user?.uid
					};
					db.write();
					writeTheTime(chalk.green(`Ajouté à la file d'attente DB : ${info.title}`));
				}
			} catch (dbErr) {
				writeTheTime(chalk.red(`Erreur ajout DB : ${dbErr}`));
			}

			return res.status(200).json({ message: 'Fichier téléchargé avec succès.' });
		});
		writer.on('error', (err) => {
			writeTheTime(chalk.red(`Erreur lors de l'écriture du fichier: ${err.message}`));
			return res.status(500).json({ message: 'Erreur lors de l\'écriture du fichier.' });
		});
	} catch (err) {
		writeTheTime(chalk.red(`Erreur lors de la requête HTTP: ${err}`));
		return res.status(500).json({ message: 'Erreur lors de la requête HTTP.' });
	}
});

export default router;