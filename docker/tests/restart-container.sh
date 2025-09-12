#!/bin/env bash

container=${1}
sleep_duration=${2}
function help(){
    echo
    echo "Usage:"
    echo "${0} <container> <sleep duration in seconds>"
    echo "  - container: valid container name from output of 'docker ps'"
    echo "  - sleep_duration: time to sleep (in seconds) before restarting container"
    echo "ex: ${0} stacks-miner-3 241"
    echo "  will stop stacks-miner-3 for 241s, then start the container again"
    echo
    exit 1
}
if ! [[ "${container}" && "${sleep_duration}" ]];then
    help
else
    echo "Stopping (${container})"
    docker stop ${container} 1> /dev/null # stop container without printing to stdout (stderr should still print)
    if [ "$?" -ne "0" ]; then
        # command error output should be sufficient to know what went wrong
        echo
        exit 1
    fi
    while [ $sleep_duration -gt 0 ]; do
        printf "    - Sleeping ...  \b [ %ss ] \033[0K\r" "${sleep_duration}" # sleep duration countdown, decrement each loop iteration
       	sleep_duration=$((sleep_duration-1))
       	sleep 1
    done
    echo "    - Slept for ${2}s"
    echo "Starting (${container})"
    docker start ${container} 1> /dev/null # start container without printing to stdout (stderr should still print)
    if [ "$?" -ne "0" ]; then
        # command error output should be sufficient to know what went wrong
        echo
        exit 1
    fi
fi
exit 0
