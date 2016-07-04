#!/bin/bash

# Reset apt
apt-get clean
rm -rf /var/lib/apt/lists
cat > /etc/apt/sources.list << EOF
deb http://ftp.ubuntu.com/ubuntu/ xenial main restricted universe multiverse
deb http://ftp.ubuntu.com/ubuntu/ xenial-updates main restricted universe multiverse
deb http://ftp.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ xenial-security main restricted universe multiverse
EOF

echo "Zeroing out free space, this may take some time..."
dd if=/dev/zero of=/zerofile || true
rm /zerofile

