import axios from "axios";
import { exec } from "child_process";
import Levenshtein from "levenshtein";
import path from 'path';
import util from "util";
import dotenv from "dotenv";
import {cleanName, extractInfo, parseLsOutput, writeTheTime} from "./tools.js";
import { LowSync } from "lowdb";
import { DataStructure } from "./interfaces.js";
import chalk from "chalk";

dotenv.config();

/////////////////////////////////////////////////////////////////////////////////
// déclaration de l'api qbittorrent
export const qbittorrentAPI = axios.create({
	baseURL: 'http://localhost:8080/api/v2',
	timeout: 3700,
});

/////////////////////////////////////////////////////////////////////////////////
// fonction pour supprimer un torrent
export async function deleteOneTorrent(torrentHash: string): Promise<boolean> {
	try {
		if (torrentHash != "") {
			writeTheTime(chalk.yellow(`Trying to delete torrent with hash: ${torrentHash}`));
			await qbittorrentAPI.post('/torrents/delete',
				new URLSearchParams({
				  hashes: torrentHash,
				  deleteFiles: "true"
				}),
				{
				  headers: {
					'Content-Type': 'application/x-www-form-urlencoded'
				  }
				}
			  );
			writeTheTime(chalk.green(`${torrentHash} has been deleted with success.`));
			return true;
		}  else {
			writeTheTime(chalk.red('No torrent has been found!'));
			return false;
		}
	} catch (error) {
		writeTheTime(chalk.red(`Error during deleting: ${error}`));
		return false;
	}
}

/////////////////////////////////////////////////////////////////////////////////
// fonction pour supprimer chaques torrent d'une série
export async function deleteAllTorrent(newData: any) : Promise<boolean>{
	try {
		const seasons = newData['seasons'];
		for (const key in seasons) {
			if (seasons[key]["episode"].length == 1) {
				const torrentHash = await searchTorrent(seasons[key]["title"]);
				await deleteOneTorrent(torrentHash);
			} else {
				if (seasons[key]["episode"].length > 1) {
					const titles = seasons[key]["titles"];
					for (let x = 0; x < titles.length; x++) {
						const torrenthash = await searchTorrent(titles[x]);
						await deleteOneTorrent(torrenthash);
					}
				}
			}
		}
		return true;
	} catch (error) {
		writeTheTime(chalk.red(`An error has occurred: ${error}`));
		return false;
	}
}

/////////////////////////////////////////////////////////////////////////////////
// supprimer les données d'une oeuvre de l'api
export async function removeFromJson(where: keyof DataStructure, id: string, db: LowSync<DataStructure>): Promise<boolean> {
	try {
		db.read();
		if (!db.data[where] || typeof db.data[where] !== "object") {
			writeTheTime(chalk.red(`Erreur: ${where} n'est pas une section valide dans la base de données.`));
			return false;
		}
		if (db.data[where][id]) {
			delete db.data[where][id];
			db.write();
			writeTheTime(chalk.green(`${id} a été supprimé de ${where} avec succès.`));
			return true;
		} else {
			writeTheTime(chalk.red(`${id} introuvable dans ${where}.`));
			return false;
		}
	} catch (err) {
		writeTheTime(chalk.red(`Erreur lors de la suppression de ${id} dans ${where}: ${err}`));
		return false;
	}
}

/////////////////////////////////////////////////////////////////////////////////
// calclue la probabilité que le nom corresponde au torrent en cours
function calculateWordSimilarity(str1: string, str2: string): number {
	const distance = new Levenshtein(str1, str2);
	const maxLength = Math.max(str1.length, str2.length);
	return ((maxLength - distance.distance) / maxLength) * 100;
}

/////////////////////////////////////////////////////////////////////////////////
// Calcule la similarité entre deux noms avec pondération pour titre et métadonnées serie
function calculateContentSimilarity(name: string, comparedName: string): number {
	const targetInfo = extractInfo(name).split(" ");
	const comparedInfo = extractInfo(comparedName).split(" ");
	let matchScore = 0;
	let totalScore = 0;

	targetInfo.forEach((word, index) => {
		let weight = 1;
		if (index === 0) {
			weight = 5;
		}
		if (word.match(/^s\d{2}$/i)) {
			weight = 4;
		}
		if (word.match(/^e\d{2}$/i)) {
			weight = 3;
		}
		totalScore += weight;
		if (comparedInfo.includes(word)) {
			matchScore += weight;
		}
	});
	const titleSimilarity = calculateWordSimilarity(cleanName(name, true), cleanName(comparedName, true));
	const finalScore = (matchScore / totalScore) * 100;
	return 0.7 * finalScore + 0.3 * titleSimilarity;
}

/////////////////////////////////////////////////////////////////////////////////
// Calcule la similarité entre deux noms de séries
export function calculateSeriesSimilarity(name: string, comparedName: string): number {
	const targetInfo = name.split(" ");
	const comparedInfo = comparedName.split(" ");
	let score = 0;

	targetInfo.forEach((word, index) => {
		let weight = 1;
		if (index === 0) {
			weight = 3;
		}
		if (comparedInfo.includes(word)) {
			score += weight;
		}
	});
	const max = Math.max(targetInfo.length, comparedInfo.length);
	return (score / max) * 100;
}

/////////////////////////////////////////////////////////////////////////////////
// Calcule la similarité entre deux noms avec pondération pour titre et métadonnées (Films)
function calculateMovieSimilarity(name: string, comparedName: string): number {
    const targetInfo = extractInfo(name).split(" ");
    const comparedInfo = extractInfo(comparedName).split(" ");
    let matchScore = 0;
    let totalScore = 0;
    targetInfo.forEach((word, index) => {
        let weight = 1;
        if (index === 0) {
            weight = 15;
        }
        if (word.match(/^\d+$/)) {
            weight = 5;
        }
        totalScore += weight;
        if (comparedInfo.includes(word)) {
            matchScore += weight;
        } else {
            if (word.match(/^\d+$/)) {
                matchScore -= 12;
            }
            if (index === 0 && !comparedInfo.includes(word)) {
                matchScore -= 20;
            }
        }
    });
    comparedInfo.forEach((word) => {
        if (word.match(/^\d+$/) && !targetInfo.includes(word)) {
            matchScore -= 15;
        }
    });
    const titleSimilarity = calculateWordSimilarity(cleanName(name, true), cleanName(comparedName, true));
    const finalScore = Math.max(0, (matchScore / totalScore) * 100);
    return 0.85 * finalScore + 0.15 * titleSimilarity;
}

/////////////////////////////////////////////////////////////////////////////////
// recherche un torrent dans qbittorrent à partir d'un nom unique (nom d'archive)
export async function searchTorrent(name: string): Promise<string> {
	let probability = {
		percent: 70,
		content: ""
	};
	try {
		await qbittorrentAPI.post('/auth/login');
		const response = await qbittorrentAPI.get('/torrents/info');
		name = cleanName(name, true);
		response.data.forEach((torrent: { name: string, hash: string }) => {
			const torrentName = cleanName(torrent.name, true);
			const similarityPercentage = calculateContentSimilarity(name, torrentName);
			if (similarityPercentage > probability.percent) {
				probability.percent = similarityPercentage;
				probability.content = torrent.hash;
			}
		});
		writeTheTime(chalk.green(`The most comparable torrent is: "${probability.content}" with ${probability.percent}% of similarity.`));
	} catch (error) {
		writeTheTime(chalk.red(`Error during torrent search: ${error}`));
	}
	return probability.content;
}

const execAsync = util.promisify(exec);

/////////////////////////////////////////////////////////////////////////////////
// recherche un contenu à partir de son nom d'archive dans le serveur
export async function searchContent(name: string, fileName: string, movie: boolean): Promise<string> {
	const excludedExtensions = ["nfo", "txt", "jpg", "sfv"];
	let probability = { percent: 0, content: "", type: "" };
	let contentPath = process.env.CONTENT_FOLDER ?? ".";
	let count: number = 0;

	while (true) {
		const { stdout: lsOutput } = await execAsync(`ls -l "${contentPath}"`);
		const items = parseLsOutput(lsOutput);
		items.forEach(item => {
			const similarity = movie ?
					calculateMovieSimilarity(extractInfo(cleanName(count < 2 ? fileName : name, movie)), extractInfo(cleanName(item.name, movie)))
				:
					calculateSeriesSimilarity(cleanName(name, movie), extractInfo(cleanName(item.name, movie)));
			if (similarity > probability.percent && !excludedExtensions.includes(item.name.split(".").pop()?.toLowerCase() ?? "")) {
				probability = { percent: similarity, content: item.name, type: item.type };
				count++;
			}
		});
		if (probability.type === "directory") {
			contentPath = path.join(contentPath, probability.content);
			probability = { percent: 0, content: "", type: "" };
		} else if (probability.type === "file" || !items.some(item => item.type === "directory")) {
			break;
		}
	}
	return `${contentPath}/${probability.content}`;
}
