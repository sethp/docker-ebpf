# for docker desktop 2.0.0.3
# see: `docker run --rm alpine uname -r`
ARG RELEASE=4.9.125

FROM linuxkit/kernel:$RELEASE AS ksrc

FROM debian:stretch as bccbuild

RUN echo deb http://deb.debian.org/debian stretch-backports main > /etc/apt/sources.list.d/stretch-backports.list && \
    apt-get update && \
    apt-get -y install bison build-essential cmake flex git libedit-dev \
     libllvm6.0 llvm-6.0-dev libclang-6.0-dev python zlib1g-dev libelf-dev && \
    apt-get clean

ARG BCC_REF=master

RUN git clone --single-branch --depth=1 --branch $BCC_REF https://github.com/iovisor/bcc.git && \
    mkdir bcc/build; cd bcc/build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/bcc/usr && \
    make -j $(nproc) && \
    make install && \
    git rev-parse HEAD > /bcc/usr/BCC_VERSION

FROM golang:1.12-stretch
# https://github.com/moby/moby/issues/34129#issuecomment-417609075
ARG RELEASE

COPY --from=ksrc /kernel-dev.tar /

RUN tar xf /kernel-dev.tar -C / && \
    mkdir -p "/lib/modules/${RELEASE}-linuxkit/" && \
    ln -s "/usr/src/linux-headers-${RELEASE}-linuxkit/" "/lib/modules/${RELEASE}-linuxkit/build"

RUN apt-get update && \
    apt-get install -y git-core libelf-dev && \
    apt-get clean

RUN go get github.com/iovisor/gobpf 

WORKDIR $GOPATH/src/github.com/iovisor/gobpf

COPY --from=bccbuild /bcc/usr /usr

ENTRYPOINT mount -t debugfs nodev /sys/kernel/debug && exec bash
