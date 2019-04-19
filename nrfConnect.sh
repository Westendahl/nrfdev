#!/bin/bash

xhost +

USERGRP=$(stat -c '%u:%g' /home/$USER)

docker run -ti \
    --rm \
    -e DISPLAY=$DISPLAY \
    -v /dev/bus/usb:/dev/bus/usb \
    --privileged \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /home/$USER:/home/$USER\
    --workdir /home/$USER \
    --shm-size 2g \
    nrfconnect:2.6.2 /home/developer/squashfs-root/app/nrfconnect
    #-u $USERGRP \
    #-v /etc/passwd:/etc/passwd \
    #-v /etc/group:/etc/group \
