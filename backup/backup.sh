#!/usr/bin/env bash
set -Eeuo pipefail

# ---------- Config ----------
BACKUP_FOLDER="/data/installation/backup"
PRESTA_SRC="/home/agathebonnet/prestashop"
SITE_SRC="/home/agathebonnet/site"

BACKUP_PRESTA="${BACKUP_FOLDER}/prestashop"
BACKUP_SITE="${BACKUP_FOLDER}/site"
BACKUP_LOG="${BACKUP_FOLDER}/log"

# Rotation "jour de semaine" (1..7). Tu peux remplacer par date +%F si tu veux.
DOW="$(date +%u)"
LOG="${BACKUP_LOG}/backup.${DOW}.log"

DB_NAME="prestashop_db"
DB_FILE="${BACKUP_PRESTA}/prestashop_db.${DOW}.sql"
PRESTA_TAR="${BACKUP_PRESTA}/prestashop.${DOW}.tar.gz"
SITE_TAR="${BACKUP_SITE}/site.${DOW}.tar.gz"

FTP_HOST="dedibackup-dc3.online.net"
FTP_USER="sd-150025"
FTP_PASS='bJt6qbFWN%xDL&4'   # ⚠️ mieux: .netrc (voir plus bas)

MAIL_FROM="no-reply@lherbefollefleuriste.com"
MAIL_TO="grie.paul@gmail.com, lherbefolle.fleuriste@gmail.com"
MAIL_SUBJECT="PROBLEME BACKUP SITE ($(hostname -s))"

# ---------- Préparation dossiers ----------
mkdir -p "$BACKUP_PRESTA" "$BACKUP_SITE" "$BACKUP_LOG"

# ---------- Logging (tout le script) ----------
exec > >(awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >>"$LOG") 2>&1

echo "=== Début backup ==="
echo "Log: $LOG"

# ---------- Helpers ----------
ERROR=0

on_error() {
  local exit_code=$?
  local line_no=$1
  echo "ERREUR: ligne ${line_no} (exit=${exit_code})"
  ERROR=1
}
trap 'on_error $LINENO' ERR

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Commande manquante: $1"; exit 1; }
}

ftp_mirror() {
  local local_dir=$1
  local remote_dir=$2

  echo "Upload FTP: $local_dir -> $remote_dir"
  lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" <<EOF
set ftp:passive-mode on
set net:max-retries 2
set net:timeout 30
set xfer:clobber on
mirror -R --verbose "$local_dir" "$remote_dir"
bye
EOF
}

send_alert_mail() {
  {
    echo "From: $MAIL_FROM"
    echo "To: $MAIL_TO"
    echo "Subject: $MAIL_SUBJECT"
    echo
    echo "Le backup a rencontré une erreur."
    echo "Serveur: $(hostname -f 2>/dev/null || hostname)"
    echo "Date: $(date -Is)"
    echo
    echo "---- Log ----"
    cat "$LOG"
  } | sendmail -t
}

# ---------- Prérequis ----------
need_cmd mysqldump
need_cmd tar
need_cmd lftp
need_cmd sendmail

# ---------- Dump DB ----------
echo "Dump DB: $DB_NAME -> $DB_FILE"
mysqldump "$DB_NAME" > "$DB_FILE"

# ---------- Archive PrestaShop ----------
echo "Archive PrestaShop: $PRESTA_SRC -> $PRESTA_TAR"
tar -czf "$PRESTA_TAR" -C "$(dirname "$PRESTA_SRC")" "$(basename "$PRESTA_SRC")"

# ---------- Upload Presta ----------
ftp_mirror "$BACKUP_PRESTA" "/prestashop"

# ---------- Archive Site ----------
echo "Archive Site: $SITE_SRC -> $SITE_TAR"
tar -czf "$SITE_TAR" -C "$(dirname "$SITE_SRC")" "$(basename "$SITE_SRC")"

# ---------- Upload Site ----------
ftp_mirror "$BACKUP_SITE" "/site"

# ---------- Upload Logs ----------
ftp_mirror "$BACKUP_LOG" "/log"

echo "=== Fin backup (ERROR=$ERROR) ==="

# ---------- Alerte mail si erreur ----------
if [[ "$ERROR" -ne 0 ]]; then
  send_alert_mail
fi

exit "$ERROR"
