#!/bin/bash
set -euo pipefail
CODEROOT=$HOME/setup-dpdk

install_dependencies() {
  sudo apt-get -y -qq update

  local APT_PKGS=(
    libaio-dev
    libnuma-dev
    ninja-build
    python3-pyelftools
  )
  if [[ $SPDKVER != none ]]; then
    APT_PKGS+=(
      libaio-dev
      uuid-dev
    )
  fi

  if ! command -v meson >/dev/null && dpkg --compare-versions $(apt-cache show meson | awk '$1=="Version:" { print $2 }') ge 1.0.0; then
    APT_PKGS+=(
      meson
    )
  else
    APT_PKGS+=(
      python3-pip
      python3-setuptools
      python3-wheel
    )
  fi

  sudo apt-get -y -qq --no-install-recommends install "${APT_PKGS[@]}"

  if ! command -v meson >/dev/null; then
    sudo pip3 install meson
  fi
}

install_dpdk() {
  mkdir -p $CODEROOT/dpdk_$DPDKVER
  cd $CODEROOT/dpdk_$DPDKVER
  if ! [[ -f meson.build ]]; then
    curl -fsLS https://github.com/DPDK/dpdk/archive/$DPDKVER.tar.gz | tar -xz --strip-components=1
    echo -n "$DPDKPATCH" | xargs -d, --no-run-if-empty -I{} \
      sh -c "curl -fsLS https://patches.dpdk.org/series/{}/mbox/ | patch -p1"
  fi

  if ! jq -e --arg V $(meson --version) '.meson_version.full == $V' build/meson-info/meson-info.json &>/dev/null; then
    echo 'Meson version changed, cannot use cached build'
    rm -rf build/
  fi

  if ! [[ -f build/lib/librte_eal.a ]]; then
    meson setup --libdir=lib -Ddebug=true -Doptimization=3 -Dcpu_instruction_set=$TARGETARCH -Dtests=false \
      -Ddisable_drivers=common/cnxk,common/dpaax,net/bnxt -Ddisable_apps='test-*' \
      build
    meson compile -C build
  fi
  sudo $(command -v meson) install -C build
  sudo find /usr/local/lib -name 'librte_*.a' -delete
  sudo ldconfig
}

install_spdk() {
  mkdir -p $CODEROOT/spdk_$SPDKVER
  cd $CODEROOT/spdk_$SPDKVER
  if ! [[ -f scripts/pkgdep.sh ]]; then
    curl -fsLS https://github.com/spdk/spdk/archive/$SPDKVER.tar.gz | tar -xz --strip-components=1
  fi

  if ! [[ -f build/lib/libspdk_env_dpdk.a ]]; then
    WITH_URING=
    if pkg-config liburing; then
      WITH_URING='--with-uring --without-uring-zns'
    fi

    sed -i '/^\s*if .*isa-l\/autogen.sh/,/^\s*fi$/ s/.*/CONFIG[ISAL]=n/' configure
    ./configure --target-arch=$TARGETARCH --with-shared \
      --disable-tests --disable-unit-tests --disable-examples --disable-apps \
      --with-dpdk $WITH_URING \
      --without-idxd --without-crypto --without-fio --without-xnvme --without-vhost \
      --without-virtio --without-vfio-user --without-rbd \
      --without-rdma --without-fc --without-daos --without-iscsi-initiator --without-vtune \
      --without-ocf --without-fuse --without-nvme-cuse --without-raid5f --without-wpdk \
      --without-usdt --without-sma

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
