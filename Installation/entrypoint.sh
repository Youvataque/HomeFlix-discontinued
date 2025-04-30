#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

HOME_PATH="/root"
SRC_GIT="${SRC_GIT}"
echo "🔄 Mise à jour de l'API..."
echo "🔍 DEBUG - SRC_GIT: $SRC_GIT | API_KEY: $API_KEY | PASSKEY: $PASSKEY"
# === Vérification SRC_GIT ===
if [ -z "$SRC_GIT" ]; then
  echo "❌ La variable SRC_GIT n'est pas définie."
  exit 1
fi

# === Nettoyage ===
rm -rf "$HOME_PATH/API" "$HOME_PATH/SRCAPI" /tmp/temp

# === Clone des repositories ===
git clone --depth=1 https://github.com/Youvataque/HomeFlix.git /tmp/temp || {
  echo "❌ Échec du clonage du repo principal"
  exit 1
}
git clone --depth=1 "$SRC_GIT" /tmp/temp2/ || {
  echo "❌ Échec du clonage du repo secondaire (SRC_GIT)"
  exit 1
}

# === Déplacement de l'API dans le home ===
mkdir -p "$HOME_PATH/API"
mv /tmp/temp/API/* "$HOME_PATH/API" || true

mkdir -p "$HOME_PATH/SRCAPI"
mv /tmp/temp2/SRCAPI/* "$HOME_PATH/SRCAPI" || true

rm -rf /tmp/temp
rm -rf /tmp/temp2

# === .env principal ===
if [ ! -f "$HOME_PATH/API/.env" ]; then
  cat <<EOF > "$HOME_PATH/API/.env"
API_KEY="$API_KEY"
VPN_PASS="$VPN_PASS"
TORRENT_FOLDER="$HOME_PATH/tempTorrents"
CONTENT_FOLDER="$HOME_PATH/medias"
EOF
  echo "✅ Fichier .env principal généré."
fi

# === .env secondaire (SRCAPI) ===
if [ ! -f "$HOME_PATH/SRCAPI/.env" ]; then
  cat <<EOF > "$HOME_PATH/SRCAPI/.env"
PASSKEY="$PASSKEY"
EOF
  echo "✅ Fichier .env SRCAPI généré."
fi

# === qBittorrent config ===
echo "📁 Génération config qBittorrent..."
qbittorrent-nox --webui-port=8080 --daemon
sleep 3
pkill qbittorrent-nox || true

CONFIG_PATH="/root/.config/qBittorrent/qBittorrent.conf"
mkdir -p "$(dirname "$CONFIG_PATH")"

cat <<EOF > "$CONFIG_PATH"
[BitTorrent]
Session\CopyTorrentFiles=true
Session\CopyTorrentFilesPath=/root/tempTorrents
Session\DefaultSavePath=/root/medias
Session\Port=40730
Session\QueueingSystemEnabled=true
Session\TempPathEnabled=false

[Core]
AutoDeleteAddedTorrentFile=Never

[LegalNotice]
Accepted=true

[Preferences]
WebUI\AlternativeUIEnabled=false
WebUI\AuthSubnetWhitelist=@Invalid()
WebUI\AuthSubnetWhitelistEnabled=false
WebUI\BanDuration=3600
WebUI\BypassLocalAuth=true
WebUI\CSRFProtection=false
WebUI\ClickjackingProtection=true
WebUI\CustomHTTPHeadersEnabled=false
WebUI\Enabled=true
WebUI\HostHeaderValidation=false
WebUI\LocalHostAuth=false
WebUI\SessionTimeout=3600
WebUI\UseUPnP=true
WebUI\Username=Homeflix
EOF

# === Node modules ===
cd "$HOME_PATH/API"
npm install
npm audit fix || true

cd "$HOME_PATH/SRCAPI"
npm install
npm audit fix || true

# === SSH config ===
service ssh start

# === Lancement services ===
tmux new-session -d -s qbittorrent 'qbittorrent-nox --webui-port=8080'
tmux new-session -d -s homeflix 'cd /root/API && npm run dev'
tmux new-session -d -s srcApi 'cd /root/SRCAPI && npm run dev'


# === Conteneur actif ===
tail -f /dev/null