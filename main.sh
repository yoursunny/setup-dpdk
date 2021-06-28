#!/bin/bash
set -eo pipefail
CODEROOT=$HOME/setup-dpdk

install_dependencies() {
  local APT_PKGS=(
    libnuma-dev
    python3-pip
    python3-pyelftools
    python3-setuptools
    python3-wheel
  )
  if ! which ninja >/dev/null; then
    APT_PKGS+=(ninja-build)
  fi

  sudo apt-get -y -qq update
  sudo apt-get -y -qq --no-install-recommends install "${APT_PKGS[@]}"

  if ! which meson >/dev/null; then
    sudo pip3 install meson
  fi
}

install_dpdk() {
  mkdir -p $CODEROOT/dpdk_$DPDKVER
  cd $CODEROOT/dpdk_$DPDKVER
  if ! [[ -f meson.build ]]; then
    curl -sfL https://static.dpdk.org/rel/dpdk-$DPDKVER.tar.xz | tar -xJ --strip-components=1
  fi

  if jq -e --arg mesonver $(meson --version) '.meson_version.full != $mesonver' build/meson-info/meson-info.json &>/dev/null; then
    rm -rf build/
  fi

  if ! [[ -f build/lib/librte_eal.a ]]; then
    meson -Ddebug=true -Doptimization=3 -Dmachine=$TARGETARCH -Dtests=false --libdir=lib build
    ninja -C build
  fi
  sudo ninja -C build install
  sudo find /usr/local/lib -name 'librte_*.a' -delete
  sudo ldconfig
}

install_spdk() {
  mkdir -p  $CODEROOT/spdk_$SPDKVER
  cd $CODEROOT/spdk_$SPDKVER
  if ! [[ -f scripts/pkgdep.sh ]]; then
    curl -sfL https://github.com/spdk/spdk/archive/v$SPDKVER.tar.gz | tar -xz --strip-components=1
  fi
  sudo scripts/pkgdep.sh

  if ! [[ -f build/lib/libspdk_env_dpdk.a ]]; then
    ./configure --target-arch=$TARGETARCH --enable-debug --disable-tests --with-shared \
      --with-dpdk=/usr/local --without-vhost --without-isal --without-fuse
    make -j$(nproc)
  fi
  sudo make install
  sudo find /usr/local/lib -name 'libspdk_*.a' -delete
  sudo ldconfig
}

if which apt-get >/dev/null; then
  install_dependencies
fi
install_dpdk
if [[ $SPDKVER != 'none' ]]; then
  install_spdk
fi
if [[ $NRHUGE -gt 0 ]]; then
  echo $NRHUGE | sudo tee /sys/devices/system/node/node*/hugepages/hugepages-2048kB/nr_hugepages >/dev/null
  sudo mkdir -p /mnt/huge2M
  sudo mount -t hugetlbfs nodev /mnt/huge2M -o pagesize=2M
fi
