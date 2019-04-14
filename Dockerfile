FROM ubuntu:16.04

ARG b_uid
ARG b_gid

ENV TERM xterm

ENV ARM_TOOLCHAIN https://developer.arm.com/-/media/Files/downloads/gnu-rm/8-2018q4/gcc-arm-none-eabi-8-2018-q4-major-linux.tar.bz2?revision=d830f9dd-cd4f-406d-8672-cca9210dd220?product=GNU%20Arm%20Embedded%20Toolchain,64-bit,,Linux,8-2018-q4-major

# turn off recommends on container OS
# install required dependencies
# THese are for nRFConnect
RUN apt-get update && \
    apt-get -y install \
        bzip2 \
        git \
        sudo \
        vim \
        libfontconfig1 \
        libglib2.0-0 \
        sudo \
        nano \
        locales \
        libgtk-3-0 \
        libxext6 \
        libxrender1 \
        libxtst6 \
        build-essential \
        unzip \
        zip \
        # Recommended by this rando https://github.com/josschne/ses/blob/master/config_3.50_sdk_15.2.0/Dockerfile \
        libx11-6 \
        libfreetype6 \
        libxrender1 \
        # Below is reccomended by nRF Connect \
        curl \
        wget \
        cmake \
        ninja-build \
        gperf \
        ccache \
        dfu-util \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        xz-utils \
        file \
        make \
        gcc-multilib \
        # xauth is needed to send open x window to DISPLAY's ip address (ssh only) \
        # xvfb is a virtual frame buffer for running toolchains headless \
        xauth xvfb \
        && \
    pip install nrfutil

# Install DTC by entering the following command (note that minimum version required is 1.4.6):
RUN [ $(apt-cache show device-tree-compiler | grep '^Version: .*$' | grep -Po '(\d.\d.\d+)' | sed s/\.//g) -ge '146' ] && sudo apt-get install device-tree-compiler || (wget http://mirrors.kernel.org/ubuntu/pool/main/d/device-tree-compiler/device-tree-compiler_1.4.7-1_amd64.deb && sudo dpkg -i device-tree-compiler_1.4.7-1_amd64.deb)

RUN wget $ARM_TOOLCHAIN /tmp/armtoolchain.tar.bz2

#RUN Xvfb :1 -screen 0 1024x768x16 &

# Sharing the x server with docker. See:
# http://fabiorehm.com/blog/2014/09/11/running-gui-apps-with-docker/
RUN export uid=${b_uid} gid=${b_gid} && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} /home/developer && \
    chown -R ${uid}:${gid} /opt

USER developer
ENV HOME /home/developer
WORKDIR /home/developer

# set up x server
ARG x_display
ENV DISPLAY ${x_display}
RUN sudo sh -c 'echo "ForwardX11Trusted yes" > /etc/ssh/ssh_config'
RUN sudo sh -c 'echo "ForwardX11 yes" > /etc/ssh/ssh_config'

RUN sudo apt-get install -qy 

# Use a locally downloaded Xilinx installer archive
ADD nrfconnect-2.6.2-x86_64.AppImage /tmp/

# Install SDK
RUN cd /tmp && \
    sudo chown -R developer:developer /opt && \
    sudo chown -R developer:developer /tmp && \
    chmod a+x /tmp/nrfconnect-2.6.2-x86_64.AppImage && \
    sync && \
    echo "Install nrf connect" && \
    /tmp/nrfconnect-2.6.2-x86_64.AppImage --appimage-extract

# Remove temp files to reduce image size
#RUN rm /tmp/nrfconnect-2.6.2-x86_64.AppImage

# Install extra packages
#   lin32ncurses5 - to compile lwip
#   libc6-dev - to compile Ultimo Library
#   libcanberra-gtk-module - for eclipse
#   lsb-release - for eclipse
#   udev - for JTAG cable drivers
#   iputils-ping - for SDK connecting to hw server (jtag drivers)
RUN sudo apt-get install -qy \
    libxss1 \
    libgconf-2-4 \
    libnss3 \
    lib32ncurses5 \
    libc6-dev \
    libcanberra-gtk-module \
    lsb-release \
    udev \
    iputils-ping

# Install JTAG drivers
#RUN cd /opt/Xilinx/SDK/2017.2/data/xicom/cable_drivers/lin64/install_script/install_drivers/ && \
#    sudo ./install_drivers

COPY entry.sh /usr/bin/
RUN echo "entry.sh" > /home/developer/.bashrc
