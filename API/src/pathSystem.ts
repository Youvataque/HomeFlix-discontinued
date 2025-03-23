import chalk from "chalk";
import { calculateWordSimilarity, searchContent } from "./actions.js";
import { writeTheTime } from "./tools.js";
import { getContentDetails, moviePossHash, SeriePossHash } from "./torrentTools.js";
import { stat } from 'fs/promises';
import { SearchResult } from "./interfaces.js";

/////////////////////////////////////////////////////////////////////////////////
// Fonction pour retourner le hash le plus proche de celui cherché pour tout 
export async function contentBestHash(name: string, originalName: string, movie: boolean): Promise<SearchResult> {
	if (movie) {
		return await moviePossHash(name, originalName);
	} else {
		return await SeriePossHash(name, originalName);
	}
}

/////////////////////////////////////////////////////////////////////////////////
// Vérifie si un path mène à un fichier
export async function isFile(path: string): Promise<boolean> {
	try {
		const stats = await stat(path);
		return stats.isFile();
	} catch (error) {
		console.error(`Erreur lors de la vérification du fichier :`, error);
		return false;
	}
}

/////////////////////////////////////////////////////////////////////////////////
// Vérifie si un path mène à un dossier
export async function isDirectory(path: string): Promise<boolean> {
	try {
		const stats = await stat(path);
		return stats.isDirectory();
	} catch (error) {
		console.error(`Erreur lors de la vérification du dossier :`, error);
		return false;
	}
}

function goodName(name: string, originalName: string, possSel: string): string {
	const sim1 = calculateWordSimilarity(name, possSel);
	const sim2 = calculateWordSimilarity(originalName, possSel);
	if (sim1 > sim2)
		return name;
	else
		return originalName;

}

/////////////////////////////////////////////////////////////////////////////////
// Fonction pour fabriquer le path vers le fichier
export async function createAbsPath(name: string, originalName: string, movie: boolean): Promise<string> {
	const datas: SearchResult = await contentBestHash(name, originalName, movie);
	const details = await getContentDetails(datas.hash);
	const tempPath = details.save_path + '/' + details.name;
	if (await isFile(tempPath)) {
		return tempPath;
	} else if (await isDirectory(tempPath)) {
		
		return await searchContent(goodName(name, originalName, datas.name), movie, tempPath);
	} else {
		writeTheTime(chalk.red(`Erreur ! Aucun chemin d'accès trouvé pour ${name}`));
		return "";
	}
}