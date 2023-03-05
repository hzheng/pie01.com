#!/bin/bash

declare -r SCRIPT_NAME=$(basename "$BASH_SOURCE")

## exit the shell(default status code: 1) after printing the message to stderr
bail() {
    echo -ne "$1" >&2
    exit ${2-1}
} 

## help message
declare -r HELP_MSG="Usage: $SCRIPT_NAME [-H host] [-p port] backup-tar-path
  -h       display this help and exit
  -H       mysql host
  -p       mysql port
"

## print the usage and exit the shell(default status code: 2)
usage() {
    declare status=2
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        status=$1
        shift
    fi
    bail "${1}$HELP_MSG" $status
}

load_env() {
    local env=
    local env_file=$1
    if [ -f $env_file ]; then
        while IFS='=' read -r key val
        do
            if [[ -n "${val}" && $key != \#* ]]; then # ignore those values starting with #
                key=$(echo $key | tr '.' '_')
                env+="${key%% *}=$val "
            fi
        done < "$env_file"
    fi
    echo $env
}

parent_dir=$(dirname $(dirname "$(readlink -f "$0")"))
readonly docker_root=$DOCKER_VOLUMES/$(basename "$parent_dir")
if [ ! -d $docker_root ]; then
    bail "$docker_root is not a directory\n"
fi
env=$(load_env $docker_root/.env)
env+=' '
env+=$(load_env $parent_dir/.env)
eval $env

DB_HOST=${DB_SUBNET_PREFIX}.1
while getopts ":hH:p:" opt; do
    case $opt in
        h)
            usage 0
            ;;
        H)
            DB_HOST=${OPTARG}
            ;;
        p)
            DB_PORT=${OPTARG}
            ;;
        \?)
            usage "Invalid option: -$OPTARG \n"
            ;;
    esac
done

shift $(($OPTIND - 1))

#==========MAIN CODE BELOW==========

[ "$#" -lt 1 ] && usage

readonly DEST_FILE="$1"

set -o pipefail
mysqldump -h $DB_HOST -P ${DB_PORT-3306} -u ${DB_USER-root} -p$DB_PASSWORD --all-databases | gzip > $DEST_FILE
