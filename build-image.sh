#!/bin/bash

# Check root privileges
if [ "$USER" != "root" ]; then
    echo "ERROR: this script must be run as root or with sudo"
    echo "It should be called by build-vm.sh"
    exit 1
fi

builddir=$(cd $(dirname $0)/build ; pwd)
pushd $builddir

echo "*** Starting image build"
perl -p -i -e "s,BUILDDIR,$builddir,g" vmbuilder.cfg
perl -p -i -e "s,BUILDDIR,$builddir,g" vmbuilder.copy
vmbuilder kvm ubuntu --config vmbuilder.cfg

# Check result
if [ "$?" != "0" ]; then
    if [ -n "$SUDO_UID" ]; then
        chown -R $SUDO_UID ubuntu-kvm
    fi
    echo "*** Image build: FAILURE"
    exit 1
fi
# Cleanup
mv ubuntu-kvm/tmp*.qcow2 nuxeovm.qcow2
if [ -n "$SUDO_UID" ]; then
    chown $SUDO_UID nuxeovm.qcow2
fi
rm -rf ubuntu-kvm
echo "*** Image build: SUCCESS"

popd

