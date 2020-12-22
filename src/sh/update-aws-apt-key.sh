#!/bin/bash

set -ex

# This file exists for the purpose of avoiding installing software-properties-common and
# gnupg-agent in the container just to run 'add-apt-repository'.

function main() {
    # https://docs.aws.amazon.com/corretto/
    local image_root="${1:-$IMAGE_ROOT}"
    local url="https://apt.corretto.aws/corretto.key"
    local destdir="${image_root:?}/usr/local/share/keyrings"
    local outfile="${destdir}/apt.corretto.aws.gpg"

    # Linux/macOS interop
    mkdir \
        -p \
        -v \
            "${destdir}"

    curl "${url}" \
    | gpg --dearmor \
    > "${outfile}"
}

main "$@"
