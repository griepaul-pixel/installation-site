#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Variables
# -----------------------------
APP_USER="agathebonnet"
APP_GROUP="agathebonnet"

BASE_DIR="/data/oauth"
APP_DIR="${BASE_DIR}/netlify-cms-github-oauth-provider"

REPO_URL="https://github.com/vencax/netlify-cms-github-oauth-provider"
SERVICE_NAME="oauth-github"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

ENV_FILE="${APP_DIR}/.env"

# -----------------------------
# Pré-requis système
# -----------------------------
sudo apt-get update -y
sudo apt-get install -y git curl ca-certificates nodejs npm

# -----------------------------
# Dossiers
# -----------------------------
sudo mkdir -p "$BASE_DIR"
sudo chown -R "${APP_USER}:${APP_GROUP}" "$BASE_DIR"

# -----------------------------
# Clone ou mise à jour du repo
# -----------------------------
if [[ -d "${APP_DIR}/.git" ]]; then
  sudo -u "$APP_USER" git -C "$APP_DIR" pull --ff-only
else
  sudo -u "$APP_USER" git clone "$REPO_URL" "$APP_DIR"
fi

# -----------------------------
# Installation des dépendances
# -----------------------------
if [[ -f "${APP_DIR}/package-lock.json" ]]; then
  sudo -u "$APP_USER" npm ci --prefix "$APP_DIR"
else
  sudo -u "$APP_USER" npm install --prefix "$APP_DIR"
fi

# -----------------------------
# Création du fichier .env
# -----------------------------
cat <<EOF | sudo tee "$ENV_FILE" >/dev/null
NODE_ENV=production
ORIGINS=test.lherbefollefleuriste.com
OAUTH_CLIENT_ID=Ov23liRewlWBeVLXSTBY
OAUTH_CLIENT_SECRET=29ddc1cd2b4d96d96d0fefc2f3804ab0dda125ec
REDIRECT_URL=https://test.lherbefollefleuriste.com/callback
GIT_HOSTNAME=https://github.com
PORT=3000
EOF

sudo chown "${APP_USER}:${APP_GROUP}" "$ENV_FILE"
sudo chmod 600 "$ENV_FILE"

# -----------------------------
# Service systemd
# -----------------------------
cat <<EOF | sudo tee "$SERVICE_FILE" >/dev/null
[Unit]
Description=OAuth provider for Netlify CMS and GitHub
After=network.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
WorkingDirectory=${APP_DIR}

EnvironmentFile=${ENV_FILE}
ExecStart=/usr/bin/npm start

Restart=always
RestartSec=2

# Durcissement basique
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 "$SERVICE_FILE"
sudo chown root:root "$SERVICE_FILE"

# -----------------------------
# Activation du service
# -----------------------------
sudo systemctl daemon-reload
sudo systemctl enable --now "$SERVICE_NAME"

echo "✅ OAuth GitHub provider installé et démarré"
echo "   Status : sudo systemctl status ${SERVICE_NAME}"
echo "   Logs   : sudo journalctl -u ${SERVICE_NAME} -f"

