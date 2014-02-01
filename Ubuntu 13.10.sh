#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
	echo "You must be root to do this." 1>&2
	exit
fi

clear
echo -e "\033[1;33mThis installs nZEDb, Nginx Web Server, php, php-fpm, memcached and a database server"
echo "[Mysql SQL Server, Percona SQL Server, Maria SQL Server, TokuDB SQL Server(MariaDB) or PostGreSQL Server]"
echo "and everything that is needed for your Ubuntu install."
echo -e "This will also completely remove apparmor and any installation you may have for MySQL, Percona, MariaDB or PostgreSQL\033[0m"
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
echo -e "\033[1;33mNginx needs to have the ip or FQDN, localhost will not work in most cases"
echo "Enter the ip or FQDN of this server."
echo -e "Detected IP's:\n\033[0m"
/sbin/ifconfig | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'
#curl -s icanhazip.com
netcat icanhazip.com 80 <<< $'GET / HTTP/1.0\nHost: icanhazip.com\n\n' | tail -n1

echo
read IPADDY

clear
echo -e "\033[1;33mYou can install the ffmpeg by using apt-get or use a precompiled static linked binary."
echo -e "To install the ffmpeg using apt-get and not the precompiled static binary, type 'y'.\033[0m"
echo
echo "y=YES n=NO"
read COMPILE
if [[ $COMPILE != "y" ]]; then
	export COMPILE="n"
fi

clear
echo -e "\033[1;33mInstall extra apps that are not necessarily needed for nZEDb operation, such as htop, mytop, etc.\033[0m"
echo
echo "y=YES n=NO"
read EXTRAS
if [[ $EXTRAS != "y" ]]; then
	export EXTRAS="n"
fi

clear
echo -e "\033[1;33mChoose your SQL Server."
echo
echo "[1] Mysql Server"
echo "[2] MariaDB Server"
echo "[3] TokuDB using MariaDB Server"
echo "[4] Percona XtraDB Server"
echo -e "[5] PostGreSQL Server\033[0m"
echo
read DATABASE
if [[ $DATABASE != "1" ]] && [[ $DATABASE != "2" ]] && [[ $DATABASE != "3" ]] && [[ $DATABASE != "4" ]] && [[ $DATABASE != "5" ]]; then
	export DATABASE="1"
fi

clear
echo -e "\033[1;33mCompletey remove MySQL, Percona, MariaDB and PostgreSQL Servers?\033[0m"
echo
echo "y=YES n=NO"
read PURGE
if [[ $PURGE != "y" ]]; then
	export PURGE="n"
fi

clear
echo -e "\033[1;33mInstall Python Modules for Python 2.*?\033[0m"
echo
echo "y=YES n=NO"
read PYTHONTWO
if [[ $PYTHONTWO != "y" ]]; then
	export PYTHONTWO="n"
fi

clear
echo -e "\033[1;33mInstall Python Modules for Python 3.*?\033[0m"
echo
echo "y=YES n=NO"
read PYTHONTHREE
if [[ $PYTHONTHREE != "y" ]]; then
	export PYTHONTHREE="n"
fi

function purgesql {
	if [[ $purgesql == "y" ]]; then
		echo "Purging postgresql"
		apt-get purge -yqq postgresql*
		echo "Purging mysql"
		apt-get purge -yqq mysql*
		echo "Purging percona"
		apt-get purge -yqq percona*
		echo "Purging mariadb"
		apt-get purge -yqq mariadb*
		echo "Purging tokudb"
		apt-get -yqq purge tokudb*
		echo "Running Autoremove"
		apt-get -yqq autoremove
	fi
}

function updateapt() {
	apt-get -yqq update
}

function disablepercona {
	sed -i 's/deb http:\/\/repo.percona.com/#deb http:\/\/repo.percona.com/' /etc/apt/sources.list
	sed -i 's/deb-src http:\/\/repo.percona.com/#deb-src http:\/\/repo.percona.com/' /etc/apt/sources.list
}

function disablemaria {
	sed -i 's/deb http:\/\/ftp.osuosl.org/#deb http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
	sed -i 's/deb-src http:\/\/ftp.osuosl.org/#deb-src http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
}

function disablepostgresql {
	sed -i 's/deb http:\/\/apt.postgresql.org/#deb http:\/\/apt.postgresql.org/' /etc/apt/sources.list
}

function enablepercona {
	sed -i 's/#deb http:\/\/repo.percona.com/deb http:\/\/repo.percona.com/' /etc/apt/sources.list
	sed -i 's/#deb-src http:\/\/repo.percona.com/deb-src http:\/\/repo.percona.com/' /etc/apt/sources.list
}

function enablemaria {
	sed -i 's/#deb http:\/\/ftp.osuosl.org/deb http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
	sed -i 's/#deb-src http:\/\/ftp.osuosl.org/deb-src http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
}

function enablepostgresql {
	sed -i 's/#deb http:\/\/apt.postgresql.org/deb http:\/\/apt.postgresql.org/' /etc/apt/sources.list
}

clear
echo "Updating Apt Catalog"
updateapt

echo "Removing Apparmor"
/etc/init.d/apparmor stop
/etc/init.d/apparmor teardown
update-rc.d -f apparmor remove
apt-get purge -yqq apparmor apparmor-utils

echo "Allow adding apt repos"
apt-get install -yqq software-properties-common
apt-get install -yqq nano

echo "Configuring ssh"
sed -i -e 's/^#ClientAliveInterval.*$/ClientAliveInterval 30/' /etc/ssh/sshd_config
sed -i -e 's/^#TCPKeepAlive.*$/TCPKeepAlive yes/' /etc/ssh/sshd_config
sed -i -e 's/^#ClientAliveCountMax.*$/ClientAliveCountMax 99999/' /etc/ssh/sshd_config

if ! grep -q 'ForwardX11Trusted' "/etc/ssh/sshd_config" ; then
        echo "ForwardX11Trusted yes" | tee -a /etc/ssh/sshd_config
else
        sed -i -e 's/ForwardX11Trusted.*$/ForwardX11Trusted yes/' /etc/ssh/sshd_config
fi
service ssh restart

if [[ $DATABASE == "1" ]]; then
	echo "Installing Mysql Server"
	echo "Updating Apt Catalog"
	disablepercona
	disablemaria
	disablepostgresql
	updateapt
	purgesql
	apt-get install -yqq mysql-client mysql-server
elif [[ $DATABASE == "2" ]]; then
	echo "Installing MariaDB Server"
	sed -i 's/deb http:\/\/repo.percona.com/#deb http:\/\/repo.percona.com/' /etc/apt/sources.list
	sed -i 's/deb-src http:\/\/repo.percona.com/#deb-src http:\/\/repo.percona.com/' /etc/apt/sources.list
	echo "" | tee -a /etc/apt/sources.list
	if ! grep -q '#MariaDB' "/etc/apt/sources.list" ; then
			echo "" | tee -a /etc/apt/sources.list
			echo "#MariaDB" | tee -a /etc/apt/sources.list
			echo "deb http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu saucy main" | tee -a /etc/apt/sources.list
		echo "deb-src http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu saucy main" | tee -a /etc/apt/sources.list
	fi
	echo "Updating Apt Catalog"
	disablepercona
	disablepostgresql
	enablemaria
	updateapt
	purgesql
	apt-get install -yqq mariadb-server mariadb-client
elif [[ $DATABASE == "3" ]]; then
	echo "Installing TokuDB Engine with MariaDB Server"
	sed -i 's/deb http:\/\/repo.percona.com/#deb http:\/\/repo.percona.com/' /etc/apt/sources.list
	sed -i 's/deb-src http:\/\/repo.percona.com/#deb-src http:\/\/repo.percona.com/' /etc/apt/sources.list
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
	echo "Updating Apt Catalog"
	disablepercona
	disablepostgresql
	enablemaria
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
	updateapt
	purgesql
	apt-get install -yqq mariadb-tokudb-engine-5.5 mariadb-client
	sed -i 's/#plugin-load=ha_tokudb.so/plugin-load=ha_tokudb.so/' /etc/mysql/conf.d/tokudb.cnf
	sed -i 's/default_storage_engine.*$/default_storage_engine  = tokudb/' /etc/mysql/my.cnf
	service mysql restart
elif [[ $DATABASE == "4" ]]; then
	echo "Installing Percona XtraDB Server"
	gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
	gpg -a --export CD2EFD2A | apt-key add -
	sed -i 's/deb http:\/\/ftp.osuosl.org/#deb http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
	sed -i 's/deb-src http:\/\/ftp.osuosl.org/#deb-src http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
	if ! grep -q '#Percona' "/etc/apt/sources.list" ; then
		echo "" | tee -a /etc/apt/sources.list
		echo "#Percona" | tee -a /etc/apt/sources.list
		echo "deb http://repo.percona.com/apt quantal main" | tee -a /etc/apt/sources.list
		echo "deb-src http://repo.percona.com/apt quantal main" | tee -a /etc/apt/sources.list
	fi
	echo "Updating Apt Catalog"
	disablemaria
	disablepostgresql
	enablepercona
	updateapt
	purgesql
	mkdir -p /etc/mysql
	wget --no-check-certificate https://dl.dropboxusercontent.com/u/8760087/initial_my.cnf -O /etc/mysql/my.cnf
	apt-get install -yqq percona-server-client-5.6 percona-server-server-5.6
elif [[ $DATABASE == "5" ]]; then
	echo "Installing PostGreSQL Server"
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
	sed -i 's/deb http:\/\/ftp.osuosl.org/#deb http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
	sed -i 's/deb-src http:\/\/ftp.osuosl.org/#deb-src http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
	sed -i 's/deb http:\/\/repo.percona.com/#deb http:\/\/repo.percona.com/' /etc/apt/sources.list
	sed -i 's/deb-src http:\/\/repo.percona.com/#deb-src http:\/\/repo.percona.com/' /etc/apt/sources.list
	if ! grep -q '#PostgreSQL' "/etc/apt/sources.list" ; then
		echo "" | tee -a /etc/apt/sources.list
		echo "#PostgreSQL" | tee -a /etc/apt/sources.list
		echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" | tee -a /etc/apt/sources.list
	fi
	echo "Updating Apt Catalog"
	disablepercona
	disablemaria
	enablepostgresql
	updateapt
	purgesql
	apt-get -yqq install postgresql postgresql-server-dev-all
fi

#Installing Prerequirements
echo -e "\033[1;33mInstalling Nginx (engineX)\033[0m"
apt-get install -yqq nginx
mkdir -p /var/log/nginx
chmod 755 /var/log/nginx

echo -e "\033[1;33mInstalling PHP, PHP-FPM\033[0m"
apt-get install -yqq php5-fpm
apt-get install -yqq php5 php5-dev php-pear php5-gd php5-curl openssh-server openssl software-properties-common ca-certificates ssl-cert memcached php5-memcache php5-memcached php5-json php5-xdebug
if [[ $DATABASE == "5" ]]; then
	apt-get install -yqq php5-pgsql
else
	apt-get install -yqq php5-mysqlnd
fi

echo -e "\033[1;33mEdit config files\033[0m"
sed -i 's/max_execution_time.*$/max_execution_time = 180/' /etc/php5/cli/php.ini
sed -i 's/max_execution_time.*$/max_execution_time = 180/' /etc/php5/fpm/php.ini
sed -i 's/memory_limit.*$/memory_limit = -1/' /etc/php5/cli/php.ini
sed -i 's/memory_limit.*$/memory_limit = -1/' /etc/php5/fpm/php.ini
sed -i 's/[;?]date.timezone.*$/date.timezone = America\/New_York/' /etc/php5/cli/php.ini
sed -i 's/[;?]date.timezone.*$/date.timezone = America\/New_York/' /etc/php5/fpm/php.ini
sed -i 's/[;?]cgi.fix_pathinfo.*$/cgi.fix_pathinfo = 0/' /etc/php5/fpm/php.ini
sed -i 's/[;?]cgi.fix_pathinfo.*$/cgi.fix_pathinfo = 0/' /etc/php5/cli/php.ini
sed -i 's/short_open_tag.*$/short_open_tag = Off/' /etc/php5/fpm/php.ini
sed -i 's/short_open_tag.*$/short_open_tag = Off/' /etc/php5/cli/php.ini
sed -i 's/display_errors.*$/display_errors = On/' /etc/php5/fpm/php.ini
sed -i 's/display_errors.*$/display_errors = On/' /etc/php5/cli/php.ini
sed -i 's/display_startup_errors.*$/display_startup_errors = On/' /etc/php5/fpm/php.ini
sed -i 's/display_startup_errors.*$/display_startup_errors = On/' /etc/php5/cli/php.ini

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

sed -i "s/localhost/$IPADDY/" /etc/nginx/sites-available/nzedb
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

if [[ $COMPILE == "y" ]]; then
	apt-get install -yqq ffmpeg libavcodec-extra-53 libavutil-extra-51 unrar x264 libav-tools libvpx-dev libx264-dev
else
	apt-get install -yqq ffmpeg libavcodec-extra-53 libavutil-extra-51 unrar x264 libav-tools libvpx-dev libx264-dev
	# Use static build of ffmpeg
	try=`date +"%Y%m%d"`
	for i in {1..30} ; do
		wget -n http://johnvansickle.com/ffmpeg/builds/ffmpeg-git-$try-64bit-static.tar.bz2
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

if [[ $EXTRAS == "y" ]]; then
	unset DEBIAN_FRONTEND
	apt-get install -yqq nmon mytop iftop bwm-ng vnstat atop iotop ifstat htop pastebinit pigz iperf geany geany-plugins-common geany-plugins geany-plugin-spellcheck ttf-mscorefonts-installer diffuse tinyca meld tmux unrar p7zip-full make screen git gedit gitweb
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

if [[ $PYTHONTWO == "y" ]]; then
	echo "Installing Python 2 modules to your user's home folder, they are not installed globally"
	apt-get install -yqq python-setuptools python-pip python-dev python-software-properties
	if [[ $DATABASE == "5" ]]; then
		pip install --user psycopg2
	else
		pip install --user cymysql
	fi
	pip install --user pynntp
	USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
	chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.local
fi

if [[ $PYTHONTHREE == "y" ]]; then
	echo "Installing Python 3 modules to your user's home folder, they are not installed globally"
	apt-get install -yqq python3-setuptools python3-pip python3-dev python-software-properties
	if [[ $DATABASE == "5" ]]; then
		pip3 install --user psycopg2
	else
		pip3 install --user cymysql
	fi
	pip3 install --user pynntp
	chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.local
fi

if [[ $DATABASE != "5" ]]; then
	clear
	echo -e "\033[1;33mMySQL password for root is blank."
	echo -e "Adding Percona functions, to not install, use any password\n\n"
	echo -e "mysql -uroot -p -e \"CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'\"\033[0m"
	mysql -uroot -p -e "CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
	echo -e "\033[1;33mmysql -uroot -p -e \"CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'\"\033[0m"
	mysql -uroot -p -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
	echo -e "\033[1;33mmysql -uroot -p -e \"CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'\"\033[0m"
	mysql -uroot -p -e "CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"
	echo -e "\033[1;33mMySQL password for root is blank."
	mysql_secure_installation
fi

clear
echo -e "\033[1;33m-----------------------------------------------"
echo -e "\033[1;33mInstall Complete...."
echo "Go to https://$IPADDY to finish nZEDb install."
echo "For questions and problems log on to #nZEDb on irc.Synirc.net"
echo -e "\n\n\033[0m"
exit
