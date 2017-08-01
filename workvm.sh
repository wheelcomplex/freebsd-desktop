#!/bin/bash

# https://wiki.freebsd.org/bhyve/UEFI

export MK_PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
export PATH="$MK_PATH"
export MK_SCRIPT="$0"
export MK_OPTS="$@"
export MK_WORKBASE="/home/david/ds/workvm"

# YES to enable debug
export PDEBUG=""

necho(){
	local msg="$@"
	if [ -z "$msg" ]
	then
		1>&2 echo " -"
	else
		1>&2 echo " - $msg"
	fi
}

pecho(){
	local msg="$@"
	if [ -z "$msg" ]
	then
		1>&2 echo " -"
	else
		1>&2 echo " - `date` $msg"
	fi
}

iecho(){
		pecho "INFO: $@"
}

eecho(){
		pecho "ERROR: $@"
}

decho(){
		test "$PDEBUG" != "1" || 1>&2 pecho "DEBUG: $@"
}

efecho(){
	local msg="$@"
	local fn=${FUNCNAME[1]}
	eecho "$fn: $msg"
}

pfecho(){
	local msg="$@"
	local fn=${FUNCNAME[1]}
	pecho "$fn: $msg"
}

genmac(){
	local msg="$@"
	if [ -z "$msg" ]
	then
		echo -n 02-60-2F; dd bs=1 count=3 if=/dev/random 2>/dev/null |hexdump -v -e '/1 "-%02X"'
	else
		echo -n 02-60-2F; echo "$msg" | md5 | dd bs=1 count=3 2>/dev/null |hexdump -v -e '/1 "-%02X"'
	fi
}

pathprune(){
	local line="$1"
	test -z "$line"&&return 0
	local pline=""
	while [ "$line" != "$pline" ]
	do
		pline="$line"
		line=`echo "$line" | sed -e 's#//#/#g'`
	done
	echo "$line"
}

usage(){
	pecho "$MK_SCRIPT [-x] [-novnc] <vm name> [stop]"
	exit 1
}

runit(){

	pecho ""
	pecho "CMD: $vmcmd"
	pecho ""
	
	$vmcmd

	for aaa in `seq 0 5`
	do
		echo -n '.'
		isvmrun $VM_NAME 
		if [ $? -ne 0 ]
		then
			pecho ""
			pecho "$VM_NAME stopped." && break
			pecho ""
		fi
		sleep 1
	done
	echo ""
	$MK_SCRIPT $VM_NAME stop
	exit $?
}

runrdp(){
	local trycnt="$1"
	local manual="$2"
	test -z "$trycnt" -o "$trycnt" = "manual" && trycnt=3

	test -z "$VM_CONSOLE_IP" && VM_CONSOLE_IP=`cat $VM_CFG_DIR/console.ip 2>/dev/null| head -n1`
	if [ -z "$VM_CONSOLE_IP" ]
	then
		eecho "CONSOLE NOT FOUND: $VM_CFG_DIR/console.ip"
		exit 1
	fi
	pecho ""
	pecho "RDP: user $VM_RDP_USER, screen $VM_RDP_WH, IP $VM_CONSOLE_IP"
	pecho ""
	export VM_RDP_BASE="rdesktop -a 32 -f -k en-us -D"
	export VM_RDP_VIEWER_CMD="$VM_RDP_BASE -u $VM_RDP_USER -p $VM_RDP_PASSWORD -z -r clipboard:PRIMARYCLIPBOARD -g $VM_RDP_WH $VM_CONSOLE_IP"
	# pecho "RPD CMD: $VM_RDP_VIEWER_CMD"
	pecho ""
	pecho "Ctrl + Alt + Enter to toggle between window and fullscreen"
	pecho ""

	if [ "$manual" = "manual" ]
	then
		pecho ""
		pecho "manual rdesktop command: $VM_RDP_VIEWER_CMD"
		pecho ""
		return 0
	fi
	ps axuww| grep -- "$VM_RDP_BASE" | grep -v grep | grep -- "-u $VM_RDP_USER -p $VM_RDP_PASSWORD" | grep -q -- "-g $VM_RDP_WH $VM_CONSOLE_IP"
	if [ $? -eq 0 ]
	then
		eecho "rdesktop viewer already running."
		ps axuww | grep -- "-u $VM_RDP_USER -p $VM_RDP_PASSWORD" | grep -- "-g $VM_RDP_WH $VM_CONSOLE_IP"
		exit 1
	fi
	for aaa in `seq 0 $trycnt`
	do
		echo -n '.'
		isvmrun $VM_NAME && pecho "$VM_NAME running ..." && break
		sleep 1
	done

	echo ""

	$VM_RDP_VIEWER_CMD

	exit $?
}

runvnc(){
	local trycnt="$1"
	local manual="$2"
	test -z "$trycnt" -o "$trycnt" = "manual" && trycnt=3

	export VM_VNC_VIEWER_CMD="$VM_VNC_BASE ${VM_VNC_BIND}:$VM_VNC_PORT"
	pecho "starting vncviewer for $VM_NAME: ${VM_VNC_BIND}:$VM_VNC_PORT ..."
	if [ "$manual" = "manual" ]
	then
		pecho ""
		pecho "manual vncviewer command: $VM_VNC_VIEWER_CMD"
		pecho ""
		return 0
	fi
	ps axuww| grep -- "$VM_VNC_BASE" | grep -v grep | grep -q -- ":$VM_VNC_PORT"
	if [ $? -eq 0 ]
	then
		eecho "vnc viewer already running."
		ps axuww| grep -- "$VM_VNC_VIEWER_CMD" | grep -v grep
		exit 1
	fi
	for aaa in `seq 0 $trycnt`
	do
		echo -n '.'
		isvmrun $VM_NAME && pecho "$VM_NAME running ..." && break
		sleep 1
	done
	echo ""
	sockstat -4 -l | grep ":$VM_VNC_PORT"
	sockstat -4 -l | grep -q ":$VM_VNC_PORT" && isvmrun $VM_NAME
	if [ $? -ne 0 ]
	then
		eecho "vnc port $VM_VNC_PORT is not listening"
		exit 1
	fi
	$VM_VNC_VIEWER_CMD
	exit $?
}

isvmrun(){
	# return 0 for running
	local VM_NAME="$1"
	test -z "$VM_NAME" && efecho "need vm name arg"&&exit 1
	ps axuww| grep bhyve | grep -v grep | grep -q "bhyve: vm$VM_NAME "
	return $?
}

xtrace=""
if [ "$1" = "-x" ]
then
	set -x
	xtrace="-x"
	shift
fi

viewer=0
if [ "$1" = "-viewer" ]
then
	viewer=1
	shift
fi

export VM_NAME="$1"
if [ -z "$VM_NAME" ]
then
	usage
	exit 1
fi
shift

export VM_DIR="$MK_WORKBASE/data/$VM_NAME/"
export VM_CFG_DIR="$MK_WORKBASE/conf/$VM_NAME/"
vmcfg="$VM_CFG_DIR/$VM_NAME.conf"

manual=""

rdpgo="0"
sshgo="0"
vnc="0"
stop=""

for aaa in $@
do
	if [ "$aaa" = "vnc" ]
	then
		vnc="1"
	fi
	if [ "$aaa" = "rdp" ]
	then
		rdpgo="1"
	fi
	if [ "$aaa" = "ssh" ]
	then
		sshgo="1"
	fi
	if [ "$aaa" = "stop" ]
	then
		stop="stop"
	fi
	if [ "$aaa" = "manual" ]
	then
		manual="manual"
	fi
done

if [ ! -d "$VM_DIR" ]
then
	mkdir -p $VM_DIR || exit 1
fi

if [ ! -d "$VM_CFG_DIR" ]
then
	mkdir -p $VM_CFG_DIR || exit 1
fi

cd $VM_DIR

if [ ! -f "$vmcfg" ]
then
	pecho ""
	pecho "vm config $vmcfg not found."
	pecho "using default configure"
	pecho ""
fi

	# default value
	export VM_VNC_BIND="127.0.0.1"
	export VM_VNC_WIDTH="1024"
	export VM_VNC_HIGH="768"
	export VM_CPUS=0
	export VM_MEM=2G
	export VM_VNC_PORT=""
	
	export VM_NIC_TYPE="virtio-net"
	#export VM_NIC_TYPE="e1000"
	
	export VM_HD_TYPE="ahci-hd"
	#export VM_HD_TYPE="virtio-blk"
	export VM_CD_TYPE="ahci-cd"
	
	# export VM_PCI_HD_NUM="5:"
	# export VM_PCI_NIC_NUM="6:"
	
	export VM_PCI_HD_NUM=""
	export VM_PCI_NIC_NUM=""
	
	# export VM_VNC_WAIT=",wait"
	export VM_VNC_WAIT=""
	
	# export VM_VNC_FULLSCREEN=" -fullscreen"
	export VM_VNC_FULLSCREEN=""

	export VM_VNC_BASE="vncviewer -RemoteResize -DesktopSize=${VM_VNC_WIDTH}x${VM_VNC_HIGH}$VM_VNC_FULLSCREEN"

	export VM_RDP_WH="1920x1050"
	export VM_RDP_WH="1280x768"
	export VM_RDP_USER="guest"
	export VM_RDP_PASSWORD="nopass"

	export VM_CONSOLE_IP_NUM=""
	export VM_CONSOLE_BR="bridge8192"
	export VM_CONSOLE_BR_IP_NET="172.16.254"
	export VM_CONSOLE_BR_IP_NUM="254"

vmvar=`cat $vmcfg 2>/dev/null| grep '^VM_' | grep '=' | grep -v ';'`
eval $vmvar

if [ "$viewer" = "1" ]
then
	# NOTE: using tigervnc
	test -z "$VM_VNC_PORT" && export VM_VNC_PORT=`cat $VM_CFG_DIR/vnc.port 2>/dev/null | head -n 1`
	if [ -z "$VM_VNC_PORT" ]
	then
		eecho "can not run -viewer, VM_VNC_PORT not defined"
		exit 1
	fi
	if [ -z "$VM_NAME" ]
	then
		eecho "can not run -viewer, VM_NAME not defined"
		exit 1
	fi
	if [ "$vnc" = "1" ]
	then
		runvnc 5 $manual &

		sleep 1

		pecho ""

		exit $?
	fi
	
	if [ "$sshgo" = "1" ]
	then
		runssh 5 $manual &

		sleep 1

		pecho ""

		exit $?
	fi

	if [ "$rdpgo" = "1" ]
	then
		runrdp 5 $manual &

		sleep 1

		pecho ""

		exit $?
	fi
	usage
	exit 0
fi


#
hwncpu="$(sysctl -n hw.ncpu)"
test -z "$hwncpu" && hwncpu=1 && eecho "read hw.ncpu failed."
maxcpu=0
let maxcpu=$hwncpu-1 >/dev/null
test $VM_CPUS -le 0 && VM_CPUS=$hwncpu

if [ $VM_CPUS -gt $hwncpu ]
then
    VM_CPUS=$hwncpu
fi

vmvar=`set | grep '^VM_' | grep '=' | grep -v ';'`
if [ `id -u` -ne 0 ]
then
	pecho "sudo ..."
    sudo $MK_SCRIPT $MK_OPTS
	exit $?
fi

if [ -n "$SUDO_USER" ]
then
	# chown -R $SUDO_USER:$SUDO_USER $MK_WORKBASE || exit 1
	:
fi

if [ "$stop" = "stop" ]
then

	bhyvectl --destroy --vm=vm$VM_NAME >/dev/null >&1
	sleep 1

	isvmrun $VM_NAME && eecho "stop $VM_NAME failed."

	pecho "clean up tap device ..."
	for item in `ls -A $VM_CFG_DIR/*.mac 2>/dev/null| sort`
	do
		tcnt=`cat ${item}.tap 2>/dev/null`
		if [ -n "$tcnt" ]
		then
			brname=`cat ${item}.bridge 2>/dev/null|head -n1`
			if [ -n "$brname" ]
			then
				ifconfig $brname >/dev/null 2>&1
				if [ $? -eq 0 ]
				then
					ifconfig $brname 2>/dev/null | grep -q "member: tap$tcnt "
					if [ $? -eq 0 ]
					then
						ifconfig $brname deletem tap$tcnt || exit 1
					fi
				fi
			fi
			ifconfig tap$tcnt >/dev/null 2>&1 && \
			ifconfig tap$tcnt destroy >/dev/null 2>&1
		fi
	done
	pecho "stopped"
	exit 0
fi
#

pecho ""
pecho "NOTE: bhyve UEFI bootloader can not boot from GPT"
pecho ""
pecho "config:"
pecho ""
echo "$vmvar"
pecho ""


VM_VNC_PORT=5900
for item in `seq 0 20`
do
	sockstat -l -4 | grep -- ":${VM_VNC_PORT}" | grep -q '*:*'
	test $? -ne 0 && break
	let VM_VNC_PORT=$VM_VNC_PORT+1 >/dev/null
done
if [ "$VM_VNC_PORT" = "5921" ]
then
	eecho "all vnc port unaviable"
	exit 1
fi

pecho ""
pecho "Running with $VM_CPUS CPU(s)."
pecho ""

# WARNING: do not use -l com1,stdio and & to run bhyve in background, will block networking
# NOTE: remove -s 31,lpc will crash with: 
vmcmd="bhyve -A -H -s 0,hostbridge -s 29,fbuf,tcp=${VM_VNC_BIND}:${VM_VNC_PORT},w=$VM_VNC_WIDTH,h=${VM_VNC_HIGH}$VM_VNC_WAIT -s 31,lpc"
vmcmd="$vmcmd -m $VM_MEM"
vmcmd="$vmcmd -c $VM_CPUS"
vmcmd="$vmcmd -l bootrom,/usr/local/share/uefi-firmware/BHYVE_UEFI.fd"

isvmrun $VM_NAME && eecho "$VM_NAME is running." && exit 1

# for bootcd
ahcicnt=4
for item in `find $VM_DIR/ -depth 1 -type f | sort`
do
	echo "$item" | grep -q '.iso$'
	if [ $? -eq 0 ]
	then
		vmcmd="$vmcmd -s ${VM_PCI_HD_NUM}${ahcicnt},${VM_CD_TYPE},$item"
		let ahcicnt=$ahcicnt+1 >/dev/null
		continue
	fi
	echo "$item" | grep -q '.disk$'
	if [ $? -eq 0 ]
	then
		vmcmd="$vmcmd -s ${VM_PCI_HD_NUM}${ahcicnt},${VM_HD_TYPE},$item"
		let ahcicnt=$ahcicnt+1 >/dev/null
		continue
	fi
	echo "$item" | grep -q '.device$'
	if [ $? -eq 0 ]
	then
		rawdev=`cat $item 2>/dev/null| head -n1`
		test -z "$rawdev" && continue
		test ! -f $rawdev -a ! -c $rawdev && pecho "WARNING: RAW device $rawdev($item) not found" && continue
		vmcmd="$vmcmd -s ${VM_PCI_HD_NUM}${ahcicnt},${VM_HD_TYPE},$rawdev"
		let ahcicnt=$ahcicnt+1 >/dev/null
		continue
	fi
done

VM_CONSOLE_BR_IP="${VM_CONSOLE_BR_IP_NET}.${VM_CONSOLE_BR_IP_NUM}"

ifconfig $VM_CONSOLE_BR >/dev/null 2>&1

if [ $? -ne  0 ]
then
	ifconfig $VM_CONSOLE_BR create up || exit 1
	ifconfig $VM_CONSOLE_BR inet $VM_CONSOLE_BR_IP/24 || exit 1
else
	brip=`ifconfig $VM_CONSOLE_BR | grep 'inet ' | awk '{print $2}'`
	brmask=`ifconfig $VM_CONSOLE_BR | grep 'inet ' | awk '{print $4}'`
	if [ "$brip" != "$VM_CONSOLE_BR_IP" -o "$brmask" != "0xffffff00" ]
	then
		pecho ""
		eecho "internal bridge $VM_CONSOLE_BR ip configure mismatch"
		pecho "NEED: $VM_CONSOLE_BR_IP 0xffffff00"
		pecho "GOT: $brip $brmask"
		pecho ""
		exit 1
	fi
fi
ping -t 1 -c 1 $VM_CONSOLE_BR_IP >/dev/null 2>&1
test $? -ne 0 && eecho "CONSOLE BRIDGE SETUP FAILED" && exit 1

if [ -n "${VM_PCI_HD_NUM}" ]
then
	ahcicnt=0
fi

test ! -f $VM_CFG_DIR/zz-console.mac && touch $VM_CFG_DIR/zz-console.mac

test ! -f $VM_CFG_DIR/zz-console.mac && exit 1

allnic="`ls -A $VM_CFG_DIR/*.mac 2>/dev/null| sort|uniq`"

for item in $allnic
do
	tcnt=`cat ${item}.tap 2>/dev/null`
	if [ -n "$tcnt" ]
	then
		ifconfig tap$tcnt >/dev/null 2>&1
		# already exist
		test $? -eq 0 && tcnt=""
	fi
	if [ -z "$tcnt" ]
	then
		tapcnt=20
		for item2 in `seq 0 20`
		do
			ifconfig tap$tapcnt 2>/dev/null
			if [ $? -ne 0 ]
			then
				tcnt=$tapcnt
				break
			fi
			let tapcnt=$tapcnt+1 >/dev/null
		done
		test -z "$tcnt" && eecho "all tap[20-40] unaviable" && exit 1
	fi
	echo "$tcnt" > ${item}.tap
	
	vmcmd="$vmcmd -s ${VM_PCI_NIC_NUM}${ahcicnt},${VM_NIC_TYPE},tap$tcnt"
	let ahcicnt=$ahcicnt+1 >/dev/null

	ifconfig tap$tcnt >/dev/null 2>&1
	if [ $? -ne 0 ]
	then
		ifconfig tap$tcnt create || exit 1
	fi
	mac=`ifconfig tap$tcnt | grep 'ether ' | awk '{print $2}'`
	echo "$mac" > $item
	brname=`cat ${item}.bridge 2>/dev/null|head -n1`
	if [ -z "$brname" -a "`basename $item`" = "zz-console.mac" ]
	then
		brname=$VM_CONSOLE_BR
		echo "$brname" > ${item}.bridge
	fi
	if [ -n "$brname" ]
	then
		ifconfig $brname >/dev/null 2>&1
		if [ $? -ne 0 ]
		then
			# create 
			ifconfig $brname create || exit 1
		fi
		ifconfig $brname up || exit 1
		ifconfig $brname addm tap$tcnt || exit 1
		# ifconfig $brname 
	fi
	ifconfig tap$tcnt up || exit 1
	# ifconfig tap$tcnt 
done
# TODO: use serial console
#-s 30,xhci,tablet \
#-l com1,stdio \
#-l com1,/dev/nmdm0A \

export VM_CONSOLE_IP=`cat $VM_CFG_DIR/console.ip 2>/dev/null| head -n1`

if [ -z "$VM_CONSOLE_IP" ]
then
	pecho "probe aviable console ip ..."
	for item in `seq 1 20`
	do
		echo -n "$item "
		VM_CONSOLE_IP=${VM_CONSOLE_BR_IP_NET}.${item}
		ping -t 1 -c 1 $VM_CONSOLE_IP >/dev/null 2>&1
		test $? -ne 0 && echo "" && VM_CONSOLE_IP_NUM=$item && break
		VM_CONSOLE_IP=''
	done
	if [ -z "$VM_CONSOLE_IP" ]
	then
		echo "failed"
		exit 1
	else
		echo ""
	fi
	ping -t 1 -c 1 $VM_CONSOLE_IP >/dev/null 2>&1
	if [ $? -eq 0 ]
	then
		pecho "CONSOLE IP $VM_CONSOLE_IP ALIVE"
	else
		pecho "AVIABLE CONSOLE IP: $VM_CONSOLE_IP"
	fi
else
	ping -t 1 -c 1 $VM_CONSOLE_IP >/dev/null 2>&1
	if [ $? -eq 0 ]
	then
		pecho "PREVIOUS CONSOLE IP $VM_CONSOLE_IP ALIVE"
	else
		pecho "PREVIOUS CONSOLE IP $VM_CONSOLE_IP UNREACHABLE"
	fi
fi
pecho ""
pecho "CONSOLE GATEWAY: $VM_CONSOLE_BR_IP"
pecho ""

echo "$VM_CONSOLE_IP" > $VM_CFG_DIR/console.ip || exit 1

ncpu=$hwncpu
let ncpu=$hwncpu-$VM_CPUS >/dev/null

# -l 0-0 is ok
vcpuno=0
for item in `seq $ncpu $maxcpu`
do
	vmcmd="$vmcmd -p $vcpuno:$item"
	let vcpuno=$vcpuno+1 >/dev/null
done

# vmcmd="cpuset -l $ncpu-$maxcpu $vmcmd vm$VM_NAME"
vmcmd="$vmcmd vm$VM_NAME"

sysctl -w net.link.tap.user_open=1 >/dev/null
sysctl -w net.link.tap.up_on_open=1 >/dev/null

kldload vmm 2>/dev/null
# kldload nmdm 2>/dev/null

echo "$VM_VNC_PORT" > $VM_CFG_DIR/vnc.port

runit &

sleep 1

pecho ""

if [ "$vnc" = "1" ]
then
	$MK_SCRIPT $xtrace -viewer $VM_NAME vnc 5 &
else
	$MK_SCRIPT $xtrace -viewer $VM_NAME vnc manual &
fi

pecho ""

if [ "$rdpgo" = "1" ]
then
	$MK_SCRIPT $xtrace -viewer $VM_NAME rdpgo 5 &
else
	$MK_SCRIPT $xtrace -viewer $VM_NAME rdpgo 5 manual &
fi

pecho ""

if [ "$sshgo" = "1" ]
then
	$MK_SCRIPT $xtrace -viewer $VM_NAME sshgo 5 &
else
	$MK_SCRIPT $xtrace -viewer $VM_NAME sshgo 5 manual &
fi

pecho ""

exit $?

