#!/bin/bash

function dockerBuild() {
    if [[ "$#" -eq 0 ]]; then
        tag='latest'
    else
        tag="$1"
    fi
    DOCKER_BUILDKIT=1 docker build -t victorpi-vm:"$tag" .
}

dockerBuild "$@"
