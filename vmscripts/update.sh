#!/bin/bash

apt-get update
DEBIAN_FRONTEND=noninteractive aptitude -q -y full-upgrade

