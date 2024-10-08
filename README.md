# `yoursunny/setup-dpdk` GitHub Action

This is a GitHub Action that installs [Data Plane Development Kit (DPDK)](https://www.dpdk.org) and [Storage Performance Development Kit (SPDK)](https://spdk.io).
This Action installs DPDK and SPDK to `/usr/local`, and then automatically configures hugepages for use in DPDK applications.

[DEV Community article](https://dev.to/yoursunny/install-data-plane-development-kit-dpdk-and-build-ndn-dpdk-35o5)

## Usage

```yaml
steps:
- uses: yoursunny/setup-dpdk@main # you may use commit SHA instead of 'main' to ensure stability
  with:
    dpdk-version: v22.11        # required
    dpdk-patches: '12345,67890' # optional, patch series numbers on https://patches.dpdk.org/project/dpdk/list/
    spdk-version: v23.01        # optional, default is not installing SPDK
    target-arch: haswell        # optional
    setup-hugepages: 4096       # optional, default is 4096MB, 0 to disable
  env:
    CC: clang # optional; compiler must be installed
```

On Ubuntu, this Action can automatically install DPDK dependencies with `apt-get` command.
If you want to use this Action on a different OS, you must install dependencies yourself before calling this action.

Optionally, enable caching for faster installation:

```yaml
steps:
- uses: actions/cache@v4
  with:
    path: |
      ~/setup-dpdk
    key: ${{ matrix.os }}_${{ matrix.compiler }}_DPDK2211_SPDK2301
    # cache key should include OS, compiler, and DPDK/SPDK version
```
