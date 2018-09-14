#!/bin/bash
##
## (C) Copyright 2018 Nuxeo (http://nuxeo.com/) and others.
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
##     Mathieu Guillaume
##

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

