#!/usr/bin/env bash
set -euo pipefail

# --- Variables (modifie ici si besoin) ---
USER_NAME="agathebonnet"
GROUP_NAME="agathebonnet"
SITE_DIR="/home/agathebonnet/site"
WEBHOOK_DIR="$SITE_DIR/webhooks"
HOOKS_FILE="$WEBHOOK_DIR/hooks.json"
GEN_SCRIPT="${SITE_DIR}/bash/generation/generation_site_test.sh"

SERVICE_NAME="webhook"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
ENV_FILE="/etc/default/webhook"

IP="0.0.0.0"
PORT="9000"
HOOK_ID="deploy-hugo"

# IMPORTANT: mets ton secret ici ou exporte WEBHOOK_SECRET avant d’exécuter le script
: "${WEBHOOK_SECRET:=f8wqogKR6GyE4nQsKzgv4VxgpTp9dt4T@kkEnX9xrAArVQ2}"

# --- Vérifs ---
if [[ $EUID -ne 0 ]]; then
  echo "❌ Ce script doit être lancé en root (ex: sudo ./script.sh)"
  exit 1
fi

if [[ ! -x "$GEN_SCRIPT" ]]; then
  echo "❌ Script de génération introuvable ou non exécutable: $GEN_SCRIPT"
  echo "   Fais: chmod +x \"$GEN_SCRIPT\""
  exit 1
fi

# --- Installation ---
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y webhook

# --- Dossiers ---
mkdir -p "$WEBHOOK_DIR"
chown -R "$USER_NAME:$GROUP_NAME" "$WEBHOOK_DIR"

# --- Fichier d'environnement (secret hors du hooks.json) ---
cat > "$ENV_FILE" <<EOF
WEBHOOK_SECRET=${WEBHOOK_SECRET}
EOF
chmod 640 "$ENV_FILE"
chown root:root "$ENV_FILE"

# --- hooks.json (JSON valide) ---
cat > "$HOOKS_FILE" <<'EOF'
[
  {
    "id": "__HOOK_ID__",
    "execute-command": "__GEN_SCRIPT__",
    "command-working-directory": "__SITE_DIR__",
    "response-message": "Déploiement Hugo lancé",
    "trigger-rule": {
      "match": {
        "type": "payload-hash-sha1",
        "secret": "${WEBHOOK_SECRET}",
        "parameter": {
          "source": "header",
          "name": "X-Hub-Signature"
        }
      }
    }
  }
]
EOF

# Remplacement des placeholders (sans casser les quotes du heredoc)
sed -i \
  -e "s|__HOOK_ID__|${HOOK_ID}|g" \
  -e "s|__GEN_SCRIPT__|${GEN_SCRIPT}|g" \
  -e "s|__SITE_DIR__|${SITE_DIR}|g" \
  "$HOOKS_FILE"

chown "$USER_NAME:$GROUP_NAME" "$HOOKS_FILE"
chmod 640 "$HOOKS_FILE"

# --- Service systemd ---
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Webhook listener
After=network.target

[Service]
Type=simple
User=${USER_NAME}
Group=${GROUP_NAME}

EnvironmentFile=${ENV_FILE}

ExecStart=/usr/bin/webhook -hooks ${HOOKS_FILE} -ip ${IP} -port ${PORT}

Restart=always
RestartSec=2

# Un minimum de durcissement
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${SITE_DIR}
LockPersonality=true
RestrictSUIDSGID=true

[Install]
WantedBy=multi-user.target
EOF

chmod 644 "$SERVICE_FILE"
chown root:root "$SERVICE_FILE"

# --- Activation ---
systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}"

echo "✅ Webhook installé et démarré."
echo "   Hooks: ${HOOKS_FILE}"
echo "   Service: systemctl status ${SERVICE_NAME}"
