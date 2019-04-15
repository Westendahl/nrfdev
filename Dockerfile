FROM ubuntu:16.04

ARG b_uid
ARG b_gid

ENV TERM xterm

ENV ARM_TOOLCHAIN https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/7-2018q2/gcc-arm-none-eabi-7-2018-q2-update-linux.tar.bz2

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
        # For nRF Connect \
        libxss1 \
        libgconf-2-4 \
        libnss3 \
        libasound2 \
        # Reccomended by nRF Connect for SEGGER \
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
    rm -rf /var/lib/apt/lists/*


# Install DTC by entering the following command (note that minimum version required is 1.4.6):
RUN [ $(apt-cache show device-tree-compiler | grep '^Version: .*$' | grep -Po '(\d.\d.\d+)' | sed s/\.//g) -ge '146' ] && sudo apt-get install device-tree-compiler || (wget http://mirrors.kernel.org/ubuntu/pool/main/d/device-tree-compiler/device-tree-compiler_1.4.7-1_amd64.deb && sudo dpkg -i device-tree-compiler_1.4.7-1_amd64.deb)

# Sharing the x server with docker. See:
# http://fabiorehm.com/blog/2014/09/11/running-gui-apps-with-docker/
RUN export uid=${b_uid} gid=${b_gid} && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} /home/developer && \
    chown -R ${uid}:${gid} /opt && \
    chown -R developer:developer /opt && \
    chown -R developer:developer /tmp

USER developer
ENV HOME /home/developer
WORKDIR /home/developer

# Install gcc toolchain
RUN mkdir -p /opt/gnuarmemb && \
    curl $ARM_TOOLCHAIN -o /tmp/armtools.tar.bz2 && \
    tar -xjf /tmp/armtools.tar.bz2 --directory /opt/gnuarmemb/ && \
    rm /tmp/armtools.tar.bz2

# Install nRF Connect
ADD nrfconnect-2.6.2-x86_64.AppImage /tmp/
RUN sudo chmod a+x /tmp/nrfconnect-2.6.2-x86_64.AppImage && \
    sync && \
    echo "Install nrf connect" && \
    /tmp/nrfconnect-2.6.2-x86_64.AppImage --appimage-extract && \
    rm /tmp/nrfconnect-2.6.2-x86_64.AppImage

# Install nRF Connect SDK
RUN pip3 install --user west && \
    export PATH=$PATH:/home/developer/.local/bin && \
    cd /home/developer && \
    mkdir ncs && \
    cd ncs && \
    west init -m https://github.com/NordicPlayground/fw-nrfconnect-nrf && \
    cd /home/developer/ncs/nrf && \
    git checkout master && \
    west update && \
    cd /home/developer/ncs && \
    pip3 install --user --upgrade setuptools && \
    pip3 install --user 'pyyaml<5.0,>=4.2b1' --force-reinstall && \
    pip3 install --user -r zephyr/scripts/requirements.txt && \
    pip3 install --user -r nrf/scripts/requirements.txt

# Install seggar ide
RUN mkdir -p /opt/segger && \
    curl https://www.segger.com/downloads/embedded-studio/embeddedstudio_arm_nordic_linux_x64 -o /tmp/segger.tar.gz && \
    tar -xzf /tmp/segger.tar.gz --directory /opt/segger/ && \
    rm /tmp/segger.tar.gz

# Install JTAG drivers
#RUN cd /opt/Xilinx/SDK/2017.2/data/xicom/cable_drivers/lin64/install_script/install_drivers/ && \
#    sudo ./install_drivers
ENV ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
ENV GNUARMEMB_TOOLCHAIN_PATH="/gnuarmemb"
ENV QT_GRAPHICSSYSTEM="native"

# Install extra packages
#   lin32ncurses5 - to compile lwip
#   libc6-dev - to compile Ultimo Library
#   libcanberra-gtk-module - for eclipse
#   lsb-release - for eclipse
#   udev - for JTAG cable drivers
#   iputils-ping - for SDK connecting to hw server (jtag drivers)
#RUN sudo apt-get update && sudo apt-get install -qy \
#    libcanberra-gtk-module
#    libgtk2.0-0 \
#    lsb-release \
#    lib32ncurses5 \
#    libc6-dev \
#    udev \
#    iputils-ping \
#    libx11-6 libfreetype6 libxrender1 libfontconfig1 libxext6 python-pip

COPY entry.sh /usr/bin/
RUN echo "entry.sh" > /home/developer/.bashrc
