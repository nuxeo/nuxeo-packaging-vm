#!/bin/bash -e
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
##     Mathieu Guillaume, Damon Brown
##

# Allow nuxeo to use sudo

echo 'nuxeo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install Java

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -q -y install acpid libreoffice imagemagick poppler-utils ffmpeg2theora ufraw libwpd-tools postgresql-9.5 apache2 perl locales pwgen dialog zip unzip exiftool aptitude curl openjdk-8-jdk
update-java-alternatives --set java-1.8.0-openjdk-amd64

# Add Nuxeo Repository for ffmpeg

curl -s http://apt.nuxeo.org/nuxeo.key | apt-key add -
echo 'deb http://apt.nuxeo.org/ xenial releases' > /etc/apt/sources.list.d/nuxeo.list # For ffmpeg

# Update & Install ffmpeg

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -q -y install ffmpeg-nuxeo ccextractor-nuxeo

# Startup

mv /tmp/vmfiles/nuxeo.init /etc/init.d/nuxeo
chmod +x /etc/init.d/nuxeo
mv /tmp/vmfiles/nuxeo_env.sh /etc/profile.d/nuxeo_env.sh
chmod +rx /etc/profile.d/nuxeo_env.sh
mv /tmp/vmfiles/nuxeo.apache2 /etc/apache2/sites-available/nuxeo.conf
mv /tmp/vmfiles/showaddress /sbin/showaddress
chmod +x /sbin/showaddress
mv /tmp/vmfiles/tty.conf /etc/systemd/system/nuxeo_status@.service
ln -sf /etc/systemd/system/nuxeo_status@.service /etc/systemd/system/getty.target.wants/getty@tty1.service

# PostgreSQL setup

pg_dropcluster --stop 9.5 main
pg_createcluster --locale=en_US.UTF-8 --port=5432 9.5 nuxeodb
service postgresql stop
pgconf="/etc/postgresql/9.5/nuxeodb/postgresql.conf"
perl -p -i -e "s/^#?shared_buffers\s*=.*$/shared_buffers = 100MB/" $pgconf
perl -p -i -e "s/^#?max_prepared_transactions\s*=.*$/max_prepared_transactions = 32/" $pgconf
perl -p -i -e "s/^#?effective_cache_size\s*=.*$/effective_cache_size = 1GB/" $pgconf
perl -p -i -e "s/^#?work_mem\s*=.*$/work_mem = 32MB/" $pgconf
perl -p -i -e "s/^#?wal_buffers\s*=.*$/wal_buffers = 8MB/" $pgconf
perl -p -i -e "s/^#?lc_messages\s*=.*$/lc_messages = 'en_US.UTF-8'/" $pgconf
perl -p -i -e "s/^#?lc_time\s*=.*$/lc_time = 'en_US.UTF-8'/" $pgconf
perl -p -i -e "s/^#?log_line_prefix\s*=.*$/log_line_prefix = '%t [%p]: [%l-1] '/" $pgconf
service postgresql start

# Apache setup

rm -f /etc/apache2/sites-enabled/*
a2enmod proxy proxy_http rewrite
a2ensite nuxeo.conf
