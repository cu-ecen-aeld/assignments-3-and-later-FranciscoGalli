#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SYSROOTDIR=/home/fran/arm-cross-compiler/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
export CROSS_COMPILE
export PATH="$PATH:/home/fran/arm-cross-compiler/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin"


if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

if [ $? -ne 0 ]; then
	echo "mkdir failed with code $?"
	exit 1
fi

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    
    echo "STEP1: deep clean of kernel tree"
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- mrproper
    
    echo "STEP2: configure for virt arm device to be used with QEMU"
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig
    
    echo "STEP3: vmlinux target: build kernel image" 
    make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- all
    
    #echo "STEP4: build modules"
    #make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- modules
    
    #echo "STEP5: build device tree"
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- dtbs
    
fi

echo "Adding the Image in outdir"

cp ${OUTDIR}/linux-stable/arch/arm64/boot/Image ${OUTDIR}


echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

mkdir ${OUTDIR}/rootfs

# TODO: Create necessary base directories

echo "creating base directories for RootFS"
cd ${OUTDIR}/rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make menuconfig
        
else
    cd busybox
fi

# TODO: Make and install busybox

echo "Building BusyBox"
make distclean
make defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu-
echo "Installing BusyBox into RootFS and creating Symlinks"
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- install

echo "Library dependencies"
#${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
#${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs

cp ${SYSROOTDIR}/libc/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib
cp ${SYSROOTDIR}/libc/lib64/libm.so.6			${OUTDIR}/rootfs/lib64
cp ${SYSROOTDIR}/libc/lib64/libresolv.so.2		${OUTDIR}/rootfs/lib64
cp ${SYSROOTDIR}/libc/lib64/libc.so.6			${OUTDIR}/rootfs/lib64

echo "Dependencies copied"

# TODO: Make device nodes

cd ${OUTDIR}/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${SCRIPT_DIR}
make clean
make CROSS_COMPILE=aarch64-none-linux-gnu- all

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp writer ${OUTDIR}/rootfs/home
cp finder.sh ${OUTDIR}/rootfs/home
cp finder-test.sh ${OUTDIR}/rootfs/home
cp conf/username.txt ${OUTDIR}/rootfs/home
cp conf/assignment.txt ${OUTDIR}/rootfs/home
cp autorun-qemu.sh ${OUTDIR}/rootfs/home

# TODO: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
cd "$OUTDIR/rootfs"
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio 


