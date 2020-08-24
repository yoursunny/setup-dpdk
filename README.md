# setup-dpdk

This is a GitHub Action that installs [Data Plane Development Kit (DPDK)](https://www.dpdk.org/) and [Storage Performance Development Kit (SPDK)](https://spdk.io/), including their dependencies.
This Action installs DPDK and SPDK to `/usr/local`, and then automatically configures hugepages for use in DPDK applications.

## Usage

```yaml
steps:
- uses: yoursunny/setup-dpdk@master # use commit SHA to ensure stability
  with:
    dpdk-version: "20.08" # required
    spdk-version: "20.07" # required
    hugepages: 2048       # optional
```
