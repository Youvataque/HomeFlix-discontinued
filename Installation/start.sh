#!/bin/bash

# === CONFIGURATION ===
ROOT_PATH="$(cd "$(dirname "$0")" && pwd)"
TORRENT_PATH="$ROOT_PATH/tempTorrents"
CONTENT_PATH="$ROOT_PATH/medias"
CONTAINER_NAME="NightCenter"
IMAGE_NAME="img_center"

# === VÉRIF/INSTALL DOCKER ===
if ! command -v docker &> /dev/null; then
  echo "⚠️ Docker n'est pas installé."

  read -p "➡️ Installer Docker maintenant ? [y/N] " install_docker
  if [[ "$install_docker" =~ ^[Yy]$ ]]; then
    if grep -qi "ubuntu\|debian" /etc/os-release; then
      echo "➡️ Distribution basée sur Ubuntu/Debian détectée."
      sudo apt update
      sudo apt install -y docker.io
    elif grep -qi "arch\|manjaro" /etc/os-release; then
      echo "➡️ Distribution basée sur Arch/Manjaro détectée."
      sudo pacman -Sy --noconfirm docker
    else
      echo "❌ Distribution inconnue. Installe Docker manuellement."
      exit 1
    fi

    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    echo "✅ Docker installé et lancé. "Fais newgrp docker" puis refais "./start.sh"."
    exit 0
  else
    echo "❌ Docker est requis. Abandon."
    exit 1
  fi
fi

# === CHECK DOCKER DÉMON ===
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker n'est pas lancé. Exécute : sudo systemctl start docker"
  exit 1
fi

# === CRÉATION DES DOSSIERS SI ABSENTS ===
mkdir -p "$TORRENT_PATH"
mkdir -p "$CONTENT_PATH"

# === SUPPRESSION DU CONTENEUR EXISTANT ===
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
  echo "🧹 Suppression de l'ancien conteneur : $CONTAINER_NAME"
  docker stop "$CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME"
fi

# === BUILD DE L'IMAGE SI ABSENTE ===
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
  echo "🔧 Image '$IMAGE_NAME' non trouvée. Construction..."
  docker build -t "$IMAGE_NAME" "$ROOT_PATH"
else
  echo "✅ Image '$IMAGE_NAME' déjà présente."
fi

# === LANCEMENT DU CONTENEUR ===
echo "🚀 Lancement du conteneur '$CONTAINER_NAME'..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p 2222:22 \
  -p 8081:8080 \
  -p 5001:5000 \
  -v "$TORRENT_PATH":/root/tempTorrents \
  -v "$CONTENT_PATH":/root/medias \
  -e PASSKEY="votre_passkey" \
  -e SRC_GIT="votre code api de dl" \
  -e API_KEY="une clef de votre choix" \
  "$IMAGE_NAME"

# === STATUS ===
if [ $? -eq 0 ]; then
  echo "✅ Conteneur lancé avec succès."
  echo "➡️  SSH        : ssh root@localhost -p 2222"
  echo "➡️  Qbittorent WebUI      : http://localhost:8081"
  echo "➡️  API Node.js   : http://localhost:5001"
else
  echo "❌ Échec du lancement. Vérifie les logs avec : docker logs $CONTAINER_NAME"
fi
