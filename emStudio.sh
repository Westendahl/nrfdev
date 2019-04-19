#!/bin/bash

xhost +

USERGRP=$(stat -c '%u:%g' /home/$USER)

docker run -ti \
    --rm \
    -e DISPLAY=$DISPLAY \
    --privileged \
    -v /dev/bus/usb:/dev/bus/usb \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    --shm-size 2g \
    -u $USERGRP \
    -v /etc/passwd:/etc/passwd \
    -v /etc/group:/etc/group \
    -v /home/$USER:/home/$USER \
    -e HOME=$HOME \
    --workdir /home/$USER \
    nrfconnect:2.6.2 $@
