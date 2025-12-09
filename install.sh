#!/bin/bash

# --- ÉTAPE 1: Mise à jour du système et installation des paquets APT essentiels ---

echo "⚙️ Mise à jour de la liste des paquets et installation des dépendances système..."

# Mise à jour de l'index des paquets disponibles (très important avant toute installation)
apt update

# Installation d'une liste de paquets nécessaires pour le fonctionnement du serveur
apt install \
    net-tools \
    shorewall \
    fail2ban \
    apache2 \
    hugo \
    postfix \
    opendkim \
    opendkim-tools \
    -y # Ajout de l'option -y pour confirmer automatiquement l'installation

# Explication des paquets installés:
# net-tools: Utilitaires réseau classiques (comme netstat, ifconfig)
# shorewall: Pare-feu avancé pour configurer les règles de sécurité.
# fail2ban: Outil qui scanne les logs et bannit les adresses IP ayant échoué à se connecter (sécurité).
# apache2: Le serveur web HTTP pour héberger des sites web.
# hugo: Un générateur de sites statiques rapide, utile pour la création de contenu.
# postfix: Agent de transfert de courrier (MTA), essentiel pour l'envoi et la réception d'emails.
# opendkim: Implémentation du protocole DomainKeys Identified Mail (DKIM) pour signer les emails.
# opendkim-tools: Outils pour gérer et configurer OpenDKIM.

# --- ÉTAPE 2: Installation et configuration de Snapd (Gestionnaire de paquets universel) ---

echo "📦 Installation et rafraîchissement de Snapd..."

# Installation du gestionnaire de paquets snapd
apt install snapd -y

# Installation du paquet snap 'core' (environnement de base pour les snaps)
snap install core

# Mise à jour des composants de base de Snapd (pour s'assurer d'avoir les dernières versions)
snap refresh core

# --- ÉTAPE 3: Installation de Certbot via Snap (pour les certificats SSL/TLS) ---

echo "🔒 Installation de Certbot pour la gestion des certificats SSL/TLS..."

# Installation de Certbot en mode 'classic' car il nécessite des permissions système étendues
snap install --classic certbot


# Création d'un lien symbolique pour la commande 'certbot'
# Cela permet d'exécuter la commande 'certbot' directement depuis n'importe quel emplacement
# Le chemin de l'exécutable snap est lié au répertoire standard des exécutables (/usr/bin)
ln -s /snap/bin/certbot /usr/bin/certbot

# Installation du plugin Apache de Certbot (pour configurer automatiquement Apache)
# Note: Ce paquet installe des dépendances Python nécessaires à l'intégration.
apt install python3-certbot-apache -y

# Répétition de la création du lien symbolique (vérification ou redondance dans le script original)
# Bien que déjà fait plus haut, on le laisse pour maintenir la fidélité au script de base.
ln -s /snap/bin/certbot /usr/bin/certbot

# Affichage des détails du lien symbolique pour vérifier que l'installation de Certbot est accessible
echo "Vérification de l'accès à la commande Certbot:"
ls -al /snap/bin/certbot

echo "✅ Installation et configuration de base terminées."

CONFIG_PATH=/home/agathebonnet/installation/configuration
echo "Copie des fichiers de configuration shorewall"

cp -ar ${CONFIG_PATH}/shorewall/* /etc/shorewall/
cp ${CONFIG_PATH}/default/shorewall /etc/default/shorewall

shorewall check
if [ $? -eq 0 ]
then
	service shorewall restart
fi

echo
echo "Copie des fichiers postfiw"
cp ${CONFIG_PATH}/postfix/main.cf /etc/postfix/
service postfix restart
echo "test.lherbefollefleuriste.com" /etc/mailname

echo
echo "Copie des fichiers fail2ban"
cp ${CONFIG_PATH}/fail2ban/jail.local /etc/fail2ban/jail.local
sudo systemctl restart fail2ban
sudo systemctl status fail2ban | grep "Active"

echo
echo "Copie des fichiers apache2"
cp ${CONFIG_PATH}/apache/security.conf /etc/apache2/conf-enabled/security.conf
apache2ctl graceful
