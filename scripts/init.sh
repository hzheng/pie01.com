#!/bin/bash

declare -r SCRIPT_NAME=$(basename "$BASH_SOURCE")

## exit the shell(default status code: 1) after printing the message to stderr
bail() {
    echo -ne "$1" >&2
    exit ${2-1}
} 

## help message
declare -r HELP_MSG="Usage: $SCRIPT_NAME domain
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

install_certbot() {
    if ! test -x /usr/bin/certbot; then
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository ppa:certbot/certbot
        sudo apt-get install -y certbot python3-certbot-nginx
        sudo apt-get update
        sudo apt-get install -y certbot python3-certbot-nginx
    fi
    sudo certbot certonly --standalone -d $1 -d www.$1
}

if [ $# -lt 1 ]; then
    usage "Too few arguments\n"
fi

install_certbot $1
