#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

ELASTIC_URL=${1:-'http://localhost:9022'}
ELASTIC_USER=${4:-monitor}
ELASTIC_PASS=${5:-m0n1t0r}

mkdir -p ${ZABBIX_DIR}/scripts/agentd/elasix

SCRIPT_CONFIG=${ZABBIX_DIR}/scripts/agentd/elasix/elasix.conf
if [[ -f ${SCRIPT_CONFIG} ]]; then
    SCRIPT_CONFIG=${ZABBIX_DIR}/scripts/agentd/elasix/elasix.conf.new
fi

cp -rpv ${SOURCE_DIR}/elasix/elasix.conf.example ${SCRIPT_CONFIG}
cp -rpv ${SOURCE_DIR}/elasix/elasix.sh           ${ZABBIX_DIR}/scripts/agentd/elasix/
cp -rpv ${SOURCE_DIR}/elasix/zabbix_agentd.conf  ${ZABBIX_DIR}/zabbix_agentd.d/elasix.conf

regex_array[0]="s|ELASTIC_URL=.*|ELASTIC_URL=\"${ELASTIC_URL}\"|g"
regex_array[1]="s|ELASTIC_USER=.*|ELASTIC_USER=\"${ELASTIC_USER}\"|g"
regex_array[2]="s|ELASTIC_PASS=.*|ELASTIC_PASS=\"${ELASTIC_PASS}\"|g"
for index in ${!regex_array[*]}; do
    sed -i "${regex_array[${index}]}" ${SCRIPT_CONFIG}
done

