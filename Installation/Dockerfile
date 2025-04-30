FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# === 1. Installation des dépendances ===
RUN apt-get update && apt-get install -y \
  curl \
  gnupg \
  nano \
  ca-certificates \
  sudo \
  bash \
  git \
  openssh-server \
  iproute2 \
  tmux \
  ufw \
  qbittorrent-nox \
  lm-sensors \
  net-tools \
  iputils-ping \
  network-manager \
  python3 && \
  apt-get clean

# === 2. Node.js via NodeSource ===
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm && \
    apt-get clean

# === 3. Définir le mot de passe root ===
RUN echo "root:root" | chpasswd

# === 4. Configuration SSH ===
RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config

# === 5. Dossier de travail ===
WORKDIR /root

# === 6. Création des dossiers de données ===
RUN mkdir -p /root/tempTorrents /root/medias /root/.config/qBittorrent

# === 7. Ajout du script de démarrage ===
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# === 8. Ports exposés ===
EXPOSE 22 8080 5000

# === 9. Entrée ===
ENTRYPOINT ["/entrypoint.sh"]