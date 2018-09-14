# Nuxeo VM Generation script

[![Build Status](https://qa.nuxeo.org/jenkins/buildStatus/icon?job=master/tools_nuxeo-packaging-vm-master)](https://qa.nuxeo.org/jenkins/job/master/job/tools_nuxeo-packaging-vm-master/)

The Nuxeo Packaging scripts produce a Virtual Machine disk image with [Packer](http://packer.io/).  This produces VMWare and VirtualBox compatible images based on [Ubuntu](https://www.ubuntu.com/).

## Requirements

- 64 bit OS (unless the builder you use can do 64 bit over 32 bit)
- packer (http://packer.io),  
- at least one of `qemu-kvm`, `virtualbox` or `VMware Workstation/Player` (possibly +VIX) depending on the builder used
- the user you run as must be able to launch VMs for your builder (for qemu, user needs to be `root` or in the `kvm` group)  

> The build-vm script uses `qemu-kvm` and `qemu-img` by default.  If you use another builder type, there will be no conversion to OVF/vmx.

## Build

Use the `build-vm.sh` script to generate images for VirtualBox, VMWare, and KVM-compatible servers.

```
Usage: ./build-vm.sh <-v version> [-d distrib] [-b builder] [-m mirror] [-c numcpus] [-r ramsize] [-n]

OPTIONS:
  -v version  Nuxeo version
  -d distrib  Nuxeo distribution (local zip file)
  -b builder  Packer builder to use (default: qemu)
  -c numcpus  Number of CPUs to suggest for VM
  -r ramsize  Size of RAM to suggest for VM
  -m mirror   Ubuntu mirror to use
  -n          Produce machine readable output

If -d is not specified, the distribution will be downloaded from a maven repository.
```

### Examples:

Build Nuxeo VM with version 10.2:
```
$ ./build-vm.sh -v 10.2
```

Build custom VM with specified distribution and 32 CPUs:
```
$ ./build-vm.sh -v 9.10 -d nuxeo-tomcat-server-9.10.zip -c 32
```

## Deploy

The build produces ZIP files that contain the disk images.

### VMWare

To use with VMWare, double-click on `nuxeovm.vmx`.

### VirtualBox

In the interface, go to File -> Import Appliance and select `nuxeovm.ovf`.

### KVM

You can convert the vmdk disk image to qcow2 with the following command:
> qemu-img convert -p -O qcow2 nuxeovm.vmdk nuxeovm.qcow2
then create a VM based on this disk image.

> Recommended settings for the VM: 2 CPUs and 2GB RAM.

# Documentation

Please see the documentation for additional information:
https://doc.nuxeo.com/nxdoc/installing-the-nuxeo-platform-on-linux/#installing-a-nuxeo-virtual-machine-image

# Contributing / Reporting issues

Please report issues with this Virtual Machine:
https://jira.nuxeo.com/browse/NXBT/component/11802/

# Nuxeo License

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html)

# About Nuxeo

The [Nuxeo Platform](http://www.nuxeo.com/products/content-management-platform/) is an open source customizable and extensible content management platform for building business applications. It provides the foundation for developing [document management](http://www.nuxeo.com/solutions/document-management/), [digital asset management](http://www.nuxeo.com/solutions/digital-asset-management/), [case management application](http://www.nuxeo.com/solutions/case-management/) and [knowledge management](http://www.nuxeo.com/solutions/advanced-knowledge-base/). You can easily add features using ready-to-use addons or by extending the platform using its extension point system.

The Nuxeo Platform is developed and supported by Nuxeo, with contributions from the community.

Nuxeo dramatically improves how content-based applications are built, managed and deployed, making customers more agile, innovative and successful. Nuxeo provides a next generation, enterprise ready platform for building traditional and cutting-edge content oriented applications. Combining a powerful application development environment with
SaaS-based tools and a modular architecture, the Nuxeo Platform and Products provide clear business value to some of the most recognizable brands including Verizon, Electronic Arts, Sharp, FICO, the U.S. Navy, and Boeing. Nuxeo is headquartered in New York and Paris.
More information is available at [www.nuxeo.com](http://www.nuxeo.com).
