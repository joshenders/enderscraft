#!/bin/bash
# This file should consist of only shell builtins

function main() {
    # usage: check_dependencies "list of external programs"
    local dependencies=("$@")

    for bin in "${dependencies[@]}"; do
        echo -n "checking for ${bin}... "
        local obj
        obj="$(type -t "${bin}")"
        if [[ "${obj}" == 'alias' ]]; then
            echo "command alias"
            continue
        elif [[ "${obj}" == 'builtin' ]]; then
            echo "shell builtin"
            continue
        elif [[ "${obj}" == 'function' ]]; then
            echo "shell function"
            continue
        elif [[ "${obj}" == 'keyword' ]]; then
            echo "shell keyword"
            continue
        elif [[ "$(type "${bin}" >/dev/null 2>&1; echo $?)" != '0' ]]; then
            echo -e "not found\n"
            echo "${0##*/}: error: Please verify that '${bin}' is installed to \$PATH before continuing" >&2
            exit 1
        else
            type -P "${bin}"
            fi
    done

    echo -e "\nAll dependencies appear to be installed"
}

main "$@"
