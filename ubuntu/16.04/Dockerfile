FROM ubuntu:16.04
RUN rm -rf /var/lib/apt/lists/*
RUN apt-get update
RUN apt-get install -y build-essential clang-3.5 git maven autoconf libtool software-properties-common
RUN apt-get install -y python-dev python-six libcurl4-nss-dev libsasl2-dev libapr1-dev libsvn-dev libevent-dev libev-dev libssl-dev
RUN apt-get install -y wget curl sed
RUN apt-get install -y openjdk-8-jdk zlib1g-dev
RUN apt-get install -y iputils-ping
RUN add-apt-repository -y ppa:deadsnakes/ppa && apt-get update && apt-get install -qy python3.6 python3.6-dev python3.6-venv
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
RUN curl https://bootstrap.pypa.io/get-pip.py | python3
RUN adduser --disabled-password --gecos '' mesos
RUN curl -sSL https://cmake.org/files/v3.8/cmake-3.8.2-Linux-x86_64.sh -o /tmp/install-cmake.sh
RUN chmod u+x /tmp/install-cmake.sh && sync && /tmp/install-cmake.sh --skip-license --prefix=/usr/local
WORKDIR mesos
RUN chown -R mesos /mesos
USER mesos
ENV GLOG_v=1 MESOS_VERBOSE=1
