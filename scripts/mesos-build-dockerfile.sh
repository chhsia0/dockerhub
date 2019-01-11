#!/usr/bin/env bash

set -xe

# This is the script used by ASF Jenkins to build and check Mesos for
# a given OS and compiler combination.

# Require the following environment variables to be set.
: ${OS:?"Environment variable 'OS' must be set (e.g., OS=ubuntu:14.04)"}

DOCKERFILE=${1:-Dockerfile}

rm -f $DOCKERFILE # Just in case a stale one exists.

# Helper function that appends instructions to docker file.
function append_dockerfile {
   echo $1 >> $DOCKERFILE
}


# TODO(vinod): Add support for Fedora and Debian.
case $OS in
  centos*)
    # NOTE: Currently we only support CentOS7+ due to the
    # compiler versions needed to compile Mesos.

    append_dockerfile "FROM $OS"

    # Install dependencies.

    append_dockerfile "RUN yum install -y which"
    append_dockerfile "RUN yum groupinstall -y 'Development Tools'"
    append_dockerfile "RUN yum install -y epel-release" # Needed for clang.
    append_dockerfile "RUN yum install -y clang git maven"
    append_dockerfile "RUN yum install -y java-1.8.0-openjdk-devel python-devel python-six zlib-devel libcurl-devel openssl-devel cyrus-sasl-devel cyrus-sasl-md5 apr-devel subversion-devel apr-utils-devel libevent-devel libev-devel"

    # Install Python 3.6.
    append_dockerfile "RUN yum install -y python36 python36-devel"
    # Use update-alternatives to set python3.6 as python3.
    append_dockerfile "RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1"
    # Install pip for Python 3.6.
    append_dockerfile "RUN curl https://bootstrap.pypa.io/get-pip.py | python3"
    # Install virtualenv to /usr/bin/virtualenv with pip.
    append_dockerfile "RUN pip3 install --no-cache-dir virtualenv"

    # Add an unprivileged user.
    append_dockerfile "RUN adduser mesos"
   ;;
  *ubuntu*)
    # NOTE: Currently we only support Ubuntu13.10+ due to the
    # compiler versions needed to compile Mesos.

    append_dockerfile "FROM $OS"

    # NOTE: We need to do this to fix some flakiness while fetching packages.
    # See https://bugs.launchpad.net/ubuntu/+source/apt/+bug/972077
    append_dockerfile "RUN rm -rf /var/lib/apt/lists/*"

    # Install dependencies.
    # IBM Power only supports Ubuntu 14.04 and gcc compiler.
    [ "$(uname -m)" = "x86_64" ] && CLANG_PKG=clang-3.5 || CLANG_PKG=
    append_dockerfile "RUN apt-get update"
    append_dockerfile "RUN apt-get install -y build-essential $CLANG_PKG git maven autoconf libtool software-properties-common"
    append_dockerfile "RUN apt-get install -y python-dev python-six libcurl4-nss-dev libsasl2-dev libapr1-dev libsvn-dev libevent-dev libev-dev libssl-dev"
    append_dockerfile "RUN apt-get install -y wget curl sed"

    case $OS in
      *16.04*)
        echo "Install Ubuntu 16.04 LTS (Xenial Xerus) specific packages"
        append_dockerfile "RUN apt-get install -y openjdk-8-jdk zlib1g-dev"
        # Install ping required by OsTest.Which
        append_dockerfile "RUN apt-get install -y iputils-ping"

        # Install Python 3.6.
        append_dockerfile "RUN add-apt-repository -y ppa:deadsnakes/ppa && apt-get update && apt-get install -qy python3.6 python3.6-dev python3.6-venv"
        # Use update-alternatives to set python3.6 as python3.
        append_dockerfile "RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1"
        # Install pip for Python 3.6.
        append_dockerfile "RUN curl https://bootstrap.pypa.io/get-pip.py | python3"
       ;;
      *)
        append_dockerfile "RUN apt-get install -y openjdk-7-jdk"
       ;;
    esac

    # Add an unpriviliged user.
    append_dockerfile "RUN adduser --disabled-password --gecos '' mesos"
    ;;
  *)
    echo "Unknown OS $OS"
    exit 1
    ;;
esac

# Install a more recent version of CMake than can be installed via packages.
#
# NOTE: We call `sync` before launching the script to workaround the docker bug.
# See https://github.com/moby/moby/issues/9547
#
# TODO(abudnik): Skip this step, when a newer version of CMake package is
# available in OS repository.
append_dockerfile "RUN curl -sSL https://cmake.org/files/v3.8/cmake-3.8.2-Linux-x86_64.sh -o /tmp/install-cmake.sh"
append_dockerfile "RUN chmod u+x /tmp/install-cmake.sh && sync && /tmp/install-cmake.sh --skip-license --prefix=/usr/local"

# Set working directory.
append_dockerfile "WORKDIR mesos"

# NOTE: We run all the tests as unprivileged 'mesos' user because
# we need to fix cgroups related tests to work inside Docker; certain
# tests (e.g., ContainerizerTest) enable cgroups isolation if the user
# is 'root'.
# TODO(vinod): Fix cgroups tests to work inside Docker.
append_dockerfile "RUN chown -R mesos /mesos"
append_dockerfile "USER mesos"

# Set the environment for build.
append_dockerfile "ENV GLOG_v=1 MESOS_VERBOSE=1"
