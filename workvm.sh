#!/bin/bash

# https://wiki.freebsd.org/bhyve/UEFI

export MK_PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
export PATH="$MK_PATH"
export MK_SCRIPT="$0"
export MK_OPTS="$@"
export MK_TOPDIR=`cd \`dirname $MK_SCRIPT\`; pwd`

if [ ! -s "${MK_TOPDIR}/tbfs.sh" ]
then
        1>&2 echo "error: ${MK_TOPDIR}/tbfs.sh not found or empty."
        exit 1
fi
. ${MK_TOPDIR}/tbfs.sh

usage(){
	pecho "$MK_SCRIPT [-x] <windisk> [vnc port: 5900]"
	exit 1
}

runvnc(){
	pecho "starting vncviewer 127.0.0.1:$vncport ..."
	sleep 3
	vncviewer 127.0.0.1:$vncport &
}

if [ "$1" = "vnc" ]
then
	runvnc
	exit $?
fi

if [ "$1" = "stop" ]
then
	bhyvectl --destroy --vm=vm100
	exit $?
fi

if [ "$1" = "-x" ]
then
	set -x
	shift
fi

windisk="$1"
windisk="/home/david/ds/data/iso/mswindows/bhyve-win10vm/system-disk.raw"
windisk="//dev/da1"
vncport="$2"

if [ -z "$windisk" ]
then
	usage
fi
test -z "$vncport" && vncport=5900

if [ ! -f "$windisk" -a ! -c "$windisk" ]
then
	eecho "windisk $windisk not exist."
	exit 1
fi

if [ `id -u` -ne 0 ]
then
	pecho "sudo ..."
    sudo $MK_SCRIPT $MK_OPTS
    exit $?
fi

MAC="00:be:fa:76:41:00"

ifconfig tap0 destroy
sysctl -w net.link.tap.user_open=1
sysctl -w net.link.tap.up_on_open=1

kldload vmm
kldload nmdm
ifconfig tap0 create ether $MAC up
ifconfig bridge0 || ifconfig bridge0 create up
ifconfig bridge0 addm tap0
ifconfig 

bootdir=`dirname $windisk`
bootcd=${bootdir}/Win10_1511_1_Chinese_zhcn_x64.iso

windisk=`readlink -f $windisk`

tapmac=`ifconfig tap0 |grep 'ether '| awk '{print $2}'`
if [ -z "$tapmac" ]
then
	eecho "MAC address of tap0 not found"
	ifconfig tap0
	exit 1
fi

if [ "$MAC" != "$tapmac" ]
then
	eecho "MAC address of tap0 mismatch with $MAC"
	ifconfig tap0
	exit 1
fi

pecho "booting $windisk (tap0 mac: $tapmac), vnc: 127.0.0.1:$vncport ..."

runit(){
	bhyvectl --destroy --vm=vm100
	sleep 1

	# WARNING: do not use -l com1,stdio and & to run bhyve in background, will block networking
	bhyve -A -c 2 -m 4G -w -H \
	        -s 0,hostbridge \
			-s 3,ahci-cd,$bootcd \
	        -s 4:0,ahci-hd,$windisk \
	        -s 5,virtio-net,tap0,mac=$tapmac \
	        -s 29,fbuf,tcp=0.0.0.0:$vncport,w=1280,h=720,wait \
	        -s 31,lpc \
	        -l bootrom,/usr/local/share/uefi-firmware/BHYVE_UEFI.fd \
	        vm100 

			bhyvectl --destroy --vm=vm100
	        #-s 30,xhci,tablet \
	        #-s 4:1,ahci-hd,$systemdisk \
	        #-l com1,stdio \
			#-l com1,/dev/nmdm0A \

}

set -x
runit  &
set +x

runvnc 

exit $?

