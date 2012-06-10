#!/bin/bash

cd "$(dirname $0)"

usage() {
    echo "Usage: $0 [-v version|-d distrib]"
    echo
    echo "OPTIONS:"
    echo "  -v version  Nuxeo version (downloaded from maven repo)"
    echo "  -d distrib  Nuxeo distribution (local zip file)"
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

if [ -z "$version" ] && [ -z "$distrib" ]; then
    echo "ERROR: One of -v or -d must be specified"
    echo
    usage
    exit 1
fi

if [ ! -z "$version" ] && [ ! -z "$distrib" ]; then
    echo "ERROR: Only one of -v or -d can be specified"
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
#sudo -n ls >/dev/null 2>/dev/null
#if [ "$?" != "0" ]; then
#    reqsok=false
#    echo "Passwordless sudo not enabled"
#fi

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
if [ ! -z "$version" ]; then
    mvn org.apache.maven.plugins:maven-dependency-plugin:2.4:get -Dartifact=org.nuxeo.ecm.distribution:nuxeo-distribution-tomcat:${version}:zip:nuxeo-cap -Ddest=build/nuxeo-distribution.zip
else
    cp "$distrib" build/nuxeo-distribution.zip
fi

sudo ./build-image.sh
if [ "$?" != "0" ]; then
    echo "ERROR: Image build failed"
fi

