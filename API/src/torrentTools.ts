import chalk from "chalk";
import fs from 'fs/promises';
import { cleanName, extractInfo, writeTheTime } from "./tools.js";
import { ContentDetails, MovieCheck, SearchResult, SerieCheck } from "./interfaces.js";
import axios from "axios";
import { calculateContentSimilarity } from "./actions.js";

// déclaration de l'api qbittorrent
export const qbittorrentAPI = axios.create({
	baseURL: 'http://localhost:8080/api/v2',
	timeout: 3700,
});

/////////////////////////////////////////////////////////////////////////////////
// recherche un torrent dans qbittorrent à partir d'un nom unique (nom d'archive)
export async function searchTorrent(name: string): Promise<SearchResult> {
	const result: SearchResult = {
		hash: "",
		percent: 60,
		name : name
	};
	try {
		await qbittorrentAPI.post('/auth/login');
		const response = await qbittorrentAPI.get('/torrents/info');
		response.data.forEach((torrent: { name: string, hash: string }) => {
			const torrentName = extractInfo(cleanName(torrent.name, true));
			const similarityPercentage = calculateContentSimilarity(name, torrentName);
			if (similarityPercentage > result.percent) {
				result.percent = similarityPercentage;
				result.hash = torrent.hash;
			}
		});
	} catch (error) {
		writeTheTime(chalk.red(`Erreur lors de la recherche de torrent : ${error}`));
	}
	return result;
}

/////////////////////////////////////////////////////////////////////////////////
// Fonction qui retourne le hash du film le plus proche de celui recherché.
export async function moviePossHash(name: string, originalName: string): Promise<SearchResult> {
	const result: MovieCheck = {
		poss1 : await searchTorrent(extractInfo(cleanName(name, true))),
		poss2 : await searchTorrent(extractInfo(cleanName(originalName, true)))
	}
	const maxPoss: SearchResult = Object.values(result).reduce((best, current) => {
		return current.percent > best.percent ? current : best;
	});
	writeTheTime(chalk.green(`Le torrent le plus proche de : ${name} est : "${maxPoss.hash}" avec ${maxPoss.percent}%.`));
	return maxPoss;
}

/////////////////////////////////////////////////////////////////////////////////
// Fonction qui retourne le hash de le serie la plus proche de celle recherchée.
export async function SeriePossHash(name: string, originalName: string): Promise<SearchResult> {
	const all1: string = extractInfo(cleanName(name, false));
	const all2: string = extractInfo(cleanName(originalName, false));
	const result: SerieCheck = {
		poss1 :  await searchTorrent(all1),
		poss2 :  await searchTorrent(all1.replace(/e\d{2}\b/i, "").trim()),
		poss3 :  await searchTorrent(all1.replace(/\bs\d{2}\s?e\d{2}\b/gi, '').replace(/\s+/g, ' ').trim()),
		poss4 :  await searchTorrent(all2),
		poss5 :  await searchTorrent(all2.replace(/e\d{2}\b/i, "").trim()),
		poss6 :  await searchTorrent(all2.replace(/\bs\d{2}\s?e\d{2}\b/gi, '').replace(/\s+/g, ' ').trim()),
	}
	const maxPoss: SearchResult = Object.values(result).reduce((best, current) => {
		return current.percent > best.percent ? current : best;
	});
	writeTheTime(chalk.green(`Le torrent le plus proche de : ${name} est : "${maxPoss.hash}" avec ${maxPoss.percent}%.`));
	return maxPoss;
}

/////////////////////////////////////////////////////////////////////////////////
// Fonction pour récupérer tous les détails d'un hash donné
export async function getContentDetails(hash: string): Promise<ContentDetails> {
	try {
		const response = await axios.get(`http://localhost:8080/api/v2/torrents/info`);
		const allTorrents = response.data;

		const match = allTorrents.find((torrent: any) => torrent.hash.toLowerCase() === hash.toLowerCase());

		if (!match) {
			throw new Error(`Aucun torrent trouvé avec le hash : ${hash}`);
		}

		return {
			addition_date: match.addition_date,
			comment: match.comment,
			completion_date: match.completion_date,
			created_by: match.created_by,
			creation_date: match.creation_date,
			dl_limit: match.dl_limit,
			dl_speed: match.dl_speed,
			dl_speed_avg: match.dl_speed_avg,
			download_path: match.download_path,
			eta: match.eta,
			has_metadata: match.has_metadata,
			hash: match.hash,
			infohash_v1: match.infohash_v1,
			infohash_v2: match.infohash_v2,
			is_private: match.is_private,
			last_seen: match.last_seen,
			name: match.name,
			nb_connections: match.nb_connections,
			nb_connections_limit: match.nb_connections_limit,
			peers: match.peers,
			peers_total: match.peers_total,
			piece_size: match.piece_size,
			pieces_have: match.pieces_have,
			pieces_num: match.pieces_num,
			popularity: match.popularity,
			private: match.private,
			reannounce: match.reannounce,
			save_path: match.save_path,
			seeding_time: match.seeding_time,
			seeds: match.seeds,
			seeds_total: match.seeds_total,
			share_ratio: match.share_ratio,
			time_elapsed: match.time_elapsed,
			total_downloaded: match.total_downloaded,
			total_downloaded_session: match.total_downloaded_session,
			total_size: match.total_size,
			total_uploaded: match.total_uploaded,
			total_uploaded_session: match.total_uploaded_session,
			total_wasted: match.total_wasted,
			up_limit: match.up_limit,
			up_speed: match.up_speed,
			up_speed_avg: match.up_speed_avg
		};
	} catch (error) {
		console.error(`Erreur dans contentDetails:`, error);
		throw error;
	}
}

/////////////////////////////////////////////////////////////////////////////////
// fonction pour supprimer un torrent
export async function deleteOneTorrent(path: string): Promise<boolean> {
	try {
		if (!path) {
			writeTheTime(chalk.red("No path provided!"));
			return false;
		}
		await fs.access(path);
		writeTheTime(chalk.yellow(`Trying to delete torrent with path: ${path}`));
		await fs.unlink(path);
		writeTheTime(chalk.green(`${path} has been deleted successfully.`));
		return true;
	} catch (error: any) {
		if (error.code === 'ENOENT') {
			writeTheTime(chalk.red(`File does not exist: ${path}`));
		} else {
			writeTheTime(chalk.red(`Error while deleting ${path}: ${error.message || error}`));
		}
		return false;
	}
}

/////////////////////////////////////////////////////////////////////////////////
// fonction pour supprimer chaques torrent d'une série
export async function deleteAllTorrent(newData: any): Promise<boolean> {
	try {
		const seasons = newData['seasons'];

		for (const seasonKey in seasons) {
			const season = seasons[seasonKey];
			for (let i = 0; i < season['size']; i++) {
				const success = await deleteOneTorrent(season['paths'][i]);
				if (!success) {
					writeTheTime(chalk.red(`Failed to delete: ${season['paths'][i]}`));
				}
			}
		}
		return true;
	} catch (error) {
		writeTheTime(chalk.red(`An error has occurred: ${error}`));
		return false;
	}
}
