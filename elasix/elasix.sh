#!/usr/bin/env ksh
rcode=0
PATH=/usr/local/bin:${PATH}

#################################################################################

#################################################################################
#
#  Variable Definition
# ---------------------
#
APP_NAME=$(basename $0)
APP_DIR=$(dirname $0)
APP_VER="0.0.1"
APP_WEB="http://www.sergiotocalini.com.ar/"
TIMESTAMP=`date '+%s'`
CACHE_DIR=${APP_DIR}/tmp
CACHE_TTL=5                                      # IN MINUTES
#
#################################################################################

#################################################################################
#
#  Load Environment
# ------------------
#
[[ -f ${APP_DIR}/${APP_NAME%.*}.conf ]] && . ${APP_DIR}/${APP_NAME%.*}.conf

#
#################################################################################

#################################################################################
#
#  Function Definition
# ---------------------
#
usage() {
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo ""
    echo "Options:"
    echo "  -a            Query arguments."
    echo "  -h            Displays this help message."
    echo "  -j            Jsonify output."
    echo "  -s ARG(str)   Section (default=stat)."
    echo "  -v            Show the script version."
    echo ""
    echo "Please send any bug reports to sergiotocalini@gmail.com"
    exit 1
}

version() {
    echo "${APP_NAME%.*} ${APP_VER}"
    exit 1
}

refresh_cache() {
    [[ -d ${CACHE_DIR} ]] || mkdir -p ${CACHE_DIR}
    type=${1:-'cluster'}
    file=${CACHE_DIR}/${type}.json
    if [[ $(( `stat -c '%Y' "${file}" 2>/dev/null`+60*${CACHE_TTL} )) -le ${TIMESTAMP} ]]; then
	if [[ ${type} == 'cluster' ]]; then
	    RESOURCE="_cluster/stats"
	elif [[ ${type} == 'nodes' ]]; then
	    RESOURCE="_nodes/stats"
	elif [[ ${type} == 'health' ]]; then
	    RESOURCE="_cluster/health"
	elif [[ ${type} == 'indices' ]]; then
	    RESOURCE="_stats"
	elif [[ ${type} == 'root' ]]; then
	    RESOURCE=""
	else
	    return 1
	fi
	if ! [[ -z ${ELASTIC_USER} && -z ${ELASTIC_PASS} ]]; then
	    CURL_AUTH_FLAG="--user"
	    CURL_AUTH_ATTR+="${ELASTIC_USER}:${ELASTIC_PASS}"
	fi
	curl -s ${CURL_AUTH_FLAG} "${CURL_AUTH_ATTR}" \
	     "${ELASTIC_URL}/${RESOURCE}" 2>/dev/null | jq '.' 2>/dev/null > ${file}
    fi
    echo "${file}"
}

discovery() {
    resource=${1}
    json=$(refresh_cache ${resource})
    if [[ ${resource} == 'nodes' ]]; then
        IFS="," nodes=`jq -r '.nodes|keys|@csv' ${json} 2>/dev/null`
 	for item in ${nodes[@]}; do 
	    nodeuuid=`echo "${item}" | awk '{print substr($0, 2, length($0) - 2)}'`
            nodename=`jq -r ".nodes.\"${nodeuuid}\".name" ${json} 2>/dev/null`
            echo "${nodeuuid}|${nodename}"
        done
    elif [[ ${resource} == 'indices' ]]; then
        IFS="," indices=`jq -r '.indices|keys|@csv' ${json} 2>/dev/null`
        for item in ${indices[@]}; do
            echo "${item}" | awk '{print substr($0, 2, length($0) - 2)}'
        done
    fi
}

get_stat() {
    type=${1}
    name=${2}
    resource=${3}
    json=$(refresh_cache ${type})
    if [[ ${type} =~ (health|cluster|root) ]]; then
        res=`jq -r ".${name}" ${json} 2>/dev/null`
    elif [[ ${type} == 'indices' && ${name} == '_all' ]]; then
        res=`jq -r ".\"${name}\".${resource}" ${json} 2>/dev/null`
    else
        res=`jq -r ".${type}.\"${name}\".${resource}" ${json} 2>/dev/null`
    fi
    echo ${res}
}
#
#################################################################################

#################################################################################
while getopts "s::a:s:uphvj:" OPTION; do
    case ${OPTION} in
	h)
	    usage
	    ;;
	s)
	    SECTION="${OPTARG}"
	    ;;
        j)
            JSON=1
            IFS=":" JSON_ATTR=(${OPTARG//p=})
            ;;
	a)
	    ARGS[${#ARGS[*]}]=${OPTARG//p=}
	    ;;
	v)
	    version
	    ;;
         \?)
            exit 1
            ;;
    esac
done

if [[ ${JSON} -eq 1 ]]; then
    rval=$(discovery ${ARGS[*]})
    echo '{'
    echo '   "data":['
    count=1
    while read line; do
	if [[ ${line} != '' ]]; then
            IFS="|" values=(${line})
            output='{ '
            for val_index in ${!values[*]}; do
		output+='"'{#${JSON_ATTR[${val_index}]:-${val_index}}}'":"'${values[${val_index}]}'"'
		if (( ${val_index}+1 < ${#values[*]} )); then
                    output="${output}, "
		fi
            done 
            output+=' }'
            if (( ${count} < `echo ${rval}|wc -l` )); then
		output="${output},"
            fi
            echo "      ${output}"
	fi
        let "count=count+1"
    done <<< ${rval}
    echo '   ]'
    echo '}'
else
    if [[ ${SECTION} == 'stat' ]]; then
	rval=$( get_stat ${ARGS[*]} )
	rcode="${?}"
    elif [[ ${SECTION} == 'discovery' ]]; then
        rval=$(discovery ${ARGS[*]})
        rcode="${?}"
    fi
    echo "${rval:-0}" | sed "s/null/0/g"
fi

exit ${rcode}
