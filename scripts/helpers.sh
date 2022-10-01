#!/bin/bash

function download() {
    curl -sL -O -C - "$1"
}
