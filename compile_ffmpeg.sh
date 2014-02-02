#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
    echo "You must be root to do this." 1>&2
    exit
fi

#get user home folder
export USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)

apt-get -qq update
apt-get remove -qq ffmpeg x264 libav-tools libvpx-dev libx264-dev
apt-get remove -qq fdk-aac

apt-get install -qq autoconf automake build-essential checkinstall git libass-dev libfaac-dev libgpac-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev \
librtmp-dev libspeex-dev libtheora-dev libtool libvorbis-dev pkg-config texi2html zlib1g-dev libjack-jackd2-dev libsdl1.2-dev libva-dev libvdpau-dev libx11-dev libxfixes-dev yasm

mkdir -p $USER_HOME/ffmpeg_build
mkdir -p $USER_HOME/bin
mkdir -p $USER_HOME/ffmpeg_sources

##x264 lib
git clone --depth 1 git://git.videolan.org/x264 $USER_HOME/ffmpeg_sources/x264
cd $USER_HOME/ffmpeg_sources/x264
./configure --prefix="$USER_HOME/ffmpeg_build" --bindir="$USER_HOME/bin" --enable-static --disable-opencl
make
make install

##aac lib
git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git $USER_HOME/ffmpeg_sources/fdk-aac
cd $USER_HOME/ffmpeg_sources/fdk-aac
autoreconf -fiv
./configure --prefix="$USER_HOME/ffmpeg_build" --disable-shared
make
make install
make distclean

##opus lib
cd $USER_HOME/ffmpeg_sources
wget -c http://downloads.xiph.org/releases/opus/opus-1.1.tar.gz
tar xzvf opus-1.1.tar.gz
cd opus-1.1
./configure --prefix="$USER_HOME/ffmpeg_build" --disable-shared
make
make install
make distclean

##vpx lib
git clone --depth 1 http://git.chromium.org/webm/libvpx.git $USER_HOME/ffmpeg_sources/libvpx
cd $USER_HOME/ffmpeg_sources/libvpx
./configure --prefix="$USER_HOME/ffmpeg_build" --disable-examples
make
make install
make clean

##build ffmpeg
git clone --depth 1 git://source.ffmpeg.org/ffmpeg $USER_HOME/ffmpeg_sources/ffmpeg
cd $USER_HOME/ffmpeg_sources/ffmpeg
export PKG_CONFIG_PATH="$USER_HOME/ffmpeg_build/lib/pkgconfig"
./configure --prefix="$USER_HOME/ffmpeg_build" --extra-cflags="-I$USER_HOME/ffmpeg_build/include" --extra-ldflags="-L$USER_HOME/ffmpeg_build/lib" \
  --bindir="$USER_HOME/bin" --extra-libs="-ldl" --enable-gpl --enable-libass --enable-libfdk-aac \
  --enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libvpx \
  --enable-libx264 --enable-nonfree --enable-libfaac --enable-librtmp --enable-libtheora \
  --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-x11grab --enable-version3
make
make install


apt-get install -qq libavcodec-extra-53 libav-tools
hash x264 ffmpeg ffplay ffprobe

##build qt-faststart
cd $USER_HOME/ffmpeg_sources/ffmpeg
make tools/qt-faststart
make install
make distclean

##lavf support in x264
cd $USER_HOME/ffmpeg_sources/x264
make distclean
./configure --prefix="$USER_HOME/ffmpeg_build" --bindir="$USER_HOME/bin" --enable-static --disable-opencl
make
make install
make distclean

apt-get install -qq lame

# chown your users folder
chown -R $SUDO_USER:$SUDO_USER $USER_HOME/bin
chown -R $SUDO_USER:$SUDO_USER $USER_HOME/ffmpeg_build
chown -R $SUDO_USER:$SUDO_USER $USER_HOME/ffmpeg_sources

clear
echo "ffmpeg, x264 and lame are now installed..."
sleep 5
