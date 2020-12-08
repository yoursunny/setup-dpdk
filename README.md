# `yoursunny/setup-dpdk` GitHub Action

This is a GitHub Action that installs [Data Plane Development Kit (DPDK)](https://www.dpdk.org/) and [Storage Performance Development Kit (SPDK)](https://spdk.io/).
This Action installs DPDK and SPDK to `/usr/local`, and then automatically configures hugepages for use in DPDK applications.

[DEV Community article](https://dev.to/yoursunny/install-data-plane-development-kit-dpdk-and-build-ndn-dpdk-35o5)

## Usage

```yaml
steps:
- uses: yoursunny/setup-dpdk@master # optional: use commit SHA instead of 'master' to ensure stability
  with:
    dpdk-version: '20.11' # required
    spdk-version: '20.10' # required
    target-arch: haswell  # optional
    hugepages: 2048       # optional
  env:
    CC: gcc-7 # optional; compiler must be installed
```

Optionally, enable caching for faster installation:

```yaml
steps:
  - uses: actions/cache@v2
    with:
      path: |
        ~/setup-dpdk.cache.txz
      key: ${{ matrix.os }}_${{ matrix.compiler }}_${{ hashFiles('.github/workflows/*.yml') }}
      # cache key should include OS, compiler, and DPDK/SPDK version
```
