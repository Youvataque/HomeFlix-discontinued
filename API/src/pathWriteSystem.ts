import chalk from "chalk";
import { MediaItem } from "./interfaces.js";
import { createAbsPath } from "./pathSystem.js";
import { formatEpCode, formatSeasCode, writeTheTime } from "./tools.js";
import { time } from "console";

/////////////////////////////////////////////////////////////////////////////////
// Fonction pour savoir si l'on a besoin d'un "path" ou autre chose.
export async function pathOrPaths(datas: Record<string, any>, name: string, originalName: string): Promise<Record<string, any>> {
	for (const key in datas) {
		const item = datas[key] as Record<string, any>;
		const ep: number[] = item['episode'] as number[];
		const size: number = item['size'] as number;

		if (!Array.isArray(item['paths'])) {
			item['paths'] = [];
		}
		if (item['complete'] && ep[0] === -1) {
			for (let x = 0; x < size; x++) {
				if (!item['paths'][x] || item['paths'][x].trim() === "") {
					const nName = name + " " + formatSeasCode(key) + formatEpCode(x + 1);
					const nOname = originalName + " " + formatSeasCode(key) + formatEpCode(x + 1);
					item['paths'][x] = await createAbsPath(nName, nOname, false);
				}
			}
		}
		else if (ep.length !== 0 && ep[0] !== -1) {
			for (let x = 0; x < ep.length; x++) {
				if (!item['paths'][x] || item['paths'][x].trim() === "") {
					const nName = name + " " + formatSeasCode(key) + formatEpCode(ep[x]);
					const nOname = originalName + " " + formatSeasCode(key) + formatEpCode(ep[x]);
					item['paths'][x] = await createAbsPath(nName, nOname, false);
				}
			}
		}
	}
	return datas;
}

/////////////////////////////////////////////////////////////////////////////////
// Fonction de régulation du createAbsPath
export async function writeGoodPath(datas: MediaItem): Promise<MediaItem> {
	if (datas.media) {
		if (!datas.title)
			datas.title = "";
		if (!datas.originalTitle)
				datas.originalTitle = "";
		datas.path = await createAbsPath(datas.title, datas.originalTitle, datas.media);
		writeTheTime(chalk.green(`Le path pour le film : "${datas.title}" a bien été ajouté.`));
	} else {
		datas.seasons = await pathOrPaths(datas.seasons, datas.title, datas.originalTitle);
		writeTheTime(chalk.green(`Les paths pour la série : "${datas.title}" ont bien été ajoutés.`));
	}
	return datas;
}