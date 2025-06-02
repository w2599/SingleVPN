#!/bin/bash
export LC_ALL=C
export THEOS=/Users/zqbb/theos_roothide
export THEOS_DEVICE_IP=192.168.31.158
export THEOS_DEVICE_PORT=2222
export ARCHS="arm64e"


tweakPath=$(cd "$(dirname "$0")";pwd)
buildPath="$(dirname "$tweakPath")/__build_roothide/$(basename "$tweakPath")"
echo "tweakPath: $tweakPath"
echo "buildPath: $buildPath"
rm -rf $buildPath && mkdir -p $buildPath && cp -a $tweakPath/ $buildPath && cd $buildPath


versionFor="1.5"
sed -i '' "s/^\(Version:\s*\).*/\1 ${versionFor}/" control
echo "versionFor: $versionFor"


if [ $1 -eq "0" ]
then
    export package FINALPACKAGE=1
	export THEOS_PACKAGE_SCHEME=roothide

	make do -j$(sysctl -n hw.physicalcpu)
	cp -f ./packages/*.deb /Users/zqbb/Documents/GitHub/myTweaks/roothide/
	exit
fi


export THEOS_PACKAGE_SCHEME=roothide
make do 
