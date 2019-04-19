#!/bin/bash

export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
export GNUARMEMB_TOOLCHAIN_PATH="/gnuarmemb"
export QT_GRAPHICSSYSTEM="native"

source /home/developer/ncs/zephyr/zephyr-env.sh

if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
    echo running command "$@"
    exec "$@"
elif [[ $# -ge 1 ]]; then
    echo "ERROR: command not found: $1"
    exit 13
else
    exec /opt/segger/arm_segger_embedded_studio_v416_linux_x64_nordic/bin/emStudio
fi
