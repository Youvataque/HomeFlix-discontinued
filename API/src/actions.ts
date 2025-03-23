import Levenshtein from "levenshtein";
import dotenv from "dotenv";
import {cleanName, extractInfo, writeTheTime} from "./tools.js";
import { LowSync } from "lowdb";
import { DataStructure } from "./interfaces.js";
import chalk from "chalk";

dotenv.config();

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
export function calculateWordSimilarity(str1: string, str2: string): number {
	const distance = new Levenshtein(str1, str2);
	const maxLength = Math.max(str1.length, str2.length);
	return ((maxLength - distance.distance) / maxLength) * 100;
}

/////////////////////////////////////////////////////////////////////////////////
// Calcule la similarité entre deux noms avec pondération pour titre et métadonnées serie
export function calculateContentSimilarity(name: string, comparedName: string): number {
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