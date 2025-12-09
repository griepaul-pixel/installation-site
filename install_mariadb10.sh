#!/bin/bash

# --- Configuration pour PrestaShop ---
DB_NAME="prestashop_db"          # Nom de la base de données PrestaShop
DB_USER="prestashop_user"        # Nom de l'utilisateur dédié à la base de données
DB_PASSWORD="84sDro#m%oT4#n^xgiA2c*69%S" # *** REMPLACER CECI *** : Mot de passe fort pour l'utilisateur PrestaShop

# --- Configuration système (pour l'installation) ---
# Le mot de passe root de MariaDB (pour le premier accès SÉCURISÉ)
# Sur les versions modernes d'Ubuntu, l'utilisateur 'root' de MySQL est authentifié par défaut via 'unix_socket'
# Ce script ne définira pas de mot de passe root en ligne de commande, mais vous demandera de le faire.
# Pour simplifier l'exécution, on utilise la méthode d'authentification 'root' par sudo.

echo "=========================================================="
echo "🚀 Démarrage de l'installation de MariaDB sur Ubuntu et Préparation de la BDD"
echo "=========================================================="

# 1. Mise à jour des paquets et installation de MariaDB
echo "⏳ Étape 1 : Mise à jour des paquets et installation du serveur MariaDB..."
sudo apt update -y
sudo apt install mariadb-server -y

if [ $? -ne 0 ]; then
    echo "❌ ERREUR : L'installation de MariaDB a échoué. Veuillez vérifier les logs."
    exit 1
fi

echo "✅ MariaDB est installé."

# 2. Sécurisation de l'installation de MariaDB
echo "⏳ Étape 2 : Sécurisation de MariaDB (via 'mysql_secure_installation')..."
# Nous ne pouvons pas automatiser 'mysql_secure_installation' car cela demande une interaction
echo "ATTENTION : Vous devez lancer manuellement 'sudo mysql_secure_installation' après ce script."
echo "Pour cette automatisation, nous allons créer l'utilisateur sans passer par l'outil interactif complet."

# 3. Création de la base de données et de l'utilisateur pour PrestaShop
echo "⏳ Étape 3 : Création de la base de données '$DB_NAME' et de l'utilisateur '$DB_USER'..."

# Les commandes sont exécutées via 'sudo mysql' car l'utilisateur 'root' de MariaDB
# est mappé à l'utilisateur 'root' du système via l'extension 'unix_socket' sur Ubuntu.
sudo mysql -e "
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
"

if [ $? -ne 0 ]; then
    echo "❌ ERREUR : La création de la base de données/utilisateur a échoué. Vérifiez le mot de passe et l'état de MariaDB."
    exit 1
fi

echo "=========================================================="
echo "✅ Configuration de la Base de Données terminée !"
echo "=========================================================="
echo "Détails de la BDD pour PrestaShop :"
echo "   - Nom de la base de données : $DB_NAME"
echo "   - Nom d'utilisateur : $DB_USER"
echo "   - Mot de passe : $DB_PASSWORD (ASSUREZ-VOUS DE L'AVOIR CHANGÉ)"
echo "   - Hôte : localhost"
echo "---"
echo "PROCHAINE ÉTAPE IMPORTANTE :"
echo "1. Lancez la commande suivante pour finaliser la sécurité :"
echo "   sudo mysql_secure_installation"
echo "2. Lorsque vous installez PrestaShop via le navigateur, utilisez les détails ci-dessus."
