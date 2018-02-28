#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

ELASTIC_SERVER=${1:-localhost}
ELASTIC_PORT=${2:-9022}
ELASTIC_METHOD=${3:-http}
ELASTIC_URL="${ELASTIC_METHOD}://${ELASTIC_SERVER}:${ELASTIC_PORT}"

mkdir -p ${ZABBIX_DIR}/scripts/agentd/elasix
cp ${SOURCE_DIR}/elasix/elasix.conf.example ${ZABBIX_DIR}/scripts/agentd/elasix/elasix.conf
cp ${SOURCE_DIR}/elasix/elasix.sh ${ZABBIX_DIR}/scripts/agentd/elasix/
cp ${SOURCE_DIR}/elasix/zabbix_agentd.conf ${ZABBIX_DIR}/zabbix_agentd.d/elasix.conf
sed -i "s|ELASTIC_URL=.*|ELASTIC_URL=\"${ELASTIC_URL}\"|g" ${ZABBIX_DIR}/scripts/agentd/elasix/elasix.conf
