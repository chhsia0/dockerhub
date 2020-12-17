FROM golang:alpine as podman-build
RUN apk add --no-cache git make gcc pkgconf musl-dev btrfs-progs btrfs-progs-dev libassuan-dev lvm2-dev device-mapper glib-dev glib-static libc-dev gpgme-dev protobuf-dev protobuf-c-dev libseccomp-dev libselinux-dev ostree-dev openssl bash
WORKDIR $GOPATH

# runc
ARG RUNC_VERSION=v1.0.0-rc6
RUN set -eux; \
    git clone --branch ${RUNC_VERSION} https://github.com/opencontainers/runc src/github.com/opencontainers/runc; \
    cd src/github.com/opencontainers/runc; \
    make static BUILDTAGS='seccomp selinux ambient'; \
    mv runc /usr/local/bin/runc

# cri-o
ARG CRIO_VERSION=v1.13.0
RUN set -eux; \
    git clone --branch ${CRIO_VERSION} https://github.com/kubernetes-sigs/cri-o src/github.com/kubernetes-sigs/cri-o; \
    cd src/github.com/kubernetes-sigs/cri-o; \
    mkdir bin; \
    make bin/conmon CFLAGS='-std=c99 -Os -Wall -Wextra -static'; \
    install -D -m 755 bin/conmon /usr/libexec/podman/conmon

# podman
ARG PODMAN_VERSION=v1.0.0
RUN set -eux; \
    git clone --branch ${PODMAN_VERSION} https://github.com/containers/libpod src/github.com/containers/libpod; \
    cd src/github.com/containers/libpod; \
    make install.tools; \
    make LDFLAGS="-w -extldflags '-static'" BUILDTAGS='seccomp selinux varlink exclude_graphdriver_devicemapper containers_image_ostree_stub containers_image_openpgp'; \
    mv bin/podman /usr/local/bin/podman

FROM alpine
RUN apk add --update --no-cache iptables ip6tables curl
COPY --from=podman-build /usr/local/bin/runc /usr/local/bin/runc
COPY --from=podman-build /usr/local/bin/podman /usr/local/bin/podman
COPY --from=podman-build /usr/libexec/podman/conmon /usr/libexec/podman/conmon
RUN set -eux; \
    adduser -D podman -h /podman -u 9000; \
    echo 'podman:900000:65536' > /etc/subuid; \
    echo 'podman:900000:65536' > /etc/subgid; \
    mkdir -pm 755 /etc/containers; \
    chown -R root:podman /podman; \
    curl -o /etc/containers/registries.conf https://raw.githubusercontent.com/projectatomic/registries/master/registries.fedora; \
    curl -o /etc/containers/policy.json https://raw.githubusercontent.com/containers/skopeo/master/default-policy.json; \
    podman --help > /dev/null
WORKDIR /podman
ENV HOME=/podman
