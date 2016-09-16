FROM kaixhin/cuda-torch

# Install some dep packages

ENV CAFFE_PACKAGES libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev \
  libboost-all-dev libhdf5-serial-dev protobuf-compiler gfortran libjpeg62 \
  libfreeimage-dev libopenblas-dev git python-dev python-pip libgoogle-glog-dev \
  libbz2-dev libxml2-dev libxslt-dev libffi-dev libssl-dev libgflags-dev \
  liblmdb-dev python-yaml python-numpy

ENV FBLUALIB_PACKAGES git unzip curl wget g++ automake autoconf autoconf-archive libtool \
  libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev \
  libgflags-dev liblz4-dev liblzma-dev libsnappy-dev make \
  zlib1g-dev binutils-dev libjemalloc-dev flex bison libkrb5-dev libsasl2-dev \
  libnuma-dev pkg-config libssl-dev libedit-dev libmatio-dev libpython-dev \
  libpython3-dev python-numpy

RUN apt-get update && \
    apt-get install -y git wget build-essential ${CAFFE_PACKAGES} ${FBLUALIB_PACKAGES} && \
    apt-get remove -y cmake

WORKDIR /usr/local/src

# Upgrade CMake for Caffe

RUN wget http://www.cmake.org/files/v3.2/cmake-3.2.2.tar.gz && \
    tar xf cmake-3.2.2.tar.gz && \
    cd cmake-3.2.2 && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    rm -rf /usr/local/src/cmake*

# Install caffe

RUN git clone https://github.com/BVLC/caffe.git && \
    cd caffe && \
    pip install --upgrade setuptools pip && \
    cat python/requirements.txt | xargs -L 1 pip install --upgrade && \
    echo 'set(BLAS "Open")' >> CMakeLists.txt && \
    mkdir -p build && \
    cd build && \
    cmake .. -DBLAS=Open -DCMAKE_INSTALL_PREFIX=/usr && \
    make -j"$(nproc)" all && \
#    make runtest && \
    make install && \
    rm -rf /usr/local/src/caffe*

# FBlualib and related Tools
# https://github.com/facebook/fblualib/blob/master/install_all.sh

RUN git clone -b v0.35.0  --depth 1 https://github.com/facebook/folly.git && \
    cd folly/folly && \
    autoreconf -ivf && \
    ./configure && \
    make && \
    make install && \
    ldconfig

RUN git clone -b v0.24.0  --depth 1 https://github.com/facebook/fbthrift.git && \
    cd fbthrift/thrift && \
    autoreconf -ivf && \
    ./configure && \
    make && \
    make install

RUN git clone -b v1.0 https://github.com/facebook/thpp && \
    cd thpp/thpp && \
    ./build.sh

RUN git clone -b v1.0 https://github.com/soumith/fblualib && \
    cd fblualib/fblualib && \
    ./build.sh

RUN git clone https://github.com/facebook/fb-caffe-exts.git
