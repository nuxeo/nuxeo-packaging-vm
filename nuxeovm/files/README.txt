- VMWare Viewer / Workstation /Fusion:
double-click on nuxeovm.vmx.

- VirtualBox:
In the interface, go to File -> Import Appliance and select nuxeovm.ovf.

- KVM:
You can convert the vmdk disk image to qcow2 with the following command:
qemu-img convert -p -O qcow2 nuxeovm.vmdk nuxeovm.qcow2
then create a VM based on this disk image.
Recommended settings for the VM: 2 CPUs and 2GB RAM.

