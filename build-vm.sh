#!/bin/bash

cd "$(dirname $0)"

usage() {
    echo "Usage: $0 <-v version> [-d distrib]"
    echo
    echo "OPTIONS:"
    echo "  -v version  Nuxeo version"
    echo "  -d distrib  Nuxeo distribution (local zip file)"
    echo
    echo "If -d is not specified, the distribution will be downloaded from a maven repository."
}

version=""
distrib=""

while getopts ":hv:d:" opt
do
    case $opt in
    h)
        usage
        exit 1
        ;;
    v)
        version=$OPTARG
        ;;
    d)
        distrib=$OPTARG
        ;;
    \?)
        echo "Invalid option: -$opt" >&2
        exit 1
        ;;
    :)
        echo "Option -$opt requires an argument" >&2
        exit 1
        ;;
    esac
done

if [ -z "$version" ]; then
    echo "ERROR: Missing version."
    echo
    usage
    exit 1
fi

# Check requirements
reqsok=true

vmbuilder=$(which vmbuilder)
if [ -z "$vmbuilder" ]; then
    reqsok=false
    echo "Missing: vmbuilder (package python-vm-builder)"
fi
virtconvert=$(which virt-convert)
if [ -z "$virtconvert" ]; then
    reqsok=false
    echo "Missing: virt-convert (package virtinst)"
fi
qemuimg=$(which qemu-img)
if [ -z "$qemuimg" ]; then
    reqsok=false
    echo "Missing: qemu-img (package qemu-utils)"
fi
# Comment for interactive sudo
sudo -n ls >/dev/null 2>/dev/null
if [ "$?" != "0" ]; then
    reqsok=false
    echo "Passwordless sudo not enabled"
fi

if [ "$reqsok" != "true" ]; then
    exit 1
fi

# Prepare build directory
if [ -d "build" ]; then
    rm -rf build
fi
mkdir build
cp -r nuxeovm/* build/

# Download/copy distribution
if [ -z "$distrib" ]; then
    mvn -q org.apache.maven.plugins:maven-dependency-plugin:2.4:get -Dartifact=org.nuxeo.ecm.distribution:nuxeo-distribution-tomcat:${version}:zip:nuxeo-cap -Ddest=build/nuxeo-distribution.zip -Dtransitive=false
else
    cp "$distrib" build/nuxeo-distribution.zip
fi

# Try to build the image
success=false
retries=0
max_retries=5
while [ "$success" != "true" ] && [ "$retries" -lt "$max_retries" ]; do
    retries=$(($retries + 1))
    sudo ./build-image.sh
    if [ "$?" != "0" ]; then
        # exit immediately if the image build failed
        echo "ERROR: Image build failed"
        break
    else
        # Validate that the image is bootable
        # (vmbuilder sometimes creates non-bootable ones)
        # -> Check if we can ping it (name is bound to the mac adress in the local network config)
        cp -f build/nuxeovm.qcow2 build/pingtest.qcow2
        sudo kvm -hda build/pingtest.qcow2 -smp 2 -m 2048 -net nic,macaddr=52:54:00:12:34:56 -net tap,script=/etc/qemu-ifup -vnc :2 -daemonize
        # Wait 2 minutes for the VM to boot up
        echo "Waiting 2 minutes for VM to boot up"
        sleep 120
        ping -q -w 30 -c 3 nuxeovm.in.nuxeo.com
        if [ "$?" == "0" ]; then
            success=true
        fi
        kvmpid=$(ps auwx | grep '52:54:00:12:34:56' | grep -v grep | awk '{print $2}')
        if [ -n "$kvmpid" ]; then
            sudo kill $kvmpid
        fi
        if [ "$success" == "true" ]; then
            break
        fi
    fi
    echo "WARNING: Image build #$retries is not bootable"
done
sudo rm -f build/pingtest.qcow2 # cleanup
if [ "$success" != "true" ]; then
    echo "ERROR: Could not build a bootable image after #$max_retries retries - giving up"
    exit 1
fi

# Convert to VMDK
qemu-img convert -f qcow2 -O vmdk -o subformat=monolithicFlat build/nuxeovm.qcow2 build/nuxeovm.vmdk

# Adjust .ovf and .vmx files
size=$(du -b build/nuxeovm.vmdk | awk '{print $1}')
perl -p -i -e "s/\@\@SIZE\@\@/$size/g" build/nuxeovm.ovf
perl -p -i -e "s/\@\@VERSION\@\@/$version/g" build/nuxeovm.ovf
# Disable checksum checking : VirtualBox doesn't like my correct ones
#ovfsha1=$(sha1sum build/nuxeovm.ovf | awk '{print $1}')
#vmdksha1=$(sha1sum build/nuxeovm.vmdk | awk '{print $1}')
#perl -p -i -e "s/\@\@OVFSHA1\@\@/$ovfsha1/g" build/nuxeovm.mf
#perl -p -i -e "s/\@\@VMDKSHA1\@\@/$vmdksha1/g" build/nuxeovm.mf

# Prepare zip
zipdir="nuxeo-$version-vm"
if [ -d "output/$zipdir" ]; then
    rm -rf "output/$zipdir"
fi
mkdir -p output/$zipdir
mv build/nuxeovm.vmdk output/$zipdir/
mv build/nuxeovm-flat.vmdk output/$zipdir/
mv build/nuxeovm.ovf output/$zipdir/
mv build/nuxeovm.vmx output/$zipdir/
#mv build/nuxeovm.mf output/$zipdir/

pushd output
zip -r $zipdir.zip $zipir
popd

