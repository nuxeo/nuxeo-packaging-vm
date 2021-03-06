#!/bin/bash -xe

START=$(date +"%s")

cd "$(dirname $0)"

usage() {
    echo "Usage: $0 <-v version> [-d distrib] [-b builder] [-m mirror] [-c numcpus] [-r ramsize] [-n]"
    echo
    echo "OPTIONS:"
    echo "  -v version  Nuxeo version"
    echo "  -d distrib  Nuxeo distribution (local zip file)"
    echo "  -b builder  Packer builder to use (default: qemu)"
    echo
    echo "If -d is not specified, the distribution will be downloaded from a maven repository."
}

version=""
distrib=""
color=""

while getopts ":hv:d:b:m:c:r:n" opt
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

haspacker=$(which packer)
if [ -z "$haspacker" ]; then
    reqsok=false
    echo "Missing: packer (http://packer.io/)"
fi
hasqemuimg=$(which qemu-img)
if [ -z "$hasqemuimg" ]; then
    reqsok=false
    echo "Missing: qemu-img (package qemu-utils)"
fi
if [ "x$builder" == "xqemu" ]; then
    haskvm=$(which kvm)
    if [ -z "$haskvm" ]; then
        reqsok=false
        echo "Missing: kvm (package qemu-kvm)"
    fi
fi
if [ "x$builder" == "xvmware" ]; then
    hasvmrun=$(which vmrun)
    if [ -z "$hasvmrun" ]; then
        reqsok=false
        echo "Missing: vmrun (VMware Player & VIX)"
    fi
fi
if [ "x$builder" == "xvirtualbox" ]; then
    hasvbox=$(which VBoxManage)
    if [ -z "$hasvbox" ]; then
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

# Download/copy distribution
if [ -d "tmp" ]; then
    rm -rf tmp
fi
mkdir tmp
if [ -z "$distrib" ]; then
    echo "Downloading distribution..."
    mvn -q org.apache.maven.plugins:maven-dependency-plugin:2.4:get -Dartifact=org.nuxeo.ecm.distribution:nuxeo-server-tomcat:${version}:zip -Ddest=tmp/nuxeo-distribution.zip -Dtransitive=false
    if [ "$?" != "0" ]; then
        echo "ERROR: Unable to download distribution"
        exit 1
    fi
else
    if [[ $distrib == *"://"* ]]; then
        wget -O tmp/nuxeo-distribution.zip $distrib
    else
        cp "$distrib" tmp/nuxeo-distribution.zip
    fi
fi

# Build image
rm -rf output-$builder
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

