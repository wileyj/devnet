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
    # check if the defined container is actually running
    # this is not a failure mode though, since this check is only that a container is running - not that it may have been stopped
    #  print a warn and then try to start it after the sleep duration has passed
    if ! [ -n "$(docker ps -f "name=${container}" -f "status=running" -q )" ]; then
        echo "WARN: container (${container}) is not running"
    fi
    # check if sleep_duration is an integer.
    # if this is not an integer, print an error and exit (we cannot sleep for a non-integer number of seconds)
    if ! [ "$sleep_duration" -eq "$sleep_duration" ] 2>/dev/null; then
        echo "Error: sleep duration (${sleep_duration}) is not a number"
        echo "Exiting"
        exit 1
    fi
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
