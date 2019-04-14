#!/bin/bash
source ../config.sh

docker pull $DOCKER_REGISTRY/sdk:2017.2

# Directory where temperary install files are located
TMP_DIR=/home/$USER/xilinxDrivers/

if [ -d $TMP_DIR ]; then
    rm -rf $TMP_DIR;
fi

mkdir TMP_DIR

# log in as the user running this script
USERGRP=$(stat -c '%u:%g' /home/$USER)

# Pipe a command into docker to copy the drivers onto the host.
# Do not run the docker with -t
echo "cp -rf /opt/Xilinx/SDK/2017.2/data/xicom/cable_drivers/lin64/install_script/install_drivers $TMP_DIR && exit" | docker run -i \
	--rm \
    -u $USERGRP \
    -v /etc/passwd:/etc/passwd \
    -v /etc/group:/etc/group \
	-v /home/$USER:/home/$USER\
	--entrypoint "/bin/bash" \
	$DOCKER_REGISTRY/sdk:2017.2

cd $TMP_DIR
sudo ./install_drivers
cd
rm -rf $TMP_DIR
