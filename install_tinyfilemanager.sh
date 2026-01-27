#!/bin/bash

apt-get install php-mbstring 
FOLDER=/data/tinyfilemanager
mkdir $FOLDER 2>/dev/null
cd $FOLDER
mkdir -p /data/site/bash/tinyfilemanager 2>/dev/null
wget https://github.com/prasathmani/tinyfilemanager/archive/refs/heads/master.zip
unzip master.zip
cp tinyfilemanager-master/tinyfilemanager.php /data/site/bash/tinyfilemanager
