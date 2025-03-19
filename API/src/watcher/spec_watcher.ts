import { exec } from 'child_process';
import axios from 'axios';
import { infoSpec, SpecItem } from '../interfaces.js';
import { specDb } from '../tools.js';

/////////////////////////////////////////////////////////////////////////////////
// récupère les informations système de l'ordinateur pour les afficher dans l'app
function getSystemInfo(): Promise<infoSpec> {
	return new Promise((resolve, reject) => {
		exec('sensors', (error, stdout, stderr) => {
			if (error) {
				console.error(`\x1b[31mErreur: ${error.message}\x1b[0m`);
				reject(error);
				return;
			}
			if (stderr) {
				console.error(`\x1b[31mErreur: ${stderr}\x1b[0m`);
				reject(stderr);
				return;
			}
			const cpuMatch = stdout.match(/Package id 0:\s+\+([\d.]+)°C/);
			const cpu = cpuMatch ? cpuMatch[1] : 'Aucune information sur la température du CPU trouvée.';
			const fanMatch = stdout.match(/Exhaust\s+:\s+(\d+)\sRPM/);
			const fanSpeed = fanMatch ? `${fanMatch[1]} RPM` : 'Aucune information sur les ventilateurs trouvée.';
			exec('free -m', (error, stdout) => {
				const ramMatch = stdout.match(/Mem:\s+(\d+)\s+(\d+)/);
				const ramUsage = ramMatch ? `${((parseInt(ramMatch[2]) / parseInt(ramMatch[1])) * 100).toFixed(2)}%` : 'Aucune information sur la RAM trouvée.';

				exec('df -h /dev/sdb1', (error, stdout, stderr) => {
					if (error) {
						console.error(`Erreur df: ${error.message}\x1b[0m`);
						resolve({ cpu, fan: fanSpeed, ram: ramUsage, storage: 'Erreur on stockage' });
						return;
					}
					if (stderr) {
						console.error(`Erreur df: ${stderr}\x1b[0m`);
						resolve({ cpu, fan: fanSpeed, ram: ramUsage, storage: 'Erreur on stockage' });
						return;
					}
					const lines = stdout.split('\n');
					const diskInfo = lines[1].split(/\s+/);
					const used = diskInfo[2]; 
					const total = diskInfo[1]; 
					const storage = `${used} / ${total}`;

					resolve({ cpu, fan: fanSpeed, ram: ramUsage, storage: storage });
				});
			});
		});
	});
}

/////////////////////////////////////////////////////////////////////////////////
// vérifie la présence d'une interface réseau vpn (tun0)
function checkVpnStatus(): Promise<boolean> {
	return new Promise((resolve) => {
		exec('ip link show', (error:any, stdout:string) => {
			if (error) {
				console.error(`\x1b[31mErreur: ${error.message}`);
				resolve(false);
				return;
			}
			resolve(stdout.includes('tun0'));
		});
	});
}

/////////////////////////////////////////////////////////////////////////////////
// récupère le débit actuel de dl sur qbittorrent
async function getQbittorrentStats(): Promise<string> {
	try {
		const response = await axios.get('http://localhost:8080/api/v2/transfer/info');
		const data = response.data;
		return `${(data.dl_info_speed / (1024 * 1024)).toFixed(2)}`
	} catch (error:any) {
		console.error(`\x1b[31mErreur qBittorrent: ${error.message}\x1b[0m`);
		return "no value";
	}
}

/////////////////////////////////////////////////////////////////////////////////
// récupère le nombre de personne qui visionnent un film
async function getNbUser(): Promise<string> {
	return new Promise((resolve) => {
		exec('netstat -tu | grep ESTABLISHED | grep NightCenter:ftp | grep -v 10.170.88.92.rev | cut -d: -f2 | sort | uniq | wc -l', (error:any, stdout:string) => {
			if (error) {
				console.error(`\x1b[31mErreur: ${error.message}\x1b[0m`);
				resolve("no value");
				return;
			}
			resolve(stdout);
		});
	});
}

/////////////////////////////////////////////////////////////////////////////////
// lances toutes les fonctions précédente et enregistre leurs résultats dans une section du json
async function runAllChecks() {
	try {
		const systemInfo = await getSystemInfo();
		const jsonData: SpecItem = {
			cpu: systemInfo.cpu,
			fan: systemInfo.fan,
			ram: systemInfo.ram,
			storage: systemInfo.storage,
			vpnActive: await checkVpnStatus(),
			dlSpeed: await getQbittorrentStats(),
			nbUser: await getNbUser()
		};
		specDb.read();
		specDb.data = { spec: jsonData };
		specDb.write();
		console.log("\x1b[32mDonnées de performances mises à jour avec succès :\x1b[0m");
	} catch (err) {
		console.error(`\x1b[31mErreur lors de l'écriture du fichier JSON : ${err}\x1b[0m`);
	}
}

/////////////////////////////////////////////////////////////////////////////////
// lance le listener
export function startSpecWatcher(): void {
	setInterval(runAllChecks, 4000);
	console.log(`Surveillance des performances en cours !`);
}
  