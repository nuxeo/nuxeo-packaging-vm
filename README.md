# Nuxeo VM Generation script

- create disk image with vmbuilder
- generate OVF from template
- generate VMX with virt-convert


Usage: ./build-vm.sh &lt;-v version> [-d distrib]

OPTIONS:  
  -v version  Nuxeo version  
  -d distrib  Nuxeo distribution (local zip file)

If -d is not specified, the distribution will be downloaded from a maven repository.


*This makes use of python-vm-builder and kvm and will probably only work on Ubuntu 12.04 or later.*

## If you want to use this script, there are a few things you need to change:
- in nuxeovm/vmbuilder.cfg, you need to point "install-mirror" to your local ubuntu mirror (or remove the line),  
- in build-vm.sh, when checking the image (search for "pingtest"), we rely on a local DNS + DHCP binding so we can know the IP address of the VM. You need to have something similar in place (or disable the check and just do it manually afterwards),  
- in build-vm.sh again, we assume passwordless sudo so the script can be run non-interactively. This can be commented out if needed (search for "interactive sudo").


