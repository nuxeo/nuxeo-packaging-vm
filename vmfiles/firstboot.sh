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

# VM setup

# Prevent double execution

if [ -f /firstboot_done ]; then
    exit 0
fi
echo "DO NOT REMOVE THIS FILE" > /firstboot_done

# Regenerate host keys
rm -f /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server

# Set random password
nxpass=$(pwgen -c1)
chpasswd << EOF
root:$nxpass
nuxeo:$nxpass
EOF

cat << 'EOF' > /etc/issue
Ubuntu 16.04.5 LTS \n \l
EOF

cat << EOF >> /etc/issue
Default password for the root and nuxeo users: $nxpass
EOF

systemctl restart getty@tty2.service

# PostgreSQL setup

locale-gen --no-purge en_US.UTF-8

pgpass=$(pwgen -c1)

su postgres -c "psql -p 5432 template1 --quiet -t -f-" << EOF > /dev/null
CREATE USER nuxeo WITH PASSWORD '$pgpass';
CREATE FUNCTION pg_catalog.text(integer) RETURNS text STRICT IMMUTABLE LANGUAGE SQL AS 'SELECT textin(int4out(\$1));';
CREATE CAST (integer AS text) WITH FUNCTION pg_catalog.text(integer) AS IMPLICIT;
COMMENT ON FUNCTION pg_catalog.text(integer) IS 'convert integer to text';
CREATE FUNCTION pg_catalog.text(bigint) RETURNS text STRICT IMMUTABLE LANGUAGE SQL AS 'SELECT textin(int8out(\$1));';
CREATE CAST (bigint AS text) WITH FUNCTION pg_catalog.text(bigint) AS IMPLICIT;
COMMENT ON FUNCTION pg_catalog.text(bigint) IS 'convert bigint to text';
EOF

su postgres -c "createdb -p 5432 -O nuxeo -E UTF-8 nuxeo"

# Nuxeo setup

cat << EOF >> /etc/nuxeo/nuxeo.conf
nuxeo.templates=postgresql
nuxeo.db.host=localhost
nuxeo.db.port=5432
nuxeo.db.name=nuxeo
nuxeo.db.user=nuxeo
nuxeo.db.password=$pgpass
EOF

update-rc.d nuxeo defaults
/etc/init.d/nuxeo start

