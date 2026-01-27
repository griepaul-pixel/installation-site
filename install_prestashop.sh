#!/bin/bash

# --- Configuration ---
# Le répertoire où vous voulez installer PrestaShop (par exemple, un nouveau dossier de site)
INSTALL_DIR="/data/prestashop"

# L'URL du fichier zip de la dernière version de PrestaShop (vérifiez la dernière version sur le site officiel)
#PRESTASHOP_URL="https://download.prestashop.com/download/releases/prestashop_edition_basic_version_9.0.1-1.0.zip"

# Nom du fichier téléchargé
DOWNLOAD_FILE="prestashop.zip"

# --- Exécution ---

echo "🚀 Début de l'installation simplifiée de PrestaShop..."
# 1. Créer le répertoire d'installation s'il n'existe pas
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Création du répertoire : $INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR"
else
    echo "Le répertoire $INSTALL_DIR existe déjà."
fi

# 2. Se déplacer dans le répertoire cible
cd "$INSTALL_DIR" || { echo "Erreur: Impossible d'entrer dans $INSTALL_DIR"; exit 1; }

# 3. Télécharger le fichier ZIP
echo "Téléchargement de PrestaShop depuis $PRESTASHOP_URL..."
#sudo wget -O "$DOWNLOAD_FILE" "$PRESTASHOP_URL"
mv ${INSTALL_DIR}/prestashop_edition_basic_version_9.0.1-1.0.zip ${INSTALL_DIR}/${DOWNLOAD_FILE}

# 4. Décompresser le fichier ZIP
echo "Décompression du fichier..."
cd ${INSTALL_DIR}
sudo unzip "$DOWNLOAD_FILE"

# 5. Le fichier téléchargé est souvent un zip qui contient un autre zip.
# On déplace le contenu du dossier 'prestashop' dans la racine.
if [ -d "prestashop" ]; then
    echo "Déplacement du contenu vers la racine du site..."
    sudo mv prestashop/* .
    sudo rm -r prestashop
fi

# 6. Supprimer le fichier ZIP téléchargé
echo "Nettoyage : suppression du fichier $DOWNLOAD_FILE"
sudo rm "$DOWNLOAD_FILE"

# 7. Définir les permissions de base (ATTENTION : peut varier selon la configuration de votre serveur)
echo "Définition des permissions (peut nécessiter d'ajuster l'utilisateur 'www-data')..."
usermod -a -G www-data agathebonnet
sudo chown -R www-data:www-data "$INSTALL_DIR"
sudo find "$INSTALL_DIR" -type d -exec chmod 755 {} \;
sudo find "$INSTALL_DIR" -type f -exec chmod 644 {} \;

echo "✅ Fichiers de PrestaShop installés dans $INSTALL_DIR."
echo "Prochaine étape : Configuration de la base de données et installation via le navigateur."
