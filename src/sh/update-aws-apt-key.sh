#!/bin/bash

set -ex

# This file exists for the purpose of avoiding installing software-properties-common and
# gnupg-agent in the container just to run 'add-apt-repository'.

function main() {
    # https://docs.aws.amazon.com/corretto/
    local url="https://apt.corretto.aws/corretto.key"
    local destdir="${BUILD_DIR:-$PWD}/docker/files/usr/local/share/keyrings"
    local outfile="${destdir}/apt.corretto.aws.gpg"

    if [[ $(uname -s) == 'Darwin' ]]; then
        mkdir \
            -p \
            -v \
                "${destdir}"
    elif [[ $(uname -s) == 'Linux' ]]; then
        mkdir \
            --parents \
            --verbose \
                "${destdir}"
    fi

    curl "${url}" \
    | gpg --dearmor \
    > "${outfile}"
}

main "$@"
