#!/bin/sh
#set -e on

CURPATH=$(pwd)
REV=${REV:-"latest"}
REV=$(basename $(readlink -f $REV))
if [ -z "$REV" ]; then
	echo "failed to find image builder directory."
	exit 1
fi
#BB_REV=${BB_REV:-"bb_stable"}
#TRUNK_REV=${TRUNK_REV:-"trunk"}
BRAND=${BRAND:-"waffle"}
TARGET=${TARGET:-"ar71xx"}
SUBTARGET=${SUBTARGET:-"generic"}
FILES=${FILES:-"files"}
PROFILE=${PROFILE:-""}
PROFILE_8M=${PROFILE_8M:-""}
PROFILE_16M=${PROFILE_16M:-""}
case "$TARGET" in
  ar71xx)
  PROFILE="$PROFILE TLWR841"
  PROFILE_8M="$PROFILE_8M TLWR842 TLWDR4300"
  PROFILE_16M="$PROFILE_16M"
  ;;
  ralink|\
  ramips)
  PROFILE_16M="$PROFILE_16M ZBT-WE826 XIAOMI-MIWIFI-MINI"
  ;;
esac
PACKAGES=${PACKAGES:-""}
PACKAGES="$PACKAGES luci luci-app-qos luci-app-p2pblock n2n-v2 coova-chilli"
if [ "" != "$(cat $REV/.config|grep kmod-ipt-coova)" ]; then
	PACKAGES="$PACKAGES kmod-ipt-coova"
fi
PACKAGES_8M=${PACKAGES_8M:-""}
PACKAGES_8M="$PACKAGES $PACKAGES_8M curl"
PACKAGES_16M=${PACKAGES_16M:-""}
PACKAGES_16M="$PACKAGES $PACKAGES_8M $PACKAGES_16M"
TARGET_PATH=${TARGET_PATH:-"$HOME/Dropbox/firmware"}
ncfscmd="CLI/ncfscmd.sh"
ncfscmd_mkdir="mkdir -pv"
ncfscmd_put="cp -fpv"
ncfshome="CLI/lib"
if [ -n "$(brew --prefix coreutils)" ]
then
  export PATH=$(brew --prefix coreutils)/libexec/gnubin:$PATH
fi

make_firmware() { # <rev>
    local rev="$1"
    # copy additional root files
    if [ -d $rev/files ]; then
        rm -rfv $rev/files
    fi
    mkdir -pv $rev/files

    for i in $(ls $CURPATH/$FILES); do
        cp -fpRv $CURPATH/$FILES/$i $rev/files/ ;
    done

    cd $rev && {
        make clean
        for i in $PROFILE; do
            make image PROFILE=$i PACKAGES="$PACKAGES" FILES=files
        done
        for i in $PROFILE_8M; do
            make image PROFILE=$i PACKAGES="$PACKAGES_8M" FILES=files
        done
        for i in $PROFILE_16M; do
            make image PROFILE=$i PACKAGES="$PACKAGES_16M" FILES=files
        done
    }
}

upload_firmware() { # <rev> <files> <target> [subtarget=generic] [brand=Waffle]
    local rev="$1"
	local files="$2"
	local target="$3"
	local subtarget="$4"
	subtarget=${subtarget:-"generic"}
	local brand="$5"
	brand=${brand:-"Waffle"}
    local version="$(cd $files && git describe --always --tags --dirty=m)"
    local branch="$(cd $files && git branch)"
    branch="${branch##* }"
    local dirname="${files##files_}"
    local fw_dir="$rev-$dirname-$version"
    local remote_dir="$TARGET_PATH/$fw_dir"

    NCFS_HOME="$ncfshome" $ncfscmd_mkdir $remote_dir
    for i in $(ls $rev/bin/$target/*-factory.bin 2>/dev/null); do
        filename=$(basename $i)
        filename=${filename/openwrt-*?$target-$subtarget/$brand}
        filename=${filename/-squashfs-factory/}
        NCFS_HOME="$ncfshome" $ncfscmd_put $i "$remote_dir/$filename"
    done
    for i in $(ls $rev/bin/$target/*-sysupgrade.bin 2>/dev/null); do
        filename=$(basename $i)
        filename=${filename/openwrt-*?$target-$subtarget/$brand}
        filename=${filename/-squashfs-sysupgrade/-upgrade}
        NCFS_HOME="$ncfshome" $ncfscmd_put $i "$remote_dir/$filename"
    done
}

cd $FILES && {
    [ -e .git ] && {
        git stash
        git checkout -f
        git fetch --all --tags
        git pull -f
        git stash pop
    }
    chmod 755 etc/dropbear
    chmod 444 etc/dropbear/authorized_keys
    chmod +x etc/init.d/*
}

make_firmware $CURPATH/$REV

# show firmware
cd $CURPATH
ls $REV/bin/$TARGET/*.bin

# upload firmware
upload_firmware $REV $FILES $TARGET $SUBTARGET $BRAND

