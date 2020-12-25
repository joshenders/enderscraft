#!/bin/bash


function main() {
    local server_jar="${SERVICE_HOME}/minecraft*.jar"

    java \
        -Xmx1024M \
        -Xms1024M \
        -jar "${server_jar}" \
            nogui
}


main "$@"