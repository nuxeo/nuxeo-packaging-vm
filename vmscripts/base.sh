#!/bin/bash -e

echo 'nuxeo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

wget -O- http://apt.nuxeo.org/nuxeo.key | apt-key add -
echo 'deb http://apt.nuxeo.org/ trusty releases' > /etc/apt/sources.list.d/nuxeo.list # For ffmpeg
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -q -y acpid openjdk-7-jdk libreoffice imagemagick poppler-utils ffmpeg-nuxeo ffmpeg2theora ufraw libwpd-tools postgresql-9.3 apache2 perl locales pwgen dialog zip unzip exiftool

update-java-alternatives --set java-1.7.0-openjdk-amd64

mv /tmp/vmfiles/nuxeo.init /etc/init.d/nuxeo
chmod +x /etc/init.d/nuxeo
mv /tmp/vmfiles/nuxeo.apache2 /etc/apache2/sites-available/nuxeo.conf
mv /tmp/vmfiles/showaddress /sbin/showaddress
chmod +x /sbin/showaddress
mv /tmp/vmfiles/tty1.conf /etc/init/tty1.conf

# PostgreSQL setup

pg_dropcluster --stop 9.3 main
pg_createcluster --locale=en_US.UTF-8 --port=5432 9.3 nuxeodb
service postgresql stop
pgconf="/etc/postgresql/9.3/nuxeodb/postgresql.conf"
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

