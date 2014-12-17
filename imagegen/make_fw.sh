#!/bin/sh
#set -e on

CURPATH=$(pwd)
REV=${REV:-"latest"}
#BB_REV=${BB_REV:-"bb_stable"}
#TRUNK_REV=${TRUNK_REV:-"trunk"}
PACKAGES=${PACKAGES:-""}
PACKAGES="$PACKAGES luci luci-app-qos luci-app-p2pblock n2n-v2 coova-chilli"
PACKAGES_8M=${PACKAGES_8M:-""}
PACKAGES_8M="$PACKAGES $PACKAGES_8M curl wget"
FILES=${FILES:-"files"}
TARGET=${TARGET:-"ar71xx"}
target_path="$HOME/Dropbox/firmware"
ncfscmd="CLI/ncfscmd.sh"
ncfscmd_mkdir="mkdir -p"
ncfscmd_put="cp"
ncfshome="CLI/lib"
export PATH=$(brew --prefix coreutils)/libexec/gnubin:$PATH

make_firmware() { # <rev>
    local rev="$1"
    cd $rev && {
        make clean
        make image PROFILE=TLWR841 PACKAGES="$PACKAGES" FILES=files
        make image PROFILE=TLWR842 PACKAGES="$PACKAGES_8M" FILES=files
        make image PROFILE=TLWDR4300 PACKAGES="$PACKAGES_8M" FILES=files
        make image PROFILE=OM2P PACKAGES="$PACKAGES_8M" FILES=files
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
    for i in $(ls $rev/bin/ar71xx/*.bin); do
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

cd $CURPATH
# copy additional root files
if [ -d $REV/files ]; then
    rm -rf $REV/files
fi
mkdir -p $REV/files

#if [ -d $TRUNK_REV/files ]; then
#    rm -rf $TRUNK_REV/files
#fi
#mkdir -p $TRUNK_REV/files

for i in $(ls $FILES); do
    cp -fpR $FILES/$i $REV/files/ ;
#    cp -fpR $FILES/$i $BB_REV/files/ ;
#    cp -fpR $FILES/$i $TRUNK_REV/files/ ;
done

#cd $CURPATH/$REV && {
#    if [ ! -e packages/n2n-v2_6603-1_ar71xx.ipk ]; then
#        rm -f packages/Packages*
#        wget -qO packages/n2n-v2_6603-1_ar71xx.ipk http://ecco.selfip.net/attitude_adjustment/ar71xx/packages/n2n-v2_6603-1_ar71xx.ipk
#    fi
#}

make_firmware $CURPATH/$REV
#make_firmware $CURPATH/$BB_REV
#make_firmware $CURPATH/$TRUNK_REV

# show firmware
cd $CURPATH
ls $REV/bin/ar71xx/*.bin
#ls $BB_REV/bin/ar71xx/*.bin
#ls $TRUNK_REV/bin/ar71xx/*.bin

# upload firmware
upload_firmware $REV
#upload_firmware $BB_REV
#upload_firmware $TRUNK_REV

