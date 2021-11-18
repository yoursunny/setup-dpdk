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
  if ! command -v ninja >/dev/null; then
    APT_PKGS+=(ninja-build)
  fi

  sudo apt-get -y -qq update
  sudo apt-get -y -qq --no-install-recommends install "${APT_PKGS[@]}"

  if ! command -v meson >/dev/null; then
    sudo pip3 install meson
  fi
}

install_dpdk() {
  mkdir -p $CODEROOT/dpdk_$DPDKVER
  cd $CODEROOT/dpdk_$DPDKVER
  if ! [[ -f meson.build ]]; then
    curl -fsLS https://github.com/DPDK/dpdk/archive/refs/tags/v$DPDKVER.tar.gz | tar -xz --strip-components=1
  fi

  if jq -e --arg mesonver $(meson --version) '.meson_version.full != $mesonver' build/meson-info/meson-info.json &>/dev/null; then
    echo 'Meson version changed, cannot use cached build'
    rm -rf build/
  fi

  if ! [[ -f build/lib/librte_eal.a ]]; then
    meson -Ddebug=true -Doptimization=3 -Dcpu_instruction_set=$TARGETARCH -Dtests=false --libdir=lib build
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
    curl -fsLS https://github.com/spdk/spdk/archive/v$SPDKVER.tar.gz | tar -xz --strip-components=1
  fi
  sudo scripts/pkgdep.sh

  if ! [[ -f build/lib/libspdk_env_dpdk.a ]]; then
    WITH_URING=
    if pkg-config liburing; then
      WITH_URING=--with-uring
    fi

    ./configure --target-arch=$TARGETARCH --with-shared \
      --disable-tests --disable-unit-tests --disable-examples --disable-apps \
      --with-dpdk $WITH_URING \
      --without-crypto --without-fuse --without-isal --without-vhost
    make -j$(nproc)
  fi
  sudo make install
  sudo find /usr/local/lib -name 'libspdk_*.a' -delete
  sudo ldconfig
}

if command -v apt-get >/dev/null; then
  install_dependencies
fi
install_dpdk
if [[ $SPDKVER != none ]]; then
  install_spdk
fi
if [[ $HUGE -gt 0 ]]; then
  sudo sh -c "while ! dpdk-hugepages.py --setup ${HUGE}M; do sleep 1; done"
  dpdk-hugepages.py --show
fi
