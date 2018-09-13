#!/bin/sh

NUXEO_HOME="/var/lib/nuxeo/server"
NUXEO_CONF="/etc/nuxeo/nuxeo.conf"
NUXEO_USER="nuxeo"

NUXEOCTL="${NUXEO_HOME}/bin/nuxeoctl"

PATH="${PATH}:${NUXEO_HOME}/bin"

export NUXEO_HOME NUXEO_CONF NUXEO_USER NUXEOCTL PATH
