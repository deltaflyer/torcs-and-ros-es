FROM dorowu/ubuntu-desktop-lxde-vnc:bionic
LABEL maintainer="Oliver Wannenwetsch"

# fix apt-dependies from lxde-vnc docker image
RUN sed -i 's|http://tw.|http://|g' /etc/apt/sources.list && \
    sed -i 's|https://tw.|https://|g' /etc/apt/sources.list

# install torcs build dependencies
RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y \
            libglib2.0-dev \
            libgl1-mesa-dev \
            libglu1-mesa-dev \
            freeglut3-dev \
            libplib-dev \
            libopenal-dev \
            libalut-dev \
            libxi-dev \
            libxmu-dev \
            libxrender-dev \
            libxrandr-dev \
            libvorbis-dev \
            libpng-dev \
            cmake \
            mesa-utils \
            libalut-dev \
            libxrender1 \
            zlib1g-dev \
        && rm -rf /var/lib/apt/lists/*

# Add Ros installation
# install packages
RUN apt-get update && apt-get install -q -y \
    dirmngr \
    gnupg2 \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# setup sources.list
RUN echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -sc` main" > /etc/apt/sources.list.d/ros-latest.list

# install bootstrap tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    python-rosdep \
    python-rosinstall \
    python-vcstools \
    && rm -rf /var/lib/apt/lists/*

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# bootstrap rosdep
RUN rosdep init \
    && rosdep update

# install ros packages and opencv
ENV ROS_DISTRO melodic
RUN apt-get update && apt-get install -y \
    ros-melodic-desktop-full=1.4.1-0* \
    *opencv* \
    python-catkin-tools \
    && rm -rf /var/lib/apt/lists/*

# Create ros workspace
RUN echo "source /opt/ros/melodic/setup.bash" >> /root/.bashrc
RUN mkdir -p /root/workspace/src

# make desktop entries
RUN mkdir -p /root/Desktop \
        && echo "[Desktop Entry]" >> /root/Desktop/torcs.desktop \
        && echo "Type=Application" >> /root/Desktop/torcs.desktop \
        && echo "Exec=torcs" >> /root/Desktop/torcs.desktop \
        && cp /usr/share/applications/lxterminal.desktop /root/Desktop/

# Add torcs
ADD torcs-1.3.7/ /opt/torcs

# Compile torcs
WORKDIR /opt/torcs
ENV CFLAGS "-fPIC"
ENV CPPFLAGS "-fPIC"
ENV export CXXFLAGS "-fPIC"
RUN ./configure
RUN make
RUN make install
RUN make datainstall

# Add torcs config
ADD torcs_user_config /root/.torcs

# Integrate ROS torcs packages
ADD torcs_ros /opt/torcs_ros
RUN ln -s /opt/torcs_ros/* /root/workspace/src/ \
    && rm /root/workspace/src/README.md

# Install visual Studio code
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt install -y wget \
    && wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt install -y code \
    && rm -rf /var/lib/apt/lists/*
