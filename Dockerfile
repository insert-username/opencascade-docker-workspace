# syntax=docker/dockerfile:1
FROM ubuntu:22.04
RUN apt-get update -y
RUN apt-get install git -y
RUN apt-get install cmake -y
RUN apt-get install wget -y

# fetch sources

RUN mkdir OCCT
WORKDIR OCCT
RUN git init
RUN git remote add origin "https://github.com/Open-Cascade-SAS/OCCT.git"
RUN git fetch --depth 1 origin V7_5_1
RUN git checkout FETCH_HEAD -b V7_5_1

WORKDIR /

RUN mkdir pythonocc-core
WORKDIR pythonocc-core
RUN git init
RUN git remote add origin "https://github.com/tpaviot/pythonocc-core.git"
RUN git fetch --depth 1 origin 7.5.1
RUN git checkout FETCH_HEAD -b 7.5.1

WORKDIR /

RUN wget https://www.vtk.org/files/release/9.1/VTK-9.1.0.tar.gz
RUN tar -xf VTK-9.1.0.tar.gz


#build vtk
WORKDIR VTK-9.1.0
RUN apt-get install build-essential mesa-common-dev mesa-utils freeglut3-dev ninja-build -y

# patch needed to fix: https://discourse.vtk.org/t/building-opencascade-7-5-0-with-vtk-9-0-1/4673/9
COPY vtk-patch.patch /vtk-patch.patch
RUN patch -i ../vtk-patch.patch -p1
RUN mkdir build
WORKDIR ./build
RUN cmake .. -GNinja -DCMAKE_BUILD_TYPE="Release"
RUN ninja -j 5
RUN ninja install

RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install libtcl -y

# build opencascade
WORKDIR /OCCT
RUN apt-get install libfreetype6-dev libtcl8.6 tk8.6-dev libxmu-dev libxi-dev -y
RUN mkdir build
WORKDIR ./build
RUN cmake .. -GNinja -DUSE_VTK=ON -D3RDPARTY_TCL_INCLUDE_DIR=/usr/include/tcl8.6/ -D3RDPARTY_VTK_INCLUDE_DIR=/usr/local/include/vtk-9.1/ -D3RDPARTY_FREETYPE_INCLUDE_DIR_freetype2=/usr/local/include -DBUILD_RELEASE_DISABLE_EXCEPTIONS=OFF -DCMAKE_BUILD_TYPE=Release -DUSE_FREETYPE=ON -DBUILD_LIBRARY_TYPE="Shared" -DBUILD_WITH_DEBUG=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON -D3RDPARTY_QT_DIR=/usr/bin/
RUN ninja -j 5
RUN ninja install

# build pythonocc-core
WORKDIR /pythonocc-core
RUN apt-get install python3.10-dev rapidjson-dev swig -y
RUN mkdir build
WORKDIR ./build
RUN cmake .. -GNinja -DCMAKE_BUILD_TYPE="Release"
RUN ninja -j 5
RUN ninja install

