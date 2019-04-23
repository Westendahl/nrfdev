#!/bin/bash

xhost +

sudo docker build \
	--network host \
	--build-arg b_uid=`id -u $USER` \
	--build-arg b_gid=`id -g $USER` \
	--build-arg x_display=$DISPLAY \
	-t nrfconnect:2.6.2 .
