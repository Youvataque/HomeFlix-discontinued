import { Router, Request, Response} from 'express';
import dotenv from 'dotenv';
import authMiddleware from './authMiddleware.js';
import { fetchSourceFunc, fetchSrcUrl } from '../tools.js';
import path from 'path';
import fs from 'fs';
import axios from 'axios';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();
const router: Router = Router();

/////////////////////////////////////////////////////////////////////////////////
// route pour récupérer la liste des contenu pour un nom et une page donnée
// depuis une source (server C en intermédiaire entre B et la source)
router.get('/fetchTorrentContent', authMiddleware, async (req: Request, res : Response) => {
	const name: string = req.query.name as string || "";
	const page: number = parseInt(req.query.page as string) || 1;

	const result = await fetchSourceFunc(page, name);
	res.json(result);
})

/////////////////////////////////////////////////////////////////////////////////
// Route pour récupérer le requète de téléchargement du content
router.post('/contentDl', authMiddleware, async (req: Request, res: Response) => {
	const { id, filename } = req.body; 

	if (!id) {
		return res.status(400).json({ message: 'L\'id du fichier est requise.' });
	}
	const urlData: Record<string, string> = await fetchSrcUrl(id);
	try {
		const response = await axios({
			method: 'GET',
			url: urlData['url'],
			responseType: 'stream'
		});

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

		const filePath = path.resolve(__dirname, process.env.TORRENT_FOLDER ?? "", finalFilename);
		const writer = fs.createWriteStream(filePath);

		response.data.pipe(writer);
		writer.on('finish', () => {
			return res.status(200).json({ message: 'Fichier téléchargé avec succès.' });
		});
		writer.on('error', (err) => {
			console.error(err);
			return res.status(500).json({ message: 'Erreur lors de l\'écriture du fichier.' });
		});
	} catch (error) {
		return res.status(500).json({ message: 'Erreur lors de la requête HTTP.' });
	}
});


export default router;