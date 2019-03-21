# for docker desktop 2.0.0.3
ARG RELEASE=4.9.125

FROM linuxkit/kernel:$RELEASE AS ksrc

FROM ubuntu
# https://github.com/moby/moby/issues/34129#issuecomment-417609075
ARG RELEASE

COPY --from=ksrc /kernel-dev.tar /

RUN tar xf kernel-dev.tar && \
    mkdir -p "/lib/modules/${RELEASE}-linuxkit/" && \
    ln -s "/usr/src/linux-headers-${RELEASE}-linuxkit/" "/lib/modules/${RELEASE}-linuxkit/build"

RUN apt-get update && \
    apt-get install -y golang-go bpfcc-tools git-core && \
    apt-get clean

ENV GOPATH /go
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

RUN go get github.com/iovisor/gobpf 

WORKDIR $GOPATH/src/github.com/iovisor/gobpf

ENTRYPOINT mount -t debugfs nodev /sys/kernel/debug && exec bash
