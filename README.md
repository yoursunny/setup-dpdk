# setup-dpdk

This is a GitHub Action that installs [Data Plane Development Kit (DPDK)](https://www.dpdk.org/) and [Storage Performance Development Kit (SPDK)](https://spdk.io/).
This Action installs DPDK and SPDK to `/usr/local`, and then automatically configures hugepages for use in DPDK applications.

## Usage

```yaml
steps:
- uses: actions/cache@v2 # optional: enable caching for faster installation
    with:
      path: |
        ~/setup-dpdk.cache.*
      key: DPDK
- uses: yoursunny/setup-dpdk@master # optional: use commit SHA instead of 'master' to ensure stability
  with:
    dpdk-version: "20.08" # required
    spdk-version: "20.07" # required
    hugepages: 2048       # optional
  env:
    CC: gcc-7 # optional; compiler must be installed
```

Optionally, enable caching for faster installation.
CPU flags should appear as (part of) the cache key, because DPDK is built with `-march=native`.

```yaml
steps:
  - id: make-cache-key
    run: |
      echo "::set-output name=cpuflags::$(lscpu -J | jq -r '.lscpu[] | select(.field=="Flags:") | .data | gsub("[^a-z0-9]"; "")')"
  - uses: actions/cache@v2
    with:
      path: |
        ~/setup-dpdk.cache.*
      key: ${{ steps.make-cache-key.outputs.cpuflags }}
```
