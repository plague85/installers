#!/usr/bin/env bash

apt-get -qq update
apt-get remove -qq ffmpeg x264 libav-tools libvpx-dev libx264-dev yasm fdk-aac

apt-get install -qq autoconf automake build-essential checkinstall git libass-dev libfaac-dev libgpac-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev librtmp-dev libspeex-dev libtheora-dev libtool libvorbis-dev pkg-config texi2html zlib1g-dev

cd /tmp
wget http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz
tar xzvf yasm-1.2.0.tar.gz
cd yasm-1.2.0
./configure
make && checkinstall --pkgname=yasm --pkgversion="1.2.0" --backup=no --deldoc=yes --default

git clone --depth 1 git://git.videolan.org/x264 /tmp/x264
cd /tmp/x264
./configure --enable-static
make && checkinstall --pkgname=x264 --pkgversion="3:$(./version.sh | awk -F'[" ]' '/POINT/{print $4"+git"$5}')" --backup=no --deldoc=yes --fstrans=no --default

git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git /tmp/fdk-aac
cd /tmp/fdk-aac
autoreconf -fiv
./configure --disable-shared
make && checkinstall --pkgname=fdk-aac --pkgversion="$(date +%Y%m%d%H%M)-git" --backup=no --deldoc=yes --fstrans=no --default

git clone --depth 1 http://git.chromium.org/webm/libvpx.git /tmp/libvpx
cd /tmp/libvpx
./configure
make && checkinstall --pkgname=libvpx --pkgversion="1:$(date +%Y%m%d%H%M)-git" --backup=no --deldoc=yes --fstrans=no --default

git clone --depth 1 git://source.ffmpeg.org/ffmpeg /tmp/ffmpeg
cd /tmp/ffmpeg
./configure --enable-gpl --enable-libfaac --enable-libfdk-aac --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-librtmp --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx264 --enable-nonfree --enable-version3
make && checkinstall --pkgname=ffmpeg --pkgversion="7:$(date +%Y%m%d%H%M)-git" --backup=no --deldoc=yes --fstrans=no --default

apt-get install -qq libavcodec-extra-53 libav-tools
hash x264 ffmpeg ffprobe

cd /tmp/ffmpeg
make tools/qt-faststart
sudo checkinstall --pkgname=qt-faststart --pkgversion="$(date +%Y%m%d%H%M)-git" --backup=no --deldoc=yes --fstrans=no --default install -Dm755 tools/qt-faststart /usr/local/bin/qt-faststart

cd /tmp/x264
make distclean
./configure --enable-static
make && checkinstall --pkgname=x264 --pkgversion="3:$(./version.sh | awk -F'[" ]' '/POINT/{print $4"+git"$5}')" --backup=no --deldoc=yes --fstrans=no --default

apt-get install -qq unrar lame mediainfo

clear
echo "ffmpeg x264 mediainfo unrar lame is now installed..."
sleep 5
