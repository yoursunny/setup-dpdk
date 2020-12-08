#!/bin/bash
set -e
set -o pipefail

mkdir -p $HOME/setup-dpdk/dpdk_$DPDKVER $HOME/setup-dpdk/spdk_$SPDKVER
cd $HOME/setup-dpdk
CACHEFILE=$HOME/setup-dpdk.cache.txz
if [[ -f $CACHEFILE ]]; then
  tar -xJf $CACHEFILE
fi

cd $HOME/setup-dpdk/spdk_$SPDKVER
if ! [[ -f scripts/pkgdep.sh ]]; then
  curl -sL https://github.com/spdk/spdk/archive/v$SPDKVER.tar.gz | tar -xz --strip-components=1
fi
sudo apt-get install python3-setuptools
sudo scripts/pkgdep.sh

MESONVER=$(meson --version)

cd $HOME/setup-dpdk/dpdk_$DPDKVER
if ! [[ -f meson.build ]]; then
  curl -sL https://static.dpdk.org/rel/dpdk-$DPDKVER.tar.xz | tar -xJ --strip-components=1
fi
if jq -e '.meson_version.full != "'$(meson --version)'"' build/meson-info/meson-info.json &>/dev/null; then
  rm -rf build/
fi
if ! [[ -f build/lib/librte_eal.a ]]; then
  meson -Ddebug=true -Doptimization=3 -Dmachine=$ARCH -Dtests=false --libdir=lib build
  ninja -C build
fi
sudo ninja -C build install
sudo find /usr/local/lib -name 'librte_*.a' -delete
sudo ldconfig

cd $HOME/setup-dpdk/spdk_$SPDKVER
if ! [[ -f build/lib/libspdk_env_dpdk.a ]]; then
  ./configure --target-arch=$ARCH --enable-debug --disable-tests --with-shared \
    --with-dpdk=/usr/local --without-vhost --without-isal --without-fuse
  make -j$(nproc)
fi
sudo make install
sudo find /usr/local/lib -name 'libspdk_*.a' -delete
sudo ldconfig

cd $HOME/setup-dpdk
tar -cJf $CACHEFILE dpdk_$DPDKVER spdk_$SPDKVER

if [[ $NRHUGE -gt 0 ]]; then
  echo $NRHUGE | sudo tee /sys/devices/system/node/node*/hugepages/hugepages-2048kB/nr_hugepages >/dev/null
  sudo mkdir -p /mnt/huge2M
  sudo mount -t hugetlbfs nodev /mnt/huge2M -o pagesize=2M
fi
