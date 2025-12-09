#!/bin/bash

# --- Configuration PHP ---
PHP_VERSION="8.3"

# Liste des extensions PHP essentielles requises par PrestaShop (peut varier légèrement)
PHP_EXTENSIONS="cli fpm gd curl intl mbstring zip xml opcache bcmath soap"

echo "=========================================================="
echo "🚀 Démarrage de l'installation de PHP $PHP_VERSION et des extensions"
echo "=========================================================="

# 1. Mise à jour des paquets
echo "⏳ Étape 1 : Mise à jour des paquets..."
sudo apt update -y

# 2. Installation des paquets PHP de base et des extensions nécessaires
echo "⏳ Étape 2 : Installation des paquets PHP et des extensions..."
# On installe le FPM (FastCGI Process Manager) pour une meilleure performance avec Apache ou Nginx
sudo apt install -y php${PHP_VERSION}-mysql php${PHP_VERSION}-fpm php${PHP_VERSION}-${PHP_EXTENSIONS// / php${PHP_VERSION}-}

if [ $? -ne 0 ]; then
    echo "❌ ERREUR : L'installation des paquets PHP a échoué. Vérifiez la version et les dépendances."
    exit 1
fi

echo "✅ PHP $PHP_VERSION et les extensions requises sont installés."

# 3. Configuration d'Apache pour PHP-FPM
# Sur Ubuntu, l'installation de php-fpm crée un socket. Il faut activer le module Apache
# 'proxy_fcgi' et 'setenvif' pour qu'Apache puisse communiquer avec PHP-FPM.

echo "⏳ Étape 3 : Activation des modules Apache nécessaires..."
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php${PHP_VERSION}-fpm

# 4. Redémarrage des services
echo "⏳ Étape 4 : Redémarrage des services Apache et PHP-FPM..."
sudo systemctl restart php${PHP_VERSION}-fpm
sudo systemctl restart apache2

echo "=========================================================="
echo "✅ Installation de PHP $PHP_VERSION terminée et intégrée à Apache !"
echo "=========================================================="
