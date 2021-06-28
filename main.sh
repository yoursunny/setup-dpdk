#!/bin/bash
set -e
set -o pipefail

# Install all dependencies based on the OS distribution
if [ -n "$(command -v apt-get)" ]; then
  sudo apt-get update;
  sudo apt-get -y install \
    jq \
    ninja-build \
    python3 \
    python3-pip \
    python3-pyelftools \
    python3-setuptools \
    python3-wheel
    
  sudo pip3 install meson
fi

CODEROOT=$HOME/setup-dpdk
mkdir -p $CODEROOT/dpdk_$DPDKVER

cd $CODEROOT/dpdk_$DPDKVER
if ! [[ -f meson.build ]]; then
  curl -sfL https://static.dpdk.org/rel/dpdk-$DPDKVER.tar.xz | tar -xJ --strip-components=1
fi

if jq -e '.meson_version.full != "'$(meson --version)'"' build/meson-info/meson-info.json &>/dev/null; then
  rm -rf build/
fi

if ! [[ -f build/lib/librte_eal.a ]]; then
  meson -Ddebug=true -Doptimization=3 -Dmachine=$TARGETARCH -Dtests=false --libdir=lib build
  ninja -C build
fi
sudo ninja -C build install
sudo find /usr/local/lib -name 'librte_*.a' -delete
sudo ldconfig

if ! [[ -z $SPDKVER ]] && [[ -n $SPDKVER ]] && [[ $SPDKVER != "none" ]]; then
  mkdir -p  $CODEROOT/spdk_$SPDKVER
  cd $CODEROOT/spdk_$SPDKVER
  if ! [[ -f scripts/pkgdep.sh ]]; then
    curl -sfL https://github.com/spdk/spdk/archive/v$SPDKVER.tar.gz | tar -xz --strip-components=1
  fi

  sudo scripts/pkgdep.sh

  cd $CODEROOT/spdk_$SPDKVER
  if ! [[ -f build/lib/libspdk_env_dpdk.a ]]; then
    ./configure --target-arch=$TARGETARCH --enable-debug --disable-tests --with-shared \
      --with-dpdk=/usr/local --without-vhost --without-isal --without-fuse
    make -j$(nproc)
  fi
  sudo make install
  sudo find /usr/local/lib -name 'libspdk_*.a' -delete
  sudo ldconfig
fi

if [[ $NRHUGE -gt 0 ]]; then
  echo $NRHUGE | sudo tee /sys/devices/system/node/node*/hugepages/hugepages-2048kB/nr_hugepages >/dev/null
  sudo mkdir -p /mnt/huge2M
  sudo mount -t hugetlbfs nodev /mnt/huge2M -o pagesize=2M
fi
