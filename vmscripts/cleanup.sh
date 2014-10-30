#!/bin/bash

# Reset apt
apt-get clean
rm -rf /var/lib/apt/lists
cat > /etc/apt/sources.list << EOF
deb http://ftp.ubuntu.com/ubuntu/ trusty main restricted universe multiverse
deb http://ftp.ubuntu.com/ubuntu/ trusty-updates main restricted universe multiverse
deb http://ftp.ubuntu.com/ubuntu/ trusty-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ trusty-security main restricted universe multiverse
EOF

echo "Zeroing out free space, this may take some time..."
dd if=/dev/zero of=/zerofile || true
rm /zerofile

