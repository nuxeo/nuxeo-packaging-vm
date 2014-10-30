# Nuxeo VM Generation script

- create disk image with packer
- generate OVF and VMX from templates

Usage: ./build-vm.sh &lt;-v version> [-d distrib] [-b builder] [-m mirror] [-c numcpus] [-r ramsize]

OPTIONS:  
  -v version  Nuxeo version  
  -d distrib  Nuxeo distribution (local zip file)  
  -b builder  Packer builder name to use (cf nuxeovm.json) - default: qemu  
  -m mirror   Ubuntu mirror address - default: Nuxeo internal mirror  


If -d is not specified, the distribution will be downloaded from a maven repository.


## Requirements:
- 64 bit OS (unless the builder you use can do 64 bit over 32 bit)  
- packer (http://packer.io)  
- at least one of qemu-kvm, virtualbox or VMware Workstation/Player (possibly +VIX) depending on the builder used.  

The build-vm script uses qemu-kvm and qemu-img by default, if you use another there will be no conversion to OVF/vmx, just the native packer builder output.


