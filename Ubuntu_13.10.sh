#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
	if [[ whoami != $SUDO_USER ]]; then
		export script=`basename $0`
		echo
		echo -e "\033[1;31mYou must run this script as a user using sudo ${script}.\033[0m" 1>&2
		echo
		exit
	fi
	export script=`basename $0`
	echo
	echo -e "\033[1;31mYou must run this script as a user using sudo ${script}, not as the root user.\033[0m" 1>&2
	echo
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
echo "Do you Agree?"
echo "y=YES n=NO"
echo

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
echo
read COMPILE
if [[ $COMPILE != "y" ]]; then
	export COMPILE="n"
fi

clear
echo -e "\033[1;33mInstall extra apps that are not necessarily needed for nZEDb operation, such as htop, mytop, etc.\033[0m"
echo
echo "y=YES n=NO"
echo
read EXTRAS
if [[ $EXTRAS != "y" ]]; then
	export EXTRAS="n"
fi

clear
echo -e "\033[1;33mInstall pear modules needed for NetBeans.\033[0m"
echo
echo "y=YES n=NO"
echo
read PEARMOD
if [[ $PEARMOD != "y" ]]; then
		export PEARMOD="n"
fi

clear
echo -e "\033[1;33mCheckout the dev branch in nZEDb?\033[0m"
echo
echo "y=YES n=NO"
echo
read CHECKOUTDEV
if [[ $CHECKOUTDEV != "y" ]]; then
		export CHECKOUTDEV="n"
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
echo
read PURGE
if [[ $PURGE != "y" ]]; then
	export PURGE="n"
fi

clear
echo -e "\033[1;33mInstall Python Modules for Python 2.*?\033[0m"
echo
echo "y=YES n=NO"
echo
read PYTHONTWO
if [[ $PYTHONTWO != "y" ]]; then
	export PYTHONTWO="n"
fi

clear
echo -e "\033[1;33mInstall Python Modules for Python 3.*?\033[0m"
echo
echo "y=YES n=NO"
echo
read PYTHONTHREE
if [[ $PYTHONTHREE != "y" ]]; then
	export PYTHONTHREE="n"
fi

clear
echo -e "\033[1;33mInstall PhpStorm?\033[0m"
echo
echo "y=YES n=NO"
echo
read PHPSTORM
if [[ $PHPSTORM != "y" ]]; then
    export PHPSTORM="n"
fi

function purgesql {
	if [[ $purgesql == "y" ]]; then
		echo -e "\033[1;33mPurging postgresql\033[0m"
		apt-get purge -yqq postgresql*
		echo -e "\033[1;33mPurging mysql\033[0m"
		apt-get purge -yqq mysql*
		echo -e "\033[1;33mPurging percona\033[0m"
		apt-get purge -yqq percona*
		echo -e "\033[1;33mPurging mariadb\033[0m"
		apt-get purge -yqq mariadb*
		echo -e "\033[1;33mPurging tokudb\033[0m"
		apt-get -yqq purge tokudb*
		echo -e "\033[1;33mRunning Autoremove\033[0m"
		apt-get -yqq autoremove
	fi
}

function updateapt() {
	echo -e "\033[1;33mUpdating Apt Catalog\033[0m"
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
updateapt

echo -e "\033[1;33mRemoving Apparmor\033[0m"
/etc/init.d/apparmor stop
/etc/init.d/apparmor teardown
update-rc.d -f apparmor remove
apt-get purge -yqq apparmor* apparmor-utils

echo -e "\033[1;33mAllow adding PPA's\033[0m"
apt-get install -yqq software-properties-common
apt-get install -yqq nano

#get user home folder
export USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)

cp /etc/nanorc $USER_HOME/.nanorc
sed -i -e 's/^# include/include/' $USER_HOME/.nanorc
sed -i -e 's/^# set tabsize 8/set tabsize 4/' $USER_HOME/.nanorc
sed -i -e 's/^# set historylog/set historylog/' $USER_HOME/.nanorc
ln -s $USER_HOME/.nanorc /root/

echo -e "\033[1;33mConfiguring OpenNTPD\033[0m"
ntpdate pool.ntp.org
apt-get install openntpd
mv /etc/openntpd/ntpd.conf /etc/openntpd/ntpd.conf.orig
echo 'server 0.us.pool.ntp.org' >> /etc/openntpd/ntpd.conf
echo 'server 1.us.pool.ntp.org' >> /etc/openntpd/ntpd.conf
echo 'server 2.us.pool.ntp.org' >> /etc/openntpd/ntpd.conf
echo 'server 3.us.pool.ntp.org' >> /etc/openntpd/ntpd.conf
echo 'listen on $IPADDY' >> /etc/openntpd/ntpd.conf
service openntpd restart

echo -e "\033[1;33mConfiguring ssh\033[0m"
sed -i -e 's/^#ClientAliveInterval.*$/ClientAliveInterval 30/' /etc/ssh/sshd_config
sed -i -e 's/^#TCPKeepAlive.*$/TCPKeepAlive yes/' /etc/ssh/sshd_config
sed -i -e 's/^#ClientAliveCountMax.*$/ClientAliveCountMax 99999/' /etc/ssh/sshd_config
touch /root/.Xauthority
touch $USER_HOME/.Xauthority
mkdir -p $USER_HOME/.local/share/
mkdir -p /root/.local/share/
service ssh restart

# set to non interactive
export DEBIAN_FRONTEND=noninteractive
if [[ $DATABASE == "1" ]]; then
	echo -e "\033[1;33mInstalling Mysql Server\033[0m"
	disablepercona
	disablemaria
	disablepostgresql
	updateapt
	purgesql
	apt-get install -yqq mysql-client mysql-server
elif [[ $DATABASE == "2" ]]; then
	echo -e "\033[1;33mInstalling MariaDB Server\033[0m"
	sed -i 's/deb http:\/\/repo.percona.com/#deb http:\/\/repo.percona.com/' /etc/apt/sources.list
	sed -i 's/deb-src http:\/\/repo.percona.com/#deb-src http:\/\/repo.percona.com/' /etc/apt/sources.list
	echo "" | tee -a /etc/apt/sources.list
	if ! grep -q '#MariaDB' "/etc/apt/sources.list" ; then
			echo "" | tee -a /etc/apt/sources.list
			echo "#MariaDB" | tee -a /etc/apt/sources.list
			echo "deb http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu saucy main" | tee -a /etc/apt/sources.list
		echo "deb-src http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu saucy main" | tee -a /etc/apt/sources.list
	fi
	disablepercona
	disablepostgresql
	enablemaria
	updateapt
	purgesql
	apt-get install -yqq mariadb-server mariadb-client
elif [[ $DATABASE == "3" ]]; then
	echo -e "\033[1;33mInstalling TokuDB Engine with MariaDB Server\033[0m"
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
	echo -e "\033[1;33mInstalling Percona XtraDB Server\033[0m"
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
	disablemaria
	disablepostgresql
	enablepercona
	updateapt
	purgesql
	mkdir -p /etc/mysql
	wget --no-check-certificate https://raw2.github.com/jonnyboy/installers/master/config/my_cnf.txt -O /etc/mysql/my.cnf
	apt-get install -yqq percona-server-client-5.6 percona-server-server-5.6 percona-toolkit
elif [[ $DATABASE == "5" ]]; then
	echo -e "\033[1;33mInstalling PostGreSQL Server\033[0m"
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
	disablepercona
	disablemaria
	enablepostgresql
	updateapt
	purgesql
	apt-get -yqq install postgresql postgresql-server-dev-all
fi

#Installing Prerequirements
echo -e "\033[1;33mInstalling Nginx (engineX)\033[0m"
export nginx=stable
add-apt-repository -y ppa:nginx/$nginx
updateapt
apt-get install -yqq nginx-extras apache2-utils
mkdir -p /var/log/nginx
chmod 755 /var/log/nginx

echo -e "\033[1;33mInstalling PHP, PHP-FPM\033[0m"
add-apt-repository -y ppa:ondrej/php5
updateapt
apt-get install -yqq php5-fpm
apt-get install -yqq php5 php5-dev php-pear php5-gd php5-curl openssh-server openssl software-properties-common ca-certificates ssl-cert memcached php5-memcache php5-memcached php5-json php5-xdebug
if [[ $DATABASE == "5" ]]; then
	apt-get install -yqq php5-pgsql
else
	apt-get install -yqq php5-mysqlnd
fi

echo -e "\033[1;33mEditing PHP config files\033[0m"
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

echo -e "\033[1;33mCommpile TMUX\033[0m"
apt-get install -yqq pkg-config libncurses5-dev libevent-dev
cd /home/$SUDO_USER
git clone https://github.com/ThomasAdam/tmux.git
cd tmux
./autogen.sh
./configure && make
make install
cd /home/$SUDO_USER

mkdir -p /var/www/nZEDb
chmod 777 /var/www/nZEDb
wget --no-check-certificate https://raw2.github.com/jonnyboy/installers/master/config/nzedb_conf.txt -O /etc/nginx/sites-available/nzedb
wget --no-check-certificate https://raw2.github.com/jonnyboy/installers/master/config/nginx_conf.txt -O /etc/nginx/nginx.conf

sed -i "s/localhost/$IPADDY/" /etc/nginx/sites-available/nzedb
if ! grep -q 'fastcgi_index index.php;' "/etc/nginx/fastcgi_params" ; then
	echo "fastcgi_index index.php;" | tee -a /etc/nginx/fastcgi_params
fi
if ! grep -q 'fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;' "/etc/nginx/fastcgi_params" ; then
	echo "fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;" | tee -a /etc/nginx/fastcgi_params
fi

unlink /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/nzedb /etc/nginx/sites-enabled/nzedb

echo -e "\033[1;33mInstalling ffmpeg x264...\033[0m"

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

echo -e "\033[1;33mInstalling Mediainfo\033[0m"

add-apt-repository -y ppa:djcj/mediainfo
updateapt
apt-get install -yyq mediainfo

# These not necessary as long as the ppa stays current
#wget -c http://mediaarea.net/download/binary/libzen0/0.4.29/libzen0_0.4.29-1_amd64.xUbuntu_13.04.deb
#wget -c http://mediaarea.net/download/binary/libmediainfo0/0.7.67/libmediainfo0_0.7.67-1_amd64.xUbuntu_13.10.deb
#wget -c http://mediaarea.net/download/binary/mediainfo/0.7.67/mediainfo_0.7.67-1_amd64.Debian_7.0.deb
#dpkg -i libzen0*
#dpkg -i libmediainfo0*
#dpkg -i mediainfo*
#rm libzen0*
#rm libmediainfo0*
#rm mediainfo*

if [[ $EXTRAS == "y" ]]; then
	echo -e "\033[1;33mInstalling Extras\033[0m"
	unset DEBIAN_FRONTEND
	apt-get install -yqq nmon mytop iftop bwm-ng vnstat atop iotop ifstat htop pastebinit pigz iperf geany geany-plugins-common geany-plugins geany-plugin-spellcheck ttf-mscorefonts-installer
	apt-get install -yqq diffuse tinyca meld unrar p7zip-full make screen git gedit gitweb cifs-utils doxygen doxygen-doc samba nfs-common vlan
	mv /bin/gzip /bin/gzip.old
	ln -s /usr/bin/pigz /bin/gzip
	echo -e  "\033[1;33mCreating VNSTAT Database for ETH0\033[0m"
	chmod o+x /usr/bin/vnstat
	chmod o+wx /var/lib/vnstat/
	sudo su $SUDO_USER -c "/usr/bin/vnstat -u -i eth0"
	sed -i 's/DAEMON=\/usr\/sbin\//DAEMON=\/usr\/bin\//' /etc/init.d/vnstat
fi

if [[ $PEARMOD == "y" ]]; then
	echo -e "\033[1;33mInstalling Pear Modules\033[0m"
	pear channel-discover pear.phpdoc.org
	pear install phpdoc/phpDocumentor
	pear install --alldeps PHP_CodeSniffer
	wget http://cs.sensiolabs.org/get/php-cs-fixer.phar -O /usr/local/bin/php-cs-fixer
	pear channel-discover pear.phpunit.de
	pear install --alldeps phpunit/Diff phpunit/Exporter  phpunit/File_Iterator phpunit/FinderFacade phpunit/Git phpunit/PHPUnit phpunit/PHPUnit_MockObject phpunit/PHPUnit_Selenium phpunit/PHPUnit_SkeletonGenerator phpunit/PHPUnit_Story phpunit/PHPUnit_TestListener_DBUS phpunit/PHPUnit_TestListener_XHProf phpunit/PHPUnit_TicketListener_Fogbugz phpunit/PHPUnit_TicketListener_GitHub phpunit/PHP_CodeBrowser phpunit/PHP_CodeCoverage phpunit/PHP_Invoker phpunit/PHP_Timer phpunit/PHP_TokenStream phpunit/Text_Template phpunit/Version phpunit/bytekit phpunit/phpcov  phpunit/phpcpd phpunit/phpdcd phpunit/phploc
fi

echo -e "\033[1;33mCleaning Up\033[0m"
apt-get -yqq autoclean
apt-get -yqq autoremove

echo -e "\033[1;33mCloning nZEDb\033[0m"
git clone https://github.com/nZEDb/nZEDb.git /var/www/nZEDb
cd /var/www/nZEDb
git stash
if [[ $CHECKOUTDEV == "y" ]]; then
	cd /var/www/nZEDb
	git stash
	git checkout dev
	git stash
	ln -sv misc/update/nix/tmux/*.php .
fi

echo -e "\033[1;33mSetting File Permissions\033[0m"
cp /var/www/nZEDb/misc/update/nix/tmux/powerline/powerline/themes/default.sh /var/www/nZEDb/misc/update/nix/tmux/powerline/powerline/themes/tmux.sh
if [ -d /var/www/nZEDb/smarty/templates_c ]; then
	chmod -R 777 /var/www/nZEDb/smarty/templates_c
fi
if [ -d /var/www/nZEDb/www/covers ]; then
	chmod -R 777 /var/www/nZEDb/www/covers
fi
if [ -d /var/www/nZEDb/nzbfiles ]; then
	chmod -R 777 /var/www/nZEDb/nzbfiles
fi
if [ -d /var/www/nZEDb/www ]; then
	chmod 777 /var/www/nZEDb/www
fi
if [ -d /var/www/nZEDb/resources ]; then
	chmod -R 777 /var/www/nZEDb/resources
fi
if [ -d /var/www/nZEDb/www/install ]; then
	chmod 777 /var/www/nZEDb/www/install
fi
if [ -d /var/www ]; then
	chown -R $SUDO_USER:www-data /var/www
fi

if [[ $PYTHONTWO == "y" ]]; then
	echo -e "\033[1;33mInstalling Python 2 modules to your user's home folder, they are not installed globally\033[0m"
	apt-get install -yqq python-setuptools python-pip python-dev python-software-properties
	if [[ $DATABASE == "5" ]]; then
		pip install --user psycopg2
	else
		pip install --user cymysql
	fi
	pip install --user socketpool
	pip install --user pynntp
fi

if [[ $PYTHONTHREE == "y" ]]; then
	echo -e "\033[1;33mInstalling Python 3 modules to your user's home folder, they are not installed globally\033[0m"
	apt-get install -yqq python3-setuptools python3-pip python3-dev python-software-properties
	if [[ $DATABASE == "5" ]]; then
		pip3 install --user psycopg2
	else
		pip3 install --user cymysql
	fi
	# does not work in python3
	#pip3 install --user socketpool
	#pip3 install --user pynntp
fi

#create tmpunrar ramdisk
export phymem=$(free -g|awk '/^Mem:/{print $2}')
if [[ $phymem -gt 3 ]]; then
	if [ -d /var/www/nZEDb/resources/tmp/unrar ]; then
		export uid=`id -u $SUDO_USER`
		export gid=`id -u www-data`
		echo "tmpfs /var/www/nZEDb/resources/tmp/unrar tmpfs user,uid=${uid},gid=${gid},nodev,nodiratime,nosuid,size=1G,mode=777 0 0" >> /etc/fstab
		mount /var/www/nZEDb/resources/tmp/unrar
	fi
fi

if [[ $EXTRAS == "y" ]]; then
	echo -e "\033[1;33mSet Secure Password for Samba\033[0m"
	smbpasswd -a $SUDO_USER
fi

#install addminer
echo -e "\033[1;33mInstalling Adminer to www/adminer.php\033[0m"
wget http://www.adminer.org/latest.php -O /var/www/nZEDb/www/adminer.php

#install PhpStorm
if [[ $PHPSTORM == "y" ]]; then
	cd $USER_HOME
	apt-get purge -yqq openjdk*
	add-apt-repository -y ppa:webupd8team/java
	updateapt
	apt-get install oracle-java7-installer
	wget http://download.jetbrains.com/webide/PhpStorm-7.1.3.tar.gz
	tar xfz PhpStorm-7.1.3.tar.gz
	chmod +x PhpStorm-133.982/bin/phpstorm.sh
	echo "" >> $USER_HOME/.profile
	echo "# set PATH so it includes user's private PhpStorm bin if it exists" >> $USER_HOME/.profile
	echo 'if [ -d "$HOME/PhpStorm-133.982/bin" ] ; then' >> $USER_HOME/.profile
	echo '	PATH="$HOME/PhpStorm-133.982/bin:$PATH"' >> $USER_HOME/.profile
	echo 'fi' >> $USER_HOME/.profile
	ln -s PhpStorm-133.982/bin/phpstorm.sh $USER_HOME
fi

#ssl
echo -e "\033[1;33mCreating Self Signed Certificate\033[0m"
mkdir -p /etc/ssl/nginx/conf
cd /etc/ssl/nginx/conf
echo -e "\033[1;33mEnter a Secure password\033[0m"
openssl genrsa -des3 -out server.key 4096
echo -e "\033[1;33mRe-enter a Secure password\033[0m"
openssl req -new -key server.key -out server.csr
cp server.key server.key.org
echo -e "\033[1;33mRe-enter a Secure password\033[0m"
openssl rsa -in server.key.org -out server.key
echo -e "\033[1;33mRe-enter a Secure password\033[0m"
openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt

service php5-fpm stop
service php5-fpm start
service nginx restart

# chown your users folder
chown -R $SUDO_USER:$SUDO_USER $USER_HOME

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
	echo -e "\033[1;33mMySQL password for root is blank.\033[0m"
	mysql_secure_installation
fi

clear
echo -e "\033[1;33m-----------------------------------------------"
echo -e "\033[1;33mInstall Complete...."
echo "Go to https://$IPADDY to finish nZEDb install."
echo "Adminer is located at  https://$IPADDY/adminer.php."
echo "For questions and problems log on to #nZEDb on irc.Synirc.net"
echo -e "\n\n\033[0m"
exit
