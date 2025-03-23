import chalk from "chalk";
import { calculateContentSimilarity, calculateWordSimilarity } from "./actions.js";
import { cleanName, extractInfo, parseLsOutput, writeTheTime } from "./tools.js";
import { getContentDetails, moviePossHash, SeriePossHash } from "./torrentTools.js";
import { stat } from 'fs/promises';
import { SearchResult } from "./interfaces.js";
import path from "path";
import { exec } from "child_process";
import util from "util";

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

/////////////////////////////////////////////////////////////////////////////////
// Fonction servant à envoyer le bon nom à completePath
function goodName(name: string, originalName: string, possSel: string): string {
	const sim1 = calculateWordSimilarity(name, possSel);
	const sim2 = calculateWordSimilarity(originalName, possSel);
	if (sim1 > sim2) {
		return name;
	} else {
		return originalName;
	}
}

const execAsync = util.promisify(exec);
/////////////////////////////////////////////////////////////////////////////////
// Fonction servant à compléter la recherche de path si nécéssaire
export async function completePath(name: string, movie: boolean, tempPath:string): Promise<string> {
	const excludedExtensions = ["nfo", "txt", "jpg", "sfv"];
	let probability = { percent: 0, content: "", type: "" };
	let contentPath = tempPath;
	let count: number = 0;

	while (true) {
		const { stdout: lsOutput } = await execAsync(`ls -l "${contentPath}"`);
		const items = parseLsOutput(lsOutput);
		items.forEach(item => {
			const similarity = calculateContentSimilarity(cleanName(name, movie), cleanName(item.name, movie))
			console.log(chalk.yellow(`Test item : ${extractInfo(cleanName(item.name, movie))} percent : ${similarity}`));
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

/////////////////////////////////////////////////////////////////////////////////
// Fonction pour fabriquer le path vers le fichier
export async function createAbsPath(name: string, originalName: string, movie: boolean): Promise<string> {
	const datas: SearchResult = await contentBestHash(name, originalName, movie);
	const details = await getContentDetails(datas.hash);
	const tempPath = details.save_path + '/' + details.name;
	if (await isFile(tempPath)) {
		return tempPath;
	} else if (await isDirectory(tempPath)) {
		return await completePath(goodName(name, originalName, datas.name), movie, tempPath);
	} else {
		writeTheTime(chalk.red(`Erreur ! Aucun chemin d'accès trouvé pour ${name}`));
		return "";
	}
}