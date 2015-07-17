Waffle_Firmware
===============

### How to Compile

```bash
git clone https://github.com/LeeNCompanyInc/Waffle_Firmware
cd Waffle_Firmware
git submodule update --init --recursive
cd barrier_breaker # for 14.07
cat feeds.conf.default | sed -e 's/openwrt\/packages.git;for-14.07/LeeNCompanyInc\/openwrt-packages.git;for-waffle/' > feeds.conf
echo "src-git wafl_packages https://github.com/LeeNCompanyInc/packages.git;for-14.07" >> feeds.conf
./scripts/feeds update -a
./scripts/feeds install -a
cp ../.config_bb .config
make defconfig
echo "r$(git log -1 --pretty origin/master|grep git-svn-id|awk '{print $2;}'|awk -F@ '{print $2}')" > version
make
```
