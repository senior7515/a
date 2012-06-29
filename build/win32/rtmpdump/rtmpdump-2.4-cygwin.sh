#!/bin/sh
host=i686-w64-mingw32

# Install Cygwin packages
./setup -nqs ftp://lug.mtu.edu/cygwin -P git,make,mingw64-i686-gcc-core,wget

# Install Zlib
wget zlib.net/zlib-1.2.7.tar.bz2
tar xf zlib*
cd zlib*
make install -f win32/Makefile.gcc BINARY_PATH="/bin" \
	DESTDIR="/usr/$host/sys-root/mingw" INCLUDE_PATH="/include" \
	LIBRARY_PATH="/lib" PREFIX="$host-"
cd -

# Determine correct PolarSSL
git clone git://git.ffmpeg.org/rtmpdump
cd rtmpdump
v='0.14.3'
grep -r ciphersuite * && v='1.0.0'
grep -r havege_random * && v='1.1.3'
cd -

# Install PolarSSL
wget polarssl.org/code/releases/polarssl-$v-gpl.tgz
tar xf polarssl*
cd polarssl*
make APPS= AR="$host-ar" CC="$host-gcc"
make install DESTDIR="/usr/$host/sys-root/mingw"
cd -

# Install RtmpDump
cd rtmpdump
git tag 'v2.4' 'c28f1ba'
# Build
make CROSS_COMPILE="$host-" CRYPTO=POLARSSL SHARED= SYS=mingw XLDFLAGS=-static \
	VERSION=$(git describe --tags)

# Build librtmp.dll
make CROSS_COMPILE="$host-" CRYPTO=POLARSSL SYS=mingw
