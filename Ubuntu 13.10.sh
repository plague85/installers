#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
	echo "You must be root to do this." 1>&2
	exit 100
fi

clear
echo -e "\033[1;33mThis installs nZEDb, Nginx Web Server, php, php-fp,. memcached, apc \n[ Mysql SQL Server, Percona SQL Server, Maria SQL Server, TokuDB SQL Server(MariaDB) or PostGreSQL Server] \nand everything that is needed to your Ubuntu install.\nThis will also completely remove apparmor and any installation you may have for MySQL, Percona, MariaDB or PostgreSQL\033[0m"
echo
echo "This program is free software. You can redistribute it and/or modify it under the terms of the GNU General Public License"
echo "version 2, as published by the Free Software Foundation."
echo
echo "This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied"
echo "warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."
echo "See the GNU General Public License for more details."
echo
echo "DISCLAIMER"
echo " # This script is made available to you without any express, implied or "
echo " # statutory warranty, not even the implied warranty of "
echo " # merchantability or fitness for a particular purpose, or the "
echo " # warranty of title. The entire risk of the use or the results from the use of this script remains with you."

echo "---------------------------------------------------------------------------------------------------------------"
echo
echo
echo
echo "Do you Agree?"
echo "y=YES n=NO"

read CHOICE
if [[ $CHOICE != "y" ]]; then
	exit
fi

clear
echo -e "\033[1;33mnginx needs to have the ip or fqdn, localhost will not work in most cases"
echo "Enter the ip or fqdn of this server."
/sbin/ifconfig | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'
#curl -s icanhazip.com
netcat icanhazip.com 80 <<< $'GET / HTTP/1.0\nHost: icanhazip.com\n\n' | tail -n1

echo
read IPADDY

clear
echo "You can install the ffmpeg by using apt-get or use a precompiled static linked binary. To install the ffmpeg using apt-get type \"y\"."
echo
echo "y=YES n=NO"
read COMPILE
if [[ $COMPILE != "y" ]]; then
	export COMPILE="n"
fi

clear
echo "Install extra apps that are not necessarily needed for nZEDb operation, such as htop, mytop, etc."
echo
echo "y=YES n=NO"
read EXTRAS
if [[ $EXTRAS != "y" ]]; then
	export EXTRAS="n"
fi

clear
echo "Choose your SQL Server."
echo
echo "[1] Mysql Server"
echo "[2] MariaDB Server"
echo "[3] TokuDB using MariaDB Server"
echo "[4] Percona XtraDB Server"
echo "[5] PostGreSQL Server"
echo
read DATABASE
if [[ $DATABASE != "1" ]] && [[ $DATABASE != "2" ]] && [[ $DATABASE != "3" ]] && [[ $DATABASE != "4" ]] && [[ $DATABASE != "5" ]]; then
	export DATABASE="1"
fi

clear
echo "Completey remove MySQL, Percona, MariaDB and PostgreSQL Servers?"
echo
echo "y=YES n=NO"
read PURGE
if [[ $PURGE != "y" ]]; then
	export PURGE="n"
fi

clear
echo "Install Python Modules for Python 2.*?"
echo
echo "y=YES n=NO"
read PYTHON@
if [[ $PURGE != "y" ]]; then
	export PYTHON2="n"
fi

clear
echo "Install Python Modules for Python 3.*?"
echo
echo "y=YES n=NO"
read PYTHON@
if [[ $PURGE != "y" ]]; then
	export PYTHON3="n"
fi

clear
echo "Updating apt"
updateapt
echo "Removing Apparmor"
/etc/init.d/apparmor stop
/etc/init.d/apparmor teardown
update-rc.d -f apparmor teardown
update-rc.d -f apparmor remove
apt-get purge -qq apparmor

echo "Allow adding apt repos"
apt-get install -qq software-properties-common
apt-get install -qq nano

function purgesql {
	if [[ $PURGE == "y" ]];
	then
		echo "Purging postgresql"
		apt-get purge -qq postgresql*
		echo "Purging mysql"
		apt-get purge -qq mysql*
		echo "Purging percona"
		apt-get purge -qq percona*
		echo "Purging mariadb"
		apt-get purge -qq mariadb*
		echo "Purging tokudb"
		apt-get -qq purge tokudb*
		echo "Running Autoremove"
		apt-get -qq autoremove
	fi
}

function updateapt {
	apt-get -qq update
}

function disablepercona {
	sed -i -e 's/deb http:\/\/repo.percona.com/#deb http:\/\/repo.percona.com/' /etc/apt/sources.list
	sed -i -e 's/deb-src http:\/\/repo.percona.com/#deb-src http:\/\/repo.percona.com/' /etc/apt/sources.list
}

function disablemaria {
	sed -i -e 's/deb http:\/\/ftp.osuosl.org/#deb http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
	sed -i -e 's/deb-src http:\/\/ftp.osuosl.org/#deb-src http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
}

function disablepostgresql {
	sed -i -e 's/deb http:\/\/apt.postgresql.org/#deb http:\/\/apt.postgresql.org/' /etc/apt/sources.list
}

function enablepercona {
	sed -i -e 's/#deb http:\/\/repo.percona.com/deb http:\/\/repo.percona.com/' /etc/apt/sources.list
	sed -i -e 's/#deb-src http:\/\/repo.percona.com/deb-src http:\/\/repo.percona.com/' /etc/apt/sources.list
}

function enablemaria {
	sed -i -e 's/#deb http:\/\/ftp.osuosl.org/deb http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
	sed -i -e 's/#deb-src http:\/\/ftp.osuosl.org/deb-src http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
}

function enablepostgresql {
	sed -i -e 's/#deb http:\/\/apt.postgresql.org/deb http:\/\/apt.postgresql.org/' /etc/apt/sources.list
}


if [[ $DATABASE == "1" ]];
then
	echo "Installing Mysql Server"
	echo -e "Updating Apt Catalog\033[0m"
	disablepercona
	disablemaria
	disablepostgresql
	updateapt
	purgesql
	apt-get install -qq mysql-client mysql-server
elif [[ $DATABASE == "2" ]];
then
	echo "Installing MariaDB Server"
	sed -i -e 's/deb http:\/\/repo.percona.com/#deb http:\/\/repo.percona.com/' /etc/apt/sources.list
	sed -i -e 's/deb-src http:\/\/repo.percona.com/#deb-src http:\/\/repo.percona.com/' /etc/apt/sources.list
	echo "" | tee -a /etc/apt/sources.list
	if ! grep -q '#MariaDB' "/etc/apt/sources.list" ; then
			echo "" | tee -a /etc/apt/sources.list
			echo "#MariaDB" | tee -a /etc/apt/sources.list
			echo "deb http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu saucy main" | tee -a /etc/apt/sources.list
		echo "deb-src http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu saucy main" | tee -a /etc/apt/sources.list
	fi
	echo -e "Updating Apt Catalog\033[0m"
	disablepercona
	disablepostgresql
	enablemaria
	updateapt
	purgesql
	apt-get install -qq mariadb-server mariadb-client
elif [[ $DATABASE == "3" ]];
then
	echo "Installing TokuDB Engine with MariaDB Server"
	sed -i -e 's/deb http:\/\/repo.percona.com/#deb http:\/\/repo.percona.com/' /etc/apt/sources.list
	sed -i -e 's/deb-src http:\/\/repo.percona.com/#deb-src http:\/\/repo.percona.com/' /etc/apt/sources.list
	echo "" | tee -a /etc/apt/sources.list
	if ! grep -q '#MariaDB' "/etc/apt/sources.list" ; then
		echo "" | tee -a /etc/apt/sources.list
		echo "#MariaDB" | tee -a /etc/apt/sources.list
		echo "deb http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu saucy main" | tee -a /etc/apt/sources.list
		echo "deb-src http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu saucy main" | tee -a /etc/apt/sources.list
	fi
	if ! grep -q '#Percona' "/etc/apt/preferences.d/00mariadb.pref" ; then
		echo "" | sudo tee -a /etc/apt/preferences.d/00mariadb.pref
		echo "#MariaDB" | sudo tee -a /etc/apt/preferences.d/00mariadb.pref
		echo "Package: *" | sudo tee -a /etc/apt/preferences.d/00mariadb.pref
		echo "Pin: origin ftp.osuosl.org" | sudo tee -a /etc/apt/preferences.d/00mariadb.pref
		echo "Pin-Priority: 1000" | sudo tee -a /etc/apt/preferences.d/00mariadb.pref
	fi
	echo -e "Updating Apt Catalog\033[0m"
	disablepercona
	disablepostgresql
	enablemaria
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
	updateapt
	purgesql
	apt-get install -qq mariadb-tokudb-engine-5.5 mariadb-client
	sed -i -e 's/#plugin-load=ha_tokudb.so/plugin-load=ha_tokudb.so/' /etc/mysql/conf.d/tokudb.cnf
	sed -i -e 's/default_storage_engine.*$/default_storage_engine  = tokudb/' /etc/mysql/my.cnf
	service mysql restart
elif [[ $DATABASE == "4" ]];
then
	echo "Installing Percona XtraDB Server"
	gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
	gpg -a --export CD2EFD2A | apt-key add -
	sed -i -e 's/deb http:\/\/ftp.osuosl.org/#deb http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
	sed -i -e 's/deb-src http:\/\/ftp.osuosl.org/#deb-src http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
	if ! grep -q '#Percona' "/etc/apt/sources.list" ; then
		echo "" | tee -a /etc/apt/sources.list
		echo "#Percona" | tee -a /etc/apt/sources.list
		echo "deb http://repo.percona.com/apt quantal main" | tee -a /etc/apt/sources.list
		echo "deb-src http://repo.percona.com/apt quantal main" | tee -a /etc/apt/sources.list
	fi
	echo -e "Updating Apt Catalog\033[0m"
	disablemaria
	disablepostgresql
	enablepercona
	updateapt
	purgesql
	mkdir -p /etc/mysql
	wget --no-check-certificate https://dl.dropboxusercontent.com/u/8760087/initial_my.cnf -O /etc/mysql/my.cnf
	apt-get install -qq percona-server-client-5.6 percona-server-server-5.6
	clear
	echo -e "\033[1;33m Adding Percona functions, to not install, use invalid password\n\n"
	echo "mysql -p -e \"CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'\""
	mysql -p -e "CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
	echo "mysql -p -e \"CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'\""
	mysql -p -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
	echo -e "mysql -p -e \"CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'\"\033[0m"
	mysql -p -e "CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"
elif [[ $DATABASE == "5" ]];
then
	echo "Installing PostGreSQL Server"
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
	sed -i -e 's/deb http:\/\/ftp.osuosl.org/#deb http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
	sed -i -e 's/deb-src http:\/\/ftp.osuosl.org/#deb-src http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
	sed -i -e 's/deb http:\/\/repo.percona.com/#deb http:\/\/repo.percona.com/' /etc/apt/sources.list
	sed -i -e 's/deb-src http:\/\/repo.percona.com/#deb-src http:\/\/repo.percona.com/' /etc/apt/sources.list
	if ! grep -q '#PostgreSQL' "/etc/apt/sources.list" ; then
		echo "" | tee -a /etc/apt/sources.list
		echo "#PostgreSQL" | tee -a /etc/apt/sources.list
		echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" | tee -a /etc/apt/sources.list
	fi
	echo -e "Updating Apt Catalog\033[0m"
	disablepercona
	disablemaria
	enablepostgresql
	updateapt
	purgesql
	apt-get -qq install postgresql postgresql-server-dev-all
fi

#Installing Prerequirements
echo -e "\033[1;33mInstalling Nginx (engineX)"
apt-get install -qq nginx
mkdir -p /var/log/nginx
chmod 755 /var/log/nginx

echo -e "\033[1;33mInstalling PHP, PHP-FPM"
apt-get install -qq php5-fpm
apt-get install -qq php5 php5-dev php-pear php5-gd php5-curl openssh-server openssl software-properties-common ca-certificates ssl-cert memcached php5-memcache php5-memcached php5-json php5-xdebug
if [[ $DATABASE == "5" ]];
then
	apt-get install -qq php5-pgsql
else
	apt-get install -qq php5-mysqlnd
fi

echo "Edit config files"
sed -i -e 's/max_execution_time.*$/max_execution_time = 180/' /etc/php5/cli/php.ini
sed -i -e 's/max_execution_time.*$/max_execution_time = 180/' /etc/php5/fpm/php.ini
sed -i -e 's/memory_limit.*$/memory_limit = -1/' /etc/php5/cli/php.ini
sed -i -e 's/memory_limit.*$/memory_limit = -1/' /etc/php5/fpm/php.ini
sed -i -e 's/[;?]date.timezone.*$/date.timezone = America\/New_York/' /etc/php5/cli/php.ini
sed -i -e 's/[;?]date.timezone.*$/date.timezone = America\/New_York/' /etc/php5/fpm/php.ini
sed -i -e 's/[;?]cgi.fix_pathinfo.*$/cgi.fix_pathinfo = 0/' /etc/php5/fpm/php.ini
sed -i -e 's/[;?]cgi.fix_pathinfo.*$/cgi.fix_pathinfo = 0/' /etc/php5/cli/php.ini
sed -i -e 's/short_open_tag.*$/short_open_tag = Off/' /etc/php5/fpm/php.ini
sed -i -e 's/short_open_tag.*$/short_open_tag = Off/' /etc/php5/cli/php.ini
sed -i -e 's/display_errors.*$/display_errors = On/' /etc/php5/fpm/php.ini
sed -i -e 's/display_errors.*$/display_errors = On/' /etc/php5/cli/php.ini
sed -i -e 's/display_startup_errors.*$/display_startup_errors = On/' /etc/php5/fpm/php.ini
sed -i -e 's/display_startup_errors.*$/display_startup_errors = On/' /etc/php5/cli/php.ini

mkdir -p /var/www/nZEDb
chmod 777 /var/www/nZEDb

if [ ! -f /etc/nginx/sites-available/nzedb ]; then
cat << EOF >> /etc/nginx/sites-available/nzedb
server {
	listen      80 default;
	server_name localhost;
	## redirect http to https ##
	rewrite        ^ https://$server_name$request_uri? permanent;
}

server {
	# Change these settings to match your machine
	listen   443; ## listen for ipv4; this line is default and implied
	listen   [::]:443 default_server ipv6only=on; ## listen for ipv6
	server_name localhost;

	ssl on;
	ssl_certificate /etc/ssl/nginx/conf/server.crt;
	ssl_certificate_key /etc/ssl/nginx/conf/server.key;

	location ^~ / {
		root /var/www/nZEDb/www/;
		index index.php;
		try_files $uri $uri/ @rewrites;

		location ~ /(?:\.|lib|pages) {
			deny all;
		}

		location ~* \.(?:css|jpe?g|gif|ogg|ogv|png|js|ico|ttf|eot|woff|svg) {
			expires max;
			add_header Pragma public;
			add_header Cache-Control "public, must-revalidate, proxy-revalidate";
		}

		location ~ \.php$ {
			try_files $uri =404;
			fastcgi_split_path_info ^(.+\.php)(/.+)$;
			# NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini

			# With php5-cgi alone:
			#fastcgi_pass 127.0.0.1:9000;
			# With php5-fpm:
			fastcgi_pass unix:/var/run/php5-fpm.sock;
			#fastcgi_index index.php;
			include fastcgi_params;
			#include /etc/nginx/fastcgi_params;
		}

	}

	location @rewrites {
		rewrite ^/([^/\.]+)/([^/]+)/([^/]+)/? /index.php?page=$1&id=$2&subpage=$3 last;
		rewrite ^/([^/\.]+)/([^/]+)/?$ /index.php?page=$1&id=$2 last;
		rewrite ^/([^/\.]+)/?$ /index.php?page=$1 last;
	}
}
EOF
fi

sed -i -e "s/localhost/$IPADDY/" /etc/nginx/sites-available/nzedb
if ! grep -q 'fastcgi_index index.php;' "/etc/nginx/fastcgi_params" ; then
	echo "fastcgi_index index.php;" | tee -a /etc/nginx/fastcgi_params
fi
if ! grep -q 'fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;' "/etc/nginx/fastcgi_params" ; then
	echo "fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;" | tee -a /etc/nginx/fastcgi_params
fi

unlink /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/nzedb /etc/nginx/sites-enabled/nzedb

echo "Create Self Signed Certificate"

#ssl
mkdir -p /etc/ssl/nginx/conf
cd /etc/ssl/nginx/conf
openssl genrsa -des3 -out server.key 4096
openssl req -new -key server.key -out server.csr
cp server.key server.key.org
openssl rsa -in server.key.org -out server.key
openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt

service php5-fpm stop
service php5-fpm start
service nginx restart

echo "Installing ffmpeg x264..."

if [[ $COMPILE != "y" ]];
then
	apt-get install -qq ffmpeg libavcodec-extra-53 libavutil-extra-51 unrar x264 libav-tools libvpx-dev libx264-dev
	#this will need to be updated
	wget http://johnvansickle.com/ffmpeg/builds/ffmpeg-linux64-20130918.tar.bz2
	tar xfv ffmpeg-linux64-*
	sudo mv ffmpeg-linux64-20130918/ffmpeg /usr/bin/
	sudo mv ffmpeg-linux64-20130918/ffprobe /usr/bin/
	rm -R ffmpeg-linux64*
else
	apt-get install -qq ffmpeg libavcodec-extra-53 libavutil-extra-51 unrar x264 libav-tools libvpx-dev libx264-dev
	# Use static build of ffmpeg
	try=`date +"%Y%m%d"`
	for i in {1..30} ; do
		wget http://johnvansickle.com/ffmpeg/builds/ffmpeg-git-$try-64bit-static.tar.bz2
		if [ $? -gt 0 ]; then
			try=`date -d "- $i day" +"%Y%m%d"`
				$((i ++ ))
		else
			break
		fi
	done
	filename=$(basename "`find . -name *.bz2`")
	tar xfv $filename
	extension="${filename##*.}"
	filename="${filename%.*}"
	extension="${filename##*.}"
	filename="${filename%.*}"
	mv $filename/ffmpeg-10bit /usr/bin/ffmpeg
	mv $filename/ffprobe /usr/bin/
	rm -r $filename
	rm $(basename "`find . -name *.bz2`")
fi

echo "Installing Mediainfo"

wget -c http://mediaarea.net/download/binary/libzen0/0.4.29/libzen0_0.4.29-1_amd64.xUbuntu_13.04.deb
wget -c http://mediaarea.net/download/binary/libmediainfo0/0.7.67/libmediainfo0_0.7.67-1_amd64.xUbuntu_13.10.deb
wget -c http://mediaarea.net/download/binary/mediainfo/0.7.67/mediainfo_0.7.67-1_amd64.Debian_7.0.deb
dpkg -i libzen0*
dpkg -i libmediainfo0*
dpkg -i mediainfo*
rm libzen0*
rm libmediainfo0*
rm mediainfo*

if [[ $PYTHON2 != "y" ]];
then
	Echo "Installing Python 2 modules"
	apt-get install -qq python-setuptools python-pip python-dev python-software-properties
	python -m easy_install
	if [[ $DATABASE == "5" ]];
	then
		easy_install psycopg2
	else
		if [ which pip 2>/dev/null ]; then pip install cymysql; fi
	fi
fi
if [[ $PYTHON3 != "y" ]];
then
	Echo "Installing Python 2 modules"
	apt-get install -qq python-setuptools python3-dev python-software-properties
	python -m easy_install
	elif [[ $DATABASE == "5" ]];
	then
		easy_install3 psycopg2
	else
		if [ which pip-3.2 2>/dev/null ]; then pip-3.2 cymysql; fi
		if [ which pip-3.3 2>/dev/null ]; then pip-3.3 cymysql; fi
	fi
fi



if [[ $EXTRAS == "y" ]]; then
	apt-get install -qq nmon mytop iftop bwm-ng vnstat atop iotop ifstat htop pastebinit pigz iperf geany geany-plugins-common geany-plugins geany-plugin-spellcheck ttf-mscorefonts-installer diffuse tinyca meld tmux unrar p7zip-full make screen git gedit gitweb
	mv /bin/gzip /bin/gzip.old
	ln -s /usr/bin/pigz /bin/gzip
fi

apt-get autoclean
apt-get autoremove

git clone https://github.com/nZEDb/nZEDb.git /var/www/nZEDb

chmod -R 777 /var/www/nZEDb/smarty/templates_c
chmod -R 777 /var/www/nZEDb/www/covers
chmod -R 777 /var/www/nZEDb/nzbfiles
chmod 777 /var/www/nZEDb/www
chmod 777 /var/www/nZEDb/www/install
chown -R www-data:www-data /var/www/

service php5-fpm stop
service php5-fpm start
service nginx restart

clear
echo -e "\033[1;33m-----------------------------------------------"
echo -e "\033[1;33mInstall Complete...."
echo "Go to http://$IPADDY to finish nZEDb install."
echo "For questions and problems log on to #nZEDb on Synirc"
echo -e "\n\n\033[0m"
exit 100
