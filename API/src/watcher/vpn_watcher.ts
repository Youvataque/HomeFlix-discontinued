import { exec } from 'child_process';
import { randomInt } from 'crypto';
import dotenv from 'dotenv';
import { NameVpn } from '../interfaces.js';
import chalk from 'chalk';
import { writeTheTime } from '../tools.js';
dotenv.config();

/////////////////////////////////////////////////////////////////////////////////
// Recherche du serveur VPN actif et des serveurs disponibles
function searchServer(): Promise<NameVpn> {
    let result: NameVpn = {
        running: "",
        selected: "",
    };
    let possibilities: Array<String> = [];

    return new Promise((resolve) => {
        exec("nmcli connection", (error, stdout, stderr) => {
            if (error) {
                writeTheTime(chalk.red(`Erreur avec le gestionnaire réseau : ${error.message}`));
                writeTheTime(chalk.red(`Détail : ${stderr}`));
                resolve(result);
                return;
            }
            const lines = stdout.split("\n");
            for (const line of lines) {
                const splitLine = line.trim().split(/\s+/);
                if (splitLine[2] === "vpn" && splitLine[3] !== "--") {
                    result.running = splitLine[0];
                } else if (splitLine[2] === "vpn" && splitLine[3] === "--") {
                    possibilities.push(splitLine[0]);
                }
            }
            result.selected = possibilities[randomInt(possibilities.length)];
            if (!result.selected) {
                writeTheTime(chalk.red("Aucun serveur VPN n'est disponible."));
                resolve(result);
                return;
            }
            resolve(result);
        });
    });
}

/////////////////////////////////////////////////////////////////////////////////
// Vérifie si le VPN est actif en testant la connexion via ping
function checkIfRunning(): Promise<boolean> {
    return new Promise((resolve) => {
        exec("ping -I tun0 -c 2 google.com", (error, stdout, stderr) => {
            if (error) {
                writeTheTime(chalk.red(`Erreur avec le VPN : ${error.message}`));
                writeTheTime(chalk.red(`Détail : ${stderr}`));
                resolve(false);
                return;
            }
            const isConnected = stdout.includes('bytes from') || stdout.includes('octets de');
            if (!isConnected) {
                writeTheTime(chalk.yellow("Le VPN semble inactif."));
            }
            resolve(isConnected);
        });
    });
}

/////////////////////////////////////////////////////////////////////////////////
// Fonction principale de gestion du VPN
async function controlUpdateVpn() {
    const isRunning: boolean = await checkIfRunning();
    if (!isRunning) {
        const names: NameVpn = await searchServer();

        if (names.running) {
            writeTheTime(chalk.yellow(`Déconnexion du VPN actuel : ${names.running}`));
            exec(`nmcli connection down ${names.running}`, (error, stdout, stderr) => {
                if (error) {
                    writeTheTime(chalk.red(`Erreur de déconnexion : ${error.message}`));
                    writeTheTime(chalk.red(`Détail : ${stderr}`));
                } else {
                    writeTheTime(chalk.green(`Déconnecté de ${names.running}`));
                }
            });
        }

        writeTheTime(chalk.yellow(`Connexion au serveur VPN : ${names.selected}`));
        writeTheTime(`Mot de passe VPN : ${process.env.VPN_PASS}`);
        exec(`echo ${process.env.VPN_PASS} | nmcli connection up ${names.selected} --ask`, (error, stdout, stderr) => {
            if (error) {
                writeTheTime(chalk.red(`Erreur de connexion : ${error.message}`));
                writeTheTime(chalk.red(`Détail : ${stderr}`));
                return;
            }
            if (stdout.includes('connexion activée') || stdout.includes('Connection successfully activated')) {
                writeTheTime(chalk.green(`Connexion réussie à ${names.selected}.`));
            } else {
                writeTheTime(chalk.yellow(`La connexion à ${names.selected} n'a pas été confirmée.`));
            }
        });
    }
}

/////////////////////////////////////////////////////////////////////////////////
// Démarrage du watcher
export function startVpnWatcher(): void {
    setInterval(controlUpdateVpn, 20000);
    writeTheTime(chalk.blue(`Surveillance de l'état du VPN en cours.`));
}