#!/bin/sh
#set -e on

CURPATH=$(pwd)
REV=${REV:-"latest"}
#BB_REV=${BB_REV:-"bb_stable"}
#TRUNK_REV=${TRUNK_REV:-"trunk"}
PROFILE=${PROFILE:-""}
PROFILE="$PROFILE TLWR841"
PROFILE_8M=${PROFILE_8M:-""}
PROFILE_8M="$PROFILE_8M TLWR842 TLWDR4300 OM2P"
PACKAGES=${PACKAGES:-""}
PACKAGES="$PACKAGES luci luci-app-qos luci-app-p2pblock n2n-v2 coova-chilli kmod-ipt-coova"
PACKAGES_8M=${PACKAGES_8M:-""}
PACKAGES_8M="$PACKAGES $PACKAGES_8M curl"
FILES=${FILES:-"files"}
TARGET=${TARGET:-"ar71xx"}
target_path="$HOME/Dropbox/firmware"
ncfscmd="CLI/ncfscmd.sh"
ncfscmd_mkdir="mkdir -pv"
ncfscmd_put="cp -fpv"
ncfshome="CLI/lib"
export PATH=$(brew --prefix coreutils)/libexec/gnubin:$PATH

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
    }
}

upload_firmware() { # <rev>
    local rev="$1"
    local version="$(cd $FILES && git describe)"
    local branch="$(cd $FILES && git branch)"
    branch="${branch##* }"
    local dirname="${FILES##files_}"
    local fw_dir="$rev-$dirname-$version"
    local remote_dir="$target_path/$fw_dir"

    NCFS_HOME="$ncfshome" $ncfscmd_mkdir $remote_dir
    for i in $(ls $rev/bin/ar71xx/*-factory.bin); do
        NCFS_HOME="$ncfshome" $ncfscmd_put $i $remote_dir
    done
    for i in $(ls $rev/bin/ar71xx/*-sysupgrade.bin); do
        NCFS_HOME="$ncfshome" $ncfscmd_put $i $remote_dir
    done
}

cd $FILES && {
    [ -e .git ] && {
        git stash
        git checkout -f
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
ls $REV/bin/ar71xx/*.bin

# upload firmware
upload_firmware $REV

