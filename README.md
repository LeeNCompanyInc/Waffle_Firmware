Waffle_Firmware
===============

### Get the Source
```bash
git clone https://github.com/LeeNCompanyInc/Waffle_Firmware
cd Waffle_Firmware
git submodule update --init --recursive
```

### How to Compile (14.07)

```bash
cd barrier_breaker
cat feeds.conf.default | sed -e 's/openwrt\/packages.git;for-14.07/LeeNCompanyInc\/openwrt-packages.git;for-waffle/' > feeds.conf
echo "src-git wafl_packages https://github.com/LeeNCompanyInc/packages.git;for-14.07" >> feeds.conf
./scripts/feeds update -a
./scripts/feeds install -a
cp ../.config_bb .config
make defconfig
echo "r$(git log -1 --pretty origin/master|grep git-svn-id|awk '{print $2;}'|awk -F@ '{print $2}')" > version
make
```

### How to Compile (15.05)

```bash
cd chaos_calmer
cp feeds.conf{.default,}
echo "src-git wafl_packages https://github.com/LeeNCompanyInc/packages.git;for-15.05" >> feeds.conf
./scripts/feeds update -a
./scripts/feeds install -a
cp ../.config_cc .config
make defconfig
echo "r$(git log -1 --pretty origin/master|grep git-svn-id|awk '{print $2;}'|awk -F@ '{print $2}')" > version
make
```
