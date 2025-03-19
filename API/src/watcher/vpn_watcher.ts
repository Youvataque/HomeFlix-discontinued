import { exec } from 'child_process';
import { randomInt } from 'crypto';
import dotenv from 'dotenv';
import { nameVpn } from '../interfaces.js';
dotenv.config();

/////////////////////////////////////////////////////////////////////////////////
// Recherche du serveur VPN actif et des serveurs disponibles
function searchServer(): Promise<nameVpn> {
    let result: nameVpn = {
        running: "",
        selected: "",
    };
    let possibilities: Array<String> = [];

    return new Promise((resolve) => {
        exec("nmcli connection", (error, stdout, stderr) => {
            if (error) {
                console.error(`\x1b[31mErreur avec le gestionnaire réseau : ${error.message}\x1b[0m`);
                console.error(`\x1b[31mDétail : ${stderr}\x1b[0m`);
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
                console.error("\x1b[31mAucun serveur VPN n'est disponible.\x1b[0m");
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
                console.error(`\x1b[31mErreur avec le VPN : ${error.message}\x1b[0m`);
                console.error(`\x1b[31mDétail : ${stderr}\x1b[0m`);
                resolve(false);
                return;
            }
            const isConnected = stdout.includes('bytes from') || stdout.includes('octets de');
            if (!isConnected) {
                console.warn("\x1b[33mLe VPN semble inactif.\x1b[0m");
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
        const names: nameVpn = await searchServer();

        if (names.running) {
            console.log(`\x1b[33mDéconnexion du VPN actuel : ${names.running}\x1b[0m`);
            exec(`nmcli connection down ${names.running}`, (error, stdout, stderr) => {
                if (error) {
                    console.error(`\x1b[31mErreur de déconnexion : ${error.message}\x1b[0m`);
                    console.error(`\x1b[31mDétail : ${stderr}\x1b[0m`);
                } else {
                    console.log(`\x1b[32mDéconnecté de ${names.running}\x1b[0m`);
                }
            });
        }

        console.log(`\x1b[33mConnexion au serveur VPN : ${names.selected}\x1b[0m`);
            console.log("Mot de passe VPN :", process.env.VPN_PASS);
        exec(`echo ${process.env.VPN_PASS} | nmcli connection up ${names.selected} --ask`, (error, stdout, stderr) => {
            if (error) {
                console.error(`\x1b[31mErreur de connexion : ${error.message}\x1b[0m`);
                console.error(`\x1b[31mDétail : ${stderr}\x1b[0m`);
                return;
            }
            if (stdout.includes('connexion activée') || stdout.includes('Connection successfully activated')) {
                console.log(`\x1b[32mConnexion réussie à ${names.selected}.\x1b[0m`);
            } else {
                console.warn(`\x1b[33mLa connexion à ${names.selected} n'a pas été confirmée.\x1b[0m`);
            }
        });
    }
}

/////////////////////////////////////////////////////////////////////////////////
// Démarrage du watcher
export function startVpnWatcher(): void {
    setInterval(controlUpdateVpn, 20000);
    console.log(`\x1b[34mSurveillance de l'état du VPN en cours...\x1b[0m`);
}