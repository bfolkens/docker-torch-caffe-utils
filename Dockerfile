FROM kaixhin/cuda-torch

# Install some dep packages

ENV CAFFE_PACKAGES libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev \
  libboost-all-dev libhdf5-serial-dev protobuf-compiler gfortran libjpeg62 \
  libfreeimage-dev libopenblas-dev git python-dev python-pip libgoogle-glog-dev \
  libbz2-dev libxml2-dev libxslt-dev libffi-dev libssl-dev libgflags-dev \
  liblmdb-dev python-yaml python-numpy luarocks

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
    wget -O build.sh https://raw.githubusercontent.com/facebook/thpp/master/thpp/build.sh && \
    sed -ie 's/gtest-1.7.0/googletest-release-1.7.0/g' CMakeLists.txt && \
    ./build.sh

RUN git clone -b v1.0 https://github.com/facebook/fblualib && \
    cd fblualib/fblualib && \
    sed -ie 's/" # python/ python"/g' build.sh && \
    curl "https://gist.githubusercontent.com/bfolkens/7857d8397ab560fca121b71cc7593174/raw/312f32345064a71fecad52ba591ed1ed0d58edca/fix_numpy_not_found_error.patch" | patch -p0 && \
    ./build.sh

RUN git clone https://github.com/facebook/fbtorch.git && \
    cd fbtorch && \
    luarocks make rocks/fbtorch-scm-1.rockspec

RUN git clone https://github.com/facebook/fbnn.git && \
    cd fbnn && \
    luarocks make rocks/fbnn-scm-1.rockspec

RUN git clone https://github.com/facebook/fb-caffe-exts.git && \
    luarocks install lualogging && \
    grep -Rl fb.util.logging torch2caffe | while read i; do sed -ie 's/fb.util.logging/logging/g' $i; done
