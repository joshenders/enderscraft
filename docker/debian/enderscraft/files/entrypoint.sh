#!/bin/bash

set -x

function exit_with_error() {
    # usage: exit_with_error "error message"

    echo "${0##*/}: $*" >&2
    exit 1
}

function main() {
    local regex='^(true|1|yes|accept)$'

    if [[ "${ACCEPT_EULA,,}" =~ $regex ]]; then
        echo 'eula=true' | tee "${MINECRAFT_HOME}/eula.txt"
    else
        exit_with_error "You must agree to the EULA in order to run this server. See README.md for details."
    fi

    java \
        -Xmx1024M \
        -Xms1024M \
        -jar "${MINECRAFT_HOME}"/minecraft_server-*.jar \
            nogui
}


main "$@"