#!/bin/sh
#set -e on

CURPATH=$(pwd)
REV=${REV:-"latest"}
REV=$(basename $(readlink -f $REV))
if [ -z "$REV" ]; then
	echo "failed to find image builder directory."
	exit 1
fi
BRAND=${BRAND:-"waffle"}
TARGET=${TARGET:-"ar71xx"}
SUBTARGET=${SUBTARGET:-"generic"}
FILES=${FILES:-"files"}
NO_FILES=${NO_FILES:-""}
PROFILE=${PROFILE:-""}
PROFILE_8M=${PROFILE_8M:-""}
PROFILE_16M=${PROFILE_16M:-""}
case "$TARGET" in
  ar71xx)
    PROFILE="$PROFILE TLWR841"
    PROFILE_8M="$PROFILE_8M TLWR842 TLWDR4300"
    PROFILE_16M="$PROFILE_16M"
  ;;
  ralink)
    PROFILE_16M="$PROFILE_16M ZBT-WE826 XIAOMI-MIWIFI-MINI"
  ;;
  ramips)
    PROFILE_8M="$PROFILE_8M ArcherC2"
    PROFILE_16M="$PROFILE_16M MIWIFI-MINI WF-2881 SAP-G3200U3"
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
	[ -z "$NO_FILES" ] && {
	    if [ -d "$rev/files" ]; then
	        rm -rfv "$rev/files"
	    fi
	    mkdir -pv "$rev/files"

	    for i in $(ls $CURPATH/$FILES); do
	        cp -fpRv "$CURPATH/$FILES/$i" "$rev/files/" ;
	    done
	}
	[ ! -z "$NO_FILES" ] && {
		rm -rfv "$rev/files"
	}

    cd $rev && {
        make clean
        for i in $PROFILE; do
			[ -z "$NO_FILES" ] && make image PROFILE=$i PACKAGES="$PACKAGES" FILES="files"
			[ ! -z "$NO_FILES" ] && make image PROFILE=$i PACKAGES="$PACKAGES" FILES=
        done
        for i in $PROFILE_8M; do
			[ -z "$NO_FILES" ] && make image PROFILE=$i PACKAGES="$PACKAGES_8M" FILES="files"
            [ ! -z "$NO_FILES" ] && make image PROFILE=$i PACKAGES="$PACKAGES_8M" FILES=
        done
        for i in $PROFILE_16M; do
			[ -z "$NO_FILES" ] && make image PROFILE=$i PACKAGES="$PACKAGES_16M" FILES="files"
            [ ! -z "$NO_FILES" ] && make image PROFILE=$i PACKAGES="$PACKAGES_16M" FILES=
        done
    }
}

upload_firmware() { # <rev> <files> <target> [subtarget=generic] [brand=Waffle]
	local rev files target subtarget brand version branch dirname fw_dir remote_dir
    rev="$1"; shift;
	files="$1"; shift;
	target="$1"; shift;
	[ ! -z "$1" ] && { subtarget="$1"; shift; }
	subtarget=${subtarget:-"generic"}
	[ ! -z "$1" ] && { brand="$1"; shift; }
	brand=${brand:-"Waffle"}
	fw_dir="$rev"
	[ -z "$NO_FILES" ] && {
	    version="$(cd $files && git describe --always --tags --dirty=m)"
	    branch="$(cd $files && git branch)"
	    branch="${branch##* }"
	    dirname="${files##files_}"
	    fw_dir="${fw_dir}-${dirname}-${version}"
	}
    remote_dir="$TARGET_PATH/$fw_dir"

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

[ -z "$NO_FILES" ] && cd $FILES && {
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

