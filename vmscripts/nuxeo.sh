#!/bin/bash -e

mkdir -p /var/lib/nuxeo

mkdir -p /tmp/nuxeo-distribution
unzip -q -d /tmp/nuxeo-distribution /tmp/nuxeo-distribution.zip
distdir=$(/bin/ls /tmp/nuxeo-distribution | head -n 1)
mv /tmp/nuxeo-distribution/$distdir /var/lib/nuxeo/server
rm -rf /tmp/nuxeo-distribution
rm -f /tmp/nuxeo-distribution.zip
chmod +x /var/lib/nuxeo/server/bin/nuxeoctl
echo "org.nuxeo.distribution.packaging=vm" >> /var/lib/nuxeo/server/templates/common/config/distribution.properties

if [ ! -f /etc/nuxeo/nuxeo.conf ]; then

    mkdir -p /etc/nuxeo
    mv /var/lib/nuxeo/server/bin/nuxeo.conf /etc/nuxeo/nuxeo.conf

    mkdir -p /var/log/nuxeo

    cat << EOF >> /etc/nuxeo/nuxeo.conf
nuxeo.log.dir=/var/log/nuxeo
nuxeo.pid.dir=/var/run/nuxeo
nuxeo.data.dir=/var/lib/nuxeo/data
nuxeo.bind.address=127.0.0.1
nuxeo.server.http.port=8080
nuxeo.server.ajp.port=0
nuxeo.wizard.done=false
nuxeo.wizard.skippedpages=General,DB
EOF

fi

chown -R nuxeo:nuxeo /var/lib/nuxeo
chown -R nuxeo:nuxeo /etc/nuxeo
chown -R nuxeo:nuxeo /var/log/nuxeo

mv /tmp/vmfiles/firstboot.sh /etc/init.d/firstboot
chmod +x /etc/init.d/firstboot
update-rc.d firstboot start 20 2 3 4 5 .

