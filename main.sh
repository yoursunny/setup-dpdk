#!/bin/bash
set -e
set -o pipefail

mkdir -p $GITHUB_WORKSPACE/setup-dpdk/dpdk_$DPDKVER $GITHUB_WORKSPACE/setup-dpdk/spdk_$SPDKVER

cd $GITHUB_WORKSPACE/setup-dpdk/spdk_$SPDKVER
curl -sL https://github.com/spdk/spdk/archive/v$SPDKVER.tar.gz | tar -xz --strip-components=1
sudo apt-get install python3-setuptools
sudo scripts/pkgdep.sh

cd $GITHUB_WORKSPACE/setup-dpdk/dpdk_$DPDKVER
curl -sL https://static.dpdk.org/rel/dpdk-$DPDKVER.tar.xz | tar -xJ --strip-components=1
meson -Dtests=false --libdir=lib build
ninja -C build
sudo ninja -C build install
sudo find /usr/local/lib -name 'librte_*.a' -delete
sudo ldconfig

cd $GITHUB_WORKSPACE/setup-dpdk/spdk_$SPDKVER
./configure --enable-debug --disable-tests --with-shared \
  --with-dpdk=/usr/local --without-vhost --without-isal --without-fuse
make -j$(nproc)
sudo make install
sudo find /usr/local/lib -name 'libspdk_*.a' -delete
sudo ldconfig

if [[ $NRHUGE -gt 0 ]]; then
  echo $NRHUGE | sudo tee /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages >/dev/null
  sudo mkdir -p /mnt/huge2M
  sudo mount -t hugetlbfs nodev /mnt/huge2M -o pagesize=2M
fi
