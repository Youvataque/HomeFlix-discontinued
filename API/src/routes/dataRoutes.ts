import { Router, Request, Response } from 'express';
import fs from 'fs';
import dotenv from 'dotenv';
import { db, getActualTime, getMimeType, specDb, writeTheTime } from "../tools.js";
import authMiddleware from './authMiddleware.js';
import { DataStructure, manualDatas, SearchInfos } from '../interfaces.js';
import chalk from 'chalk';
import { createAbsPath, getContentPath } from '../pathSystem.js';
import { deleteAllTorrent, deleteOneTorrent, searchTorrent } from '../torrentTools.js';
import { removeFromJson } from '../actions.js';
import { writeGoodPath } from '../pathWriteSystem.js';

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
router.post('/contentStatus', authMiddleware, async (req: Request, res: Response) => {
	try {
		const { newData, where } = req.body;

		if (!where || !['queue', 'tv', 'movie'].includes(where)) {
			return res.status(400).json({ error: 'Clé invalide pour where' });
		}
		if (!newData || !newData.id) {
			return res.status(400).json({ error: "L'élément doit avoir un ID" });
		}

		const uid = req.user?.uid;
		if (!uid) {
			return res.status(401).json({ error: 'Utilisateur non identifié' });
		}

		db.read();
		db.data[where as keyof DataStructure][newData.id] = {
			"title": newData["title"],
			"originalTitle": newData["originalTitle"],
			"name": newData["name"],
			"media": newData["media"],
			"percent": newData["percent"],
			"path": "",
			"date": getActualTime(),
			"seasons": newData["seasons"],
			"user": uid,
		};
		db.write();

		res.status(201).json({ message: 'Données ajoutées avec succès' });
		writeTheTime(chalk.green(`Données ajoutées à la DB pour l'utilisateur ${uid}.`));
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
		del = await deleteOneTorrent(newData['path']);
	} else {
		del = await deleteAllTorrent(newData);
	}
	if (del) await removeFromJson(newData["media"] ? "movie" : "tv", newData["id"], db);
});

/////////////////////////////////////////////////////////////////////////////////
// Route pour rechercher la localisation d'un contenu
router.post('/manualUpdate', async (req: Request, res: Response) => {
	const body = req.body as manualDatas;
	const { id, movie } = body;	
	let found: boolean = false;
	try {
		db.read();
		const data = db.data;
		for (const key in movie ? data.movie : data.tv) {
			if (id == key) {
				found = true;
				if (movie) {
					data.movie[key]['path'] = "";
					data.movie[key] = await writeGoodPath(data.movie[key]);
				} else {
					for (const season in data.tv[key]['seasons']) {
						data.tv[key]['seasons'][season]['paths'] = {};
					}
					data.tv[key] = await writeGoodPath(data.tv[key]);
					console.log(data.tv[key]['paths']);
				}
				break ;
			}
		}
		db.data = data;
		db.write();
		if (!found) {
			writeTheTime(chalk.red("Mise à jour manuelle impossible, le contenue n'existe pas !"))
			return res.status(201).json({message : "Mise à jour manuelle impossible, le contenue n'existe pas !"})
		} {
			writeTheTime(chalk.green("Mise à jour manuelle terminé."))
			return res.status(201).json({message : "Mise à jour manuelle terminé."})
		}
	} catch (error) {
		writeTheTime(chalk.red(`Erreur lors de la recherche du contenu : ${error}`));
		res.status(500).json({ error: 'Une erreur est survenue lors de la recherche du contenu.' });
	}
});

/////////////////////////////////////////////////////////////////////////////////
// Route pour rechercher la localisation d'un contenu
router.post('/contentSearch',authMiddleware, async (req: Request, res: Response) => {
	const {id, movie, season, episode} = req.body;
	let path: string = "";
	const infos: SearchInfos = {
		id: id as string,
		movie: movie as boolean,
		season: season as number,
		episode: episode as number
	}
	try {
		db.read();
		const data = db.data;
		const section = infos.movie ? data.movie : data.tv;
		if (section && section[infos.id]) {
			path = getContentPath(infos, section[infos.id]);
			if (path != "Error") {
				writeTheTime(chalk.green(`Le path pour ${infos.id} a été trouvé : ${path}.`));
				return res.status(201).json({"path" : encodeURIComponent(path)});
			}
		}
		path = "Error";
		writeTheTime(chalk.red("Erreur dans la recherche de path, aucun contenue trouvé!"));
		res.status(404).json({"path" : path});
	} catch (error) {
		writeTheTime(chalk.red(`Erreur lors de la recherche du contenu : ${error}`));
		res.status(500).json({ error: 'Une erreur est survenue lors de la recherche du contenu.' });
	}
});

/////////////////////////////////////////////////////////////////////////////////
// Route pour lire une vidéo en streaming
router.get('/streamVideo', authMiddleware, (req, res) => {
	const videoPath = decodeURIComponent(req.query.path as string);

	if (!videoPath || typeof videoPath !== 'string') {
		return res.status(400).json({ message: 'Le chemin du fichier vidéo est requis.' });
	}

	fs.stat(videoPath, (err, stats) => {
		if (err) {
			writeTheTime(`Erreur lors de l'accès au fichier : ${err.message}`);
			return res.status(404).json({ message: 'Fichier non trouvé.' });
		}
		 if (!stats.isFile()) {
			writeTheTime(`Chemin non fichier (dir ?) : ${videoPath}`);
			return res.status(400).json({ message: 'Le chemin ne pointe pas vers un fichier.' });
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