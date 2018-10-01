#!/bin/bash
##
## (C) Copyright 2011-2018 Nuxeo (http://nuxeo.com/) and others.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
## Contributors:
##     Julien Carsique, Mathieu Guillaume, Damon Brown
##

START=$(date +"%s")

cd "$(dirname $0)"

usage() {
    echo "Usage: $0 <-v version> [-d distrib] [-b builder] [-m mirror] [-c numcpus] [-r ramsize] [-P profile] [-n]"
    echo
    echo "OPTIONS:"
    echo "  -v version  Nuxeo version"
    echo "  -d distrib  Nuxeo distribution (local zip file)"
    echo "  -b builder  Packer builder to use (default: qemu)"
    echo "  -c numcpus  Number of CPUs to suggest for VM"
    echo "  -r ramsize  Size of RAM to suggest for VM"
    echo "  -m mirror   Ubuntu mirror to use"
    echo "  -P profile  Maven profile to use"
    echo "  -n          Produce machine readable output"
    echo
    echo "If -d is not specified, the distribution will be downloaded from a maven repository."
}

version=""
distrib=""
color=""
profile="public"

while getopts ":hv:d:b:m:c:r:P:n" opt
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
    b)
        builder=$OPTARG
        ;;
    m)
        mirror=$OPTARG
        ;;
    c)
        cpus=$OPTARG
        ;;
    r)
        ram=$OPTARG
        ;;
    P)
        profile=$OPTARG
        ;;
    n)
        color="-machine-readable"
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

if [ -z "$builder" ]; then
    builder="qemu"
fi

if [ -z "$mirror" ]; then
    mirrorarg=""
else
    mirrorarg="-var mirror=$mirror"
fi

if [ -z "$cpus" ]; then
    cpusarg=""
else
    cpusarg="-var cpu=$cpus"
fi

if [ -z "$ram" ]; then
    memarg=""
else
    memarg="-var mem=$ram"
fi

# Check requirements
reqsok=true

command -v mvn &>/dev/null
CMDFOUND=$?
if [[ -z "$distrib" && 0 -ne "$CMDFOUND" ]]; then
    reqsok=false
    echo "Missing: mvn (package maven)"
fi
command -v wget &>/dev/null
CMDFOUND=$?
if [[ $distrib == *"://"* && 0 -ne "$CMDFOUND" ]]; then
    reqsok=false
    echo "Missing: wget (package wget)"
fi
command -v packer &>/dev/null
CMDFOUND=$?
if [ 0 -ne "$CMDFOUND" ]; then
    reqsok=false
    echo "Missing: packer (http://packer.io/)"
fi
command -v qemu-img &>/dev/null
CMDFOUND=$?
if [ 0 -ne "$CMDFOUND" ]; then
    reqsok=false
    echo "Missing: qemu-img (package qemu-utils)"
fi
command -v zip &>/dev/null
CMDFOUND=$?
if [ 0 -ne "$CMDFOUND" ]; then
    reqsok=false
    echo "Missing: zip (package zip)"
fi
if [ "x$builder" == "xqemu" ]; then
    command -v kvm &>/dev/null
    CMDFOUND=$?
    if [ 0 -ne "$CMDFOUND" ]; then
        reqsok=false
        echo "Missing: kvm (package qemu-kvm)"
    fi
    command -v VBoxManage &>/dev/null
    CMDFOUND=$?
    if [ 0 -ne "$CMDFOUND" ]; then
        reqsok=false
        echo "Missing: VBoxManage (package virtualbox)"
    fi
    if [[ ! -w /dev/kvm ]]; then
       echo "Warning: Unable to write to /dev/kvm.  Build may fail."
    fi
fi
if [ "x$builder" == "xvmware" ]; then
    command -v vmrun &>/dev/null
    CMDFOUND=$?
    if [ 0 -ne "$CMDFOUND" ]; then
        reqsok=false
        echo "Missing: vmrun (VMware Player & VIX)"
    fi
fi
if [ "x$builder" == "xvirtualbox" ]; then
    command -v VBoxManage &>/dev/null
    CMDFOUND=$?
    if [ 0 -ne "$CMDFOUND" ]; then
        reqsok=false
        echo "Missing: VBoxManage (package virtualbox)"
    fi
fi

if [ "$reqsok" != "true" ]; then
    exit 1
fi

if [ "x$builder" != "xqemu" ]; then
    echo "WARNING: Non-qemu builder selected, no post-build conversion will be done."
fi

# Clean up previous download
if [ -d "tmp" ]; then
    rm -rf tmp
    if [ "$?" != "0" ]; then
        echo "ERROR: Unable to remove previous distribution"
        exit 1
    fi
fi

# Download/copy distribution
mkdir tmp
if [ -z "$distrib" ]; then
    echo "Downloading distribution..."
    mvn -q org.apache.maven.plugins:maven-dependency-plugin:3.1.1:copy \
        -Dartifact=org.nuxeo.ecm.distribution:nuxeo-server-tomcat:${version}:zip \
        -DoutputDirectory=${PWD}/tmp -P ${profile} \
        -DoverWriteReleases=true -DoverWriteSnapshots=true \
        -Dmdep.stripVersion=true
    if [ "$?" != "0" ]; then
        rm -f tmp/nuxeo-server-tomcat.zip
        echo "ERROR: Unable to download distribution from maven"
        exit 1
    fi
    mv -f tmp/nuxeo-server-tomcat.zip tmp/nuxeo-distribution.zip
else
    if [[ $distrib == *"://"* ]]; then
        wget -O tmp/nuxeo-distribution.zip $distrib
        if [ "$?" != "0" ]; then
            rm -f tmp/nuxeo-distribution.zip
            echo "ERROR: Unable to download distribution from $distrib"
            exit 1
        fi
    elif [ -r "$distrib" ]; then
        cp -f "$distrib" tmp/nuxeo-distribution.zip
        if [ "$?" != "0" ]; then
            rm -f tmp/nuxeo-distribution.zip
            echo "ERROR: Unable to copy distribution from $distrib"
            exit 1
        fi
    fi
fi

# Check for distribution
if [ ! -r tmp/nuxeo-distribution.zip ]; then
    echo "No Nuxeo distribution found, unable to build image."
    echo
    usage
    exit 1
fi

# Clean up previous output
if [ -d "output-$builder" ]; then
    rm -rf output-$builder
    if [ "$?" != "0" ]; then
        echo "ERROR: Unable to remove previous build output"
        exit 1
    fi
fi

# Build image
packer build -only=$builder $mirrorarg $cpusarg $memarg $color nuxeovm.json
RETCODE=$?
echo "Build status: $RETCODE"

# Finish up
END=$(date +"%s")
DELTA=$(($END-$START))
echo "Build took $(($DELTA / 60)) minutes and $(($DELTA % 60)) seconds."

if [ "$RETCODE" != "0" ]; then
    echo "Build failed."
    exit 1
fi

if [ "x$builder" == "xqemu" ]; then

    #
    # VMWare version
    #

    zipdir="nuxeo-$version-vm-vmware"
    if [ -d "$zipdir" ]; then
        rm -rf $zipdir
    fi
    rm -f ${zipdir}.zip || true
    mkdir -p $zipdir
    # Convert to vmdk
    if [ -f output-qemu/nuxeovm.raw ]; then
        qemu-img convert -f raw -O vmdk -o subformat=monolithicFlat output-qemu/nuxeovm.raw $zipdir/nuxeovm.vmdk
    else
        qemu-img convert -f raw -O vmdk -o subformat=monolithicFlat output-qemu/nuxeovm $zipdir/nuxeovm.vmdk
    fi
    # Create archive
    cp templates/nuxeovm.vmx $zipdir/
    cp templates/README-vmware.txt $zipdir/README.txt
    zip -r ${zipdir}.zip $zipdir

    #
    # VirtualBox version
    #

    zipdir="nuxeo-$version-vm-vbox"
    if [ -d "$zipdir" ]; then
        rm -rf $zipdir
    fi
    rm -f ${zipdir}.zip || true
    mkdir -p $zipdir
    # Convert to monolithic VMDK as qemu-img is bad with sparse
    if [ -f output-qemu/nuxeovm.raw ]; then
        qemu-img convert -f raw -O vmdk -o subformat=monolithicFlat output-qemu/nuxeovm.raw $zipdir/nuxeovm.tmp
    else
        qemu-img convert -f raw -O vmdk -o subformat=monolithicFlat output-qemu/nuxeovm $zipdir/nuxeovm.tmp
    fi
    # Then to sparse VMDK
    vboxmanage clonehd --format=VMDK --variant=Stream $zipdir/nuxeovm.tmp $zipdir/nuxeovm.vmdk
    rm $zipdir/nuxeovm*.tmp

    # Create archive
    size=$(du -b $zipdir/nuxeovm.vmdk | awk '{print $1}')
    perl -p -e "s/\@\@SIZE\@\@/$size/g" templates/nuxeovm.ovf | perl -p -e "s/\@\@VERSION\@\@/$version/g" > $zipdir/nuxeovm.ovf
    cp templates/README-vbox.txt $zipdir/README.txt
    zip -r ${zipdir}.zip $zipdir

fi

