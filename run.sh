#!/bin/bash

declare -r SCRIPT_NAME=$(basename "$BASH_SOURCE" .sh)

## exit the shell(default status code: 1) after printing the message to stderr
bail() {
    echo -ne "$1" >&2
    exit ${2-1}
} 

## help message
declare -r HELP_MSG="Usage: $SCRIPT_NAME [-cdhkD]
  -c       run config only
  -d       run as a deamon
  -h       display this help and exit
  -k       keep old build
  -D       dry run
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

function check_env_variables {
  for var in "$@"
  do
    if [ -z "${!var}" ]
    then
        bail "$var is not defined as an environment variable\n"
    fi
  done
}

run() {
    local dry_run=$1
    shift
    local cmd="$*"
    if [ "$dry_run" -eq 1 ]; then
        echo $cmd
    else
        echo "running:" $cmd
        eval "$cmd"
    fi
}

build_args=" up --remove-orphans --build"
declare dry_run=0
while getopts ":cdhkD" opt; do
    case $opt in
        c)
            build_args=" config"
            ;;
        d)
            build_args+=" -d"
            ;;
        h)
            usage 0
            ;;
        k)
            declare keep_old=1
            ;;
        D)
            dry_run=1
            ;;
        \?)
            usage "Invalid option: -$OPTARG \n"
            ;;
    esac
done

check_env_variables DOCKER_VOLUMES

parent_dir=$(dirname "$(readlink -f "$0")")
readonly docker_root=$DOCKER_VOLUMES/$(basename "$parent_dir")
if [ ! -d $docker_root ]; then
    bail "$docker_root is not a directory\n"
fi

env="DOCKER_ROOT=$docker_root "
env_file=$docker_root/.env
if [ -f $env_file ]; then
    while IFS='=' read -r key val
    do
        if [[ $key != \#* ]]; then # ignore those values starting with #
            key=$(echo $key | tr '.' '_')
            env+="${key%% *}=$val "
        fi
    done < "$env_file"
fi

declare sync="rsync -rlic"
if [ "$dry_run" -eq 1 ]; then
    sync+="n"
fi
eval "$sync ghost/content/ $docker_root/content"

if [[ -z "$keep_old" ]]; then
    run $dry_run "docker-compose rm -fs" 
fi

run $dry_run "$env docker-compose $build_args"
