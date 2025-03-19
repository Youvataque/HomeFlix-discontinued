import { Router, Request, Response, NextFunction } from 'express';
import fs from 'fs';
import dotenv from 'dotenv';
import { deleteAllTorrent, deleteOneTorrent, removeFromJson, searchContent, searchTorrent } from '../actions.js';
import { db, getMimeType, specDb, writeTheTime } from "../tools.js";
import authMiddleware from './authMiddleware.js';
import { DataStructure } from '../interfaces.js';
import chalk from 'chalk';

dotenv.config();
const router: Router = Router();

/////////////////////////////////////////////////////////////////////////////////
// Route pour récupérer des données de contenu
router.get('/contentStatus', authMiddleware,(req: Request, res: Response) => {
	try {
		db.read();
		res.json(db.data);
		writeTheTime(chalk.green(`Contenu de la db lue avec succès.`));
	} catch (err) {
		writeTheTime(chalk.red(`Erreur lors de la lecture de la DB : ${err}`));
		res.status(500).json({ error: 'Erreur interne du serveur' });
	}
});

/////////////////////////////////////////////////////////////////////////////////
// Route pour récupérer des données de spec
router.get('/specStatus', authMiddleware,(req: Request, res: Response) => {
	try {
		specDb.read();
		res.json(specDb.data);
	} catch (err) {
		writeTheTime(chalk.red(`Erreur lors de la lecture de la DB : ${err}`));
		res.status(500).json({ error: 'Erreur interne du serveur' });
	}
});

/////////////////////////////////////////////////////////////////////////////////
// Route pour ajouter des données
router.post('/contentStatus', authMiddleware, (req: Request, res: Response) => {
	try {
		const { newData, where } = req.body;

		if (!where || !['queue', 'tv', 'movie'].includes(where)) {
			return res.status(400).json({ error: 'Clé invalide pour where' });
		}
		if (!newData || !newData.id) {
			return res.status(400).json({ error: "L'élément doit avoir un ID" });
		}

		db.read();
		db.data[where as keyof DataStructure][newData.id] = {
			"title": newData["title"],
			"originalTitle": newData["originalTitle"],
			"name": newData["name"],
			"media": newData["media"],
			"percent": newData["percent"],
			"seasons": newData["seasons"]
		};
		db.write();
		res.status(201).json({ message: 'Données ajoutées avec succès' });
		writeTheTime(chalk.green(`Données ajoutées avec succès à la DB.`));
	} catch (err) {
		writeTheTime(chalk.red(`Erreur dans /contentStatus: ${err}`));
		res.status(500).json({ error: 'Erreur interne du serveur' });
	}
});

/////////////////////////////////////////////////////////////////////////////////
// Route pour supprimer une oeuvre
router.post('/contentErase', authMiddleware, async (req: Request, res: Response) => {
	const { newData } = req.body;
	let del = false;
	db.read();
	if (newData['media']) {
		const torrentHash = await searchTorrent(newData["name"]);
		del = await deleteOneTorrent(torrentHash);
	} else {
		del = await deleteAllTorrent(newData);
	}
	if (del) await removeFromJson(newData["media"] ? "movie" : "tv", newData["id"], db);
});

/////////////////////////////////////////////////////////////////////////////////
// Route pour rechercher la localisation d'un contenu
router.post('/contentSearch', authMiddleware, async (req: Request, res: Response) => {
	const { name, fileName, type } = req.body;

	if (!name || typeof name !== 'string') {
		return res.status(400).json({ error: 'Le nom et le type de contenu sont requis.' });
	}
	try {
		const contentPath = await searchContent(name, fileName, type);
		res.status(200).json({ path: contentPath });
	} catch (error) {
		writeTheTime(chalk.red(`Erreur lors de la recherche du contenu : ${error}`));
		res.status(500).json({ error: 'Une erreur est survenue lors de la recherche du contenu.' });
	}
});

/////////////////////////////////////////////////////////////////////////////////
// Route pour lire une vidéo en streaming
router.get('/streamVideo', authMiddleware, (req, res) => {
	const videoPath = req.query.path;

	if (!videoPath || typeof videoPath !== 'string') {
		return res.status(400).json({ message: 'Le chemin du fichier vidéo est requis.' });
	}

	fs.stat(videoPath, (err, stats) => {
		if (err) {
			writeTheTime(`Erreur lors de l'accès au fichier : ${err.message}`);
			return res.status(404).json({ message: 'Fichier non trouvé.' });
		}
		const fileSize = stats.size;
		const range = req.headers.range;
		if (!range) {
			const contentType = getMimeType(videoPath);
			res.writeHead(200, {
				'Content-Length': fileSize,
				'Content-Type': contentType,
			});
			fs.createReadStream(videoPath).pipe(res);
			return;
		}
		const parts = range.replace(/bytes=/, '').split('-');
		const start = parseInt(parts[0], 10);
		const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
		if (start >= fileSize || end >= fileSize) {
			res.status(416).header({
				'Content-Range': `bytes */${fileSize}`,
			});
			return res.end();
		}

		const contentLength = end - start + 1;
		const contentType = getMimeType(videoPath);
		const headers = {
			'Content-Range': `bytes ${start}-${end}/${fileSize}`,
			'Accept-Ranges': 'bytes',
			'Content-Length': contentLength,
			'Content-Type': contentType,
		};
		res.writeHead(206, headers);
		const videoStream = fs.createReadStream(videoPath, { start, end });
		videoStream.pipe(res);
	});
});

export default router;