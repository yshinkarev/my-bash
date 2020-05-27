#!/bin/sh

cd /opt
env | grep H2

if [ ! -d ${H2DATA}/data ]; then
    root mkdir -p ${H2DATA}/data
    root chown -R h2:h2 ${H2DATA}/data
fi

${H2DIR}/bin/h2.sh \
    -properties "${H2CONF}" \
    -baseDir "${H2DATA}/data" \
    -web \
    -webAllowOthers \
    -webPort 8080 \
    -tcp \
    -tcpAllowOthers \
    -tcpPort 1521
