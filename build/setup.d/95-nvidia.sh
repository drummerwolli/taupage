#!/bin/bash

# See https://github.com/NVIDIA/nvidia-docker/wiki/Deploy-on-Amazon-EC2
# But we're using the run script to not depend on build tools
DRIVER_ARCH="Linux-x86_64"
DRIVER_VERSION="384.90"
DRIVER_FILENAME="NVIDIA-${DRIVER_ARCH}-${DRIVER_VERSION}.run"
DRIVER_CHECKSUM="487f9702d76d9eebea5b73b33fe4d602"

DOCKER_DRIVER_VERSION="1.0.1"
DOCKER_DRIVER_FILENAME="nvidia-docker_${DOCKER_DRIVER_VERSION}-1_amd64.deb"


apt-get update

pkgs="
build-essential
linux-headers-virtual-lts-xenial
"

# find latest headers
kernelname=$(ls -lah /usr/src/ | tail -n1 | sed 's/.*linux-headers-\([0-9a-z.-]\+\).*/\1/')
apt-get install -y -q --no-install-recommends -o Dpkg::Options::="--force-confold" $pkgs >>install.log

echo "Installing NVIDIA driver ver: ${DRIVER_VERSION}"

# Using the run File
wget -P /tmp "http://us.download.nvidia.com/XFree86/${DRIVER_ARCH}/${DRIVER_VERSION}/${DRIVER_FILENAME}"

filechecksum=($(md5sum "/tmp/${DRIVER_FILENAME}"))
# shellcheck disable=SC2128
if [[ "${filechecksum}" -ne "${DRIVER_CHECKSUM}" ]]; then
  echo "MD5 missmatch got: ${filechecksum} expected: ${DRIVER_CHECKSUM}"
  exit 1
fi

chmod +x "/tmp/${DRIVER_FILENAME}"

/tmp/$DRIVER_FILENAME -e -a -s --kernel-source-path "/usr/src/linux-headers-${kernelname}/" --kernel-name "${kernelname}"

echo "Installing nvidia docker ver: ${DOCKER_DRIVER_VERSION}"
wget -P /tmp "https://github.com/NVIDIA/nvidia-docker/releases/download/v${DOCKER_DRIVER_VERSION}/${DOCKER_DRIVER_FILENAME}"
dpkg -i "/tmp/${DOCKER_DRIVER_FILENAME}"

echo "Removing build packages driver"
apt-get purge -y -q  $pkgs >>install.log
