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
    if [[ $(( `stat -c '%Y' "${file}"`+60*${CACHE_TTL} )) -le ${TIMESTAMP} ]]; then
	if [[ ${type} == 'cluster' ]]; then
	    RESOURCE="_cluster/stats"
	elif [[ ${type} == 'nodes' ]]; then
	    RESOURCE="_nodes/stats"
	elif [[ ${type} == 'health' ]]; then
	    RESOURCE="_cluster/health"
	elif [[ ${type} == 'indices' ]]; then
	    RESOURCE="_stats"
	fi
	curl -s "${ELASTIC_URL}/${RESOURCE}" 2>/dev/null | jq '.' > ${file}
    fi
    echo "${file}"
}

discovery() {
    resource=${1}
    json=$(refresh_cache ${resource})
    if [[ ${resource} != 'nodes' ]]; then
 	for item in `jq -r '.nodes|keys|@tsv' ${json}`; do 
	    echo ${item}
        done
    fi
}

get_stat() {
    resource=${1}
    json=$(refresh_cache ${resource})
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
            IFS=":" JSON_ATTR=(${OPTARG})
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

#if [[ -f "${SCRIPT%.sh}.sh" ]]; then
    if [[ ${JSON} -eq 1 ]]; then
       rval=$(discovery ${ARGS[*]})
       echo '{'
       echo '   "data":['
       count=1
       while read line; do
          IFS="|" values=(${line})
          output='{ '
          for val_index in ${!values[*]}; do
             output+='"'{#${JSON_ATTR[${val_index}]}}'":"'${values[${val_index}]}'"'
             if (( ${val_index}+1 < ${#values[*]} )); then
                output="${output}, "
             fi
          done 
          output+=' }'
          if (( ${count} < `echo ${rval}|wc -l` )); then
             output="${output},"
          fi
          echo "      ${output}"
          let "count=count+1"
       done <<< ${rval}
       echo '   ]'
       echo '}'
    else
	if [[ ${SECTION} == 'stat' ]]; then
	   rval=$( get_stat ${ARGS[*]} )
	   rcode="${?}"
        fi
	echo ${rval:-0}
    fi
#else
#    echo "ZBX_NOTSUPPORTED"
#    rcode="1"
#fi

exit ${rcode}