#!/bin/bash

# https://wiki.freebsd.org/bhyve/UEFI

export MK_PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
export PATH="$MK_PATH"
export MK_SCRIPT="$0"
export MK_OPTS="$@"
export MK_WORKBASE="/vm"

export VM_IFCONFIG="ifconfig"
export VM_SUDO_IFCONFIG="sudo ifconfig"
export VM_SUDO_BHYVE="sudo bhyve"
export VM_SUDO_BHYVECTL="sudo bhyvectl"

# YES to enable debug
export PDEBUG=""

toupper(){
    local msg="$@"
    echo "${msg^^}"
}

tolower(){
    local msg="$@"
    echo "${msg,,}"
}

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
    pecho "$MK_SCRIPT [-x] [-novnc] [-viewer] <vm name> [stop] [vnc] [rdp] [ssh]"
    exit 1
}

stopvm(){

    $VM_SUDO_BHYVECTL --destroy --vm=vm$VM_NAME >/dev/null >&1
    sleep 1

	for aaa in `seq 0 5`
	do
		isvmrun $VM_NAME || break
		sleep 1
	done

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
                $VM_SUDO_IFCONFIG $brname >/dev/null 2>&1
                if [ $? -eq 0 ]
                then
                    $VM_SUDO_IFCONFIG $brname 2>/dev/null | grep -q "member: tap$tcnt "
                    if [ $? -eq 0 ]
                    then
                        $VM_SUDO_IFCONFIG $brname deletem tap$tcnt || exit 1
                    fi
                fi
            fi
            $VM_SUDO_IFCONFIG tap$tcnt >/dev/null 2>&1 && \
            $VM_SUDO_IFCONFIG tap$tcnt destroy >/dev/null 2>&1
        fi
    done
    pecho "stopped"
    exit 0
}

runvm(){

    pecho ""
    pecho "CMD: $VM_CMD"
    pecho ""

    cat /dev/null > $VM_DIR/bhyve.log.err
    
    for aaa in `seq 0 5`
    do
        $VM_CMD 2>&1 
        cat $VM_DIR/bhyve.log | grep -q 'vm_reinit'
        if [ $? -eq 0 ]
        then
            cat $VM_DIR/bhyve.log | grep -C 10 'vm_reinit' > $VM_DIR/bhyve.log.err
            cat /dev/null > $VM_DIR/bhyve.log
            pecho ""
            pecho "vm_reinit error, re-try $VM_NAME"
            pecho ""
            cat $VM_DIR/bhyve.log >> $VM_DIR/bhyve.log.err
        else
            break
        fi
        sleep 1
    done

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
    stopvm
    exit $?
}

update_console_ip(){
    test -z "$VM_CONSOLE_MAC" && VM_CONSOLE_MAC=`cat $VM_CFG_DIR/zz-console.hwaddr 2>/dev/null`
    if [ -z "$VM_CONSOLE_MAC" ]
    then
        eecho ""
        eecho "VM_CONSOLE_MAC NOT FOUND: $VM_CFG_DIR/zz-console.hwaddr"
        eecho ""
        return 1
    fi

    # got console ip from dnsmasq
    pecho "fetch console ip($VM_CONSOLE_MAC) from dnsmasq lease ..."
    VM_CONSOLE_IP=`cat /var/db/dnsmasq.leases | grep -i "${VM_CONSOLE_MAC}$"| awk '{print $3}'| head -n1`
    for item in `seq 0 90`
    do
        if [ -z "$VM_CONSOLE_IP" ]
        then
            sleep 1
            continue
        else
            break
        fi
        VM_CONSOLE_IP=`cat /var/db/dnsmasq.leases | grep -i "${VM_CONSOLE_MAC}$"| awk '{print $3}'| head -n1`
    done
    if [ -z "$VM_CONSOLE_IP" ]
    then
        eecho ""
        eecho "FETCH CONSOLE IP FAILED"
        eecho ""
        return 1
    fi
    pecho "waiting for console ip $VM_CONSOLE_IP($VM_CONSOLE_MAC) up ..."
    for aaa in `seq 0 30`
    do
        ping -t 1 -c 1 $VM_CONSOLE_IP >/dev/null 2>&1
        if [ $? -eq 0 ]
        then
            break
        fi
        sleep 1
    done
    ping -t 1 -c 1 $VM_CONSOLE_IP >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
        pecho "CONSOLE IP $VM_CONSOLE_IP ALIVE"
    else
        pecho "CONSOLE IP $VM_CONSOLE_IP UNREACHABLE"
    fi

    local presum=`md5 /etc/pf.rdr.conf`
    echo "$VM_CONSOLE_IP" > $VM_CFG_DIR/zz-console.ip || exit 1
    echo "workvm = \"$VM_CONSOLE_IP\"" > /etc/pf.rdr.conf || exit 1
    pecho ""
    pecho "CONSOLE IP $VM_CONSOLE_IP updated into /etc/pf.rdr.conf"
    pecho ""
    if [ "$presum" != "`md5 /etc/pf.rdr.conf`" ]
    then
        pfsess start
    fi
    return 0
}

runrdp(){
    export APPNAME=rdp
    trap 'handle_trap' INT QUIT HUP
    pecho "run $APPNAME, log to $VM_DIR/${APPNAME}.log"
    if [ "$2" = "manual" ]
    then
        bgrdp $@ 2>&1 | tee -i $VM_DIR/${APPNAME}.log 
        return $?
    else
        bgrdp $@ 2>&1 | tee -i $VM_DIR/${APPNAME}.log
        return $?
    fi
}

bgrdp(){
    local trycnt="$1"
    local manual="$2"
    test -z "$trycnt" -o "$trycnt" = "manual" && trycnt=3

    update_console_ip || return 1

    pecho ""
    pecho "RDP: user $VM_RDP_USER, screen $VM_RDP_WH, IP $VM_CONSOLE_IP"
    pecho ""
    # -x 0x80 for font smooth, 0x81 0x8f
    export VM_RDP_BASE="rdesktop -r sound:local -x 0x80 -a 32 -f -k en-us -D"
	# runvnc
    #export VM_RDP_VIEWER_CMD="$VM_RDP_BASE -T $VM_NAME -u $VM_RDP_USER -p $VM_RDP_PASSWORD -z -r clipboard:PRIMARYCLIPBOARD -g $VM_RDP_WH $VM_CONSOLE_IP"
    export VM_RDP_VIEWER_CMD="$VM_RDP_BASE -T $VM_NAME -u $VM_RDP_USER -p $VM_RDP_PASSWORD -z -r clipboard:PRIMARYCLIPBOARD $VM_CONSOLE_IP"
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
    ps axuww| grep -- "$VM_RDP_BASE" | grep -v grep | grep -- "-T $VM_NAME" | grep -- "-u $VM_RDP_USER -p $VM_RDP_PASSWORD" | grep -q -- "-g $VM_RDP_WH"
    if [ $? -eq 0 ]
    then
        eecho "rdesktop viewer already running."
        ps axuww | grep -- "-u $VM_RDP_USER -p $VM_RDP_PASSWORD" | grep -- "-T $VM_NAME" | grep -- "-g $VM_RDP_WH"
        sleep 5
        return 1
    fi
    for aaa in `seq 0 $trycnt`
    do
        echo -n '.'
        isvmrun $VM_NAME && pecho " $VM_NAME running ..." && break
        sleep 1
    done

    pecho ""
    pecho ""
    pecho ""
    pecho ""
    pecho "Verify console ip $VM_CONSOLE_IP ..."
    pecho ""
    for aaa in `seq 0 30`
    do
        echo -n '.'
        ping -t 1 -c 1 $VM_CONSOLE_IP >/dev/null 2>&1 && pecho " $VM_CONSOLE_IP alive ..." && break
        sleep 1
    done

    echo ""

    $VM_RDP_VIEWER_CMD 
    return $?
}

runssh(){
    local trycnt="$1"
    local manual="$2"
    test -z "$trycnt" -o "$trycnt" = "manual" && trycnt=3
}

runvnc(){
    export APPNAME=vnc
    pecho "run $APPNAME, log to $VM_DIR/${APPNAME}.log"
    if [ "$2" = "manual" ]
    then
        bgvnc $@ 2>&1 | tee -i $VM_DIR/${APPNAME}.log 
        return $?
    else
        bgvnc $@ 2>&1 | tee -i $VM_DIR/${APPNAME}.log
        return $?
    fi
}

bgvnc(){
    local trycnt="$1"
    local manual="$2"
    test -z "$trycnt" -o "$trycnt" = "manual" && trycnt=10

    trap 'handle_trap' INT QUIT HUP EXIT TERM
    # trap 'handle_trap' INT QUIT HUP

    # NOTE: using tigervnc
    VM_VNC_PORT=`cat $VM_CFG_DIR/zz-vnc.port 2>/dev/null | head -n 1`
    if [ -z "$VM_VNC_PORT" ]
    then
        eecho "can not run -viewer, VM_VNC_PORT not defined in $VM_CFG_DIR/zz-vnc.port"
        exit 1
    fi

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
        pecho ""
        eecho "vnc viewer already running."
        ps axuww| grep -- "$VM_VNC_VIEWER_CMD" | grep -v grep
        pecho ""
        sleep 10
        return 1
    fi
    for aaa in `seq 0 $trycnt`
    do
        sockstat -4 -l | grep ":$VM_VNC_PORT"
        sockstat -4 -l | grep -q ":$VM_VNC_PORT" && isvmrun $VM_NAME && break
        sleep 1
    done
    sockstat -4 -l | grep -q ":$VM_VNC_PORT" && isvmrun $VM_NAME
    if [ $? -ne 0 ]
    then
        eecho "vnc port $VM_VNC_PORT is not listening"
        sleep 10
        return 1
    fi
    $VM_VNC_VIEWER_CMD
    return $?
}
##
#     1       HUP (hang up)
#     2       INT (interrupt)
#     3       QUIT (quit)
#     6       ABRT (abort)
#     9       KILL (non-catchable, non-ignorable kill)
#     14      ALRM (alarm clock)
#     15      TERM (software termination signal)
##
handle_trap ( ) {
    #trap '' INT QUIT HUP EXIT 
    pecho "$APPNAME: signaled"
}

isvmrun(){
    # return 0 for running
    local VM_NAME="$1"
    test -z "$VM_NAME" && efecho "need vm name arg"&&exit 1
    ps axuww| grep bhyve | grep -v grep | grep -q "bhyve: vm$VM_NAME "
    return $?
}

vncstatus(){
    if [ -z "$VM_VNC_PORT" ]
    then
        VM_VNC_PORT=`cat $VM_CFG_DIR/zz-vnc.port 2>/dev/null | head -n 1`
    fi
    if [ -z "$VM_VNC_PORT" ]
    then
        eecho "VM_VNC_PORT not defined in $VM_CFG_DIR/zz-vnc.port"
        return 1
    fi
    for aaa in `seq 1 10`
    do
        ps axuww| grep -- "$VM_VNC_BASE" | grep -v grep | grep -q -- ":$VM_VNC_PORT"
        if [ $? -eq 0 ]
        then
            pecho ""
            pecho "vnc viewer started."
            ps axuww| grep -- "$VM_VNC_BASE" | grep -v grep | grep -- ":$VM_VNC_PORT"
            pecho ""
            sleep 5
            return 0
        fi
    done
    return 1
}

aftervm(){

    pecho ""

    if [ "$novnc" != "1" ]
    then
        # runvnc 5 
        nohup $MK_SCRIPT -viewer $VM_NAME vnc >>  $VM_DIR/bhyve.log 2>&1 &
    else
        pecho ""
        
        runvnc 5 manual 
    fi
    
    pecho ""

}

export xtrace=""
export viewer=0
export novnc=0
export manual=""
export rdpgo="0"
export sshgo="0"
export vncgo="0"
export dostop=""
export VM_NAME=""
export dovm="0"
for aaa in $@
do
    if [ "$aaa" = "-viewer" ]
    then
        viewer=1
        continue
    fi
    if [ "$aaa" = "-x" ]
    then
        set -x
        xtrace="-x"
        continue
    fi
    if [ "$aaa" = "-novnc" ]
    then
        novnc=1
        continue
    fi
    echo "$aaa" | grep -q '^-' && continue
    if [ "$aaa" = "vnc" ]
    then
        vncgo="1"
        continue
    fi
    if [ "$aaa" = "rdp" ]
    then
        rdpgo="1"
        continue
    fi
    if [ "$aaa" = "ssh" ]
    then
        sshgo="1"
        continue
    fi
    if [ "$aaa" = "stop" ]
    then
        dostop="stop"
        continue
    fi
    if [ "$aaa" = "manual" ]
    then
        manual="manual"
        continue
    fi
    if [ "$aaa" = "runvm" ]
    then
        dovm="1"
        continue
    fi
    test -z "$VM_NAME" && VM_NAME="$aaa" && pecho "VM NAME: $VM_NAME" 
done

if [ -z "$VM_NAME" ]
then
    usage
    exit 1
fi
shift


if [ "$dovm" = "1" ]
then
    if [ -z "$VM_CMD" ]
    then
        eecho "VM_CMD not defined"
        exit 1
    fi
    runvm
    exit $?
fi

export VM_DIR="$MK_WORKBASE/data/$VM_NAME/"
export VM_CFG_DIR="$MK_WORKBASE/conf/$VM_NAME/"
VM_CFG_FILE="$VM_CFG_DIR/vm.conf"

if [ ! -f "$VM_CFG_FILE" ]
then
    eecho ""
    eecho "vm config $VM_CFG_FILE not found."
    eecho ""
    exit 1
fi

if [ ! -d "$VM_DIR" ]
then
    mkdir -p $VM_DIR || exit 1
fi

cd $VM_DIR
# default value
export VM_VNC_BIND="127.0.0.1"
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

export VM_RDP_WH="1920x1050"
export VM_RDP_WH="1280x768"
export VM_RDP_USER="guest"
export VM_RDP_PASSWORD="nopass"

export VM_CONSOLE_IP_NUM=""
export VM_CONSOLE_BR="bridge8192"
export VM_CONSOLE_BR_IP_NET="172.16.254"
export VM_CONSOLE_BR_IP_NUM="254"

vmvar=`cat $VM_CFG_FILE 2>/dev/null| grep '^VM_' | grep '=' | grep -v ';'`
eval $vmvar

dispinfo=`sysctl -a | grep 'framebuffer' | grep 'fbcon size:'| awk -F'fbcon size: ' '{print $2}'|tr ',' ' '| awk '{print $1} {print $3}'`
VM_VNC_WIDTH=`echo $dispinfo | awk '{print $1}'`
VM_VNC_HIGH=`echo $dispinfo | awk '{print $2}'`
test -z "$VM_VNC_WIDTH" && VM_VNC_WIDTH=1280
test -z "$VM_VNC_HIGH" && VM_VNC_HIGH=720
if [ "$VM_VNC_WIDTH" -gt 1280 ]
then
	VM_VNC_WIDTH=1280
fi
if [ "$VM_VNC_HIGH" -gt 720 ]
then
	VM_VNC_HIGH=720
fi

pecho ""
pecho "VNC RESOLUTION: ${VM_VNC_WIDTH}x${VM_VNC_HIGH}"
pecho ""

# export VM_VNC_BASE="vncviewer -fullscreen -Shared -RemoteResize -DesktopSize=${VM_VNC_WIDTH}x${VM_VNC_HIGH}$VM_VNC_FULLSCREEN"
export VM_VNC_BASE="vncviewer -RemoteResize -DesktopSize=${VM_VNC_WIDTH}x${VM_VNC_HIGH}$VM_VNC_FULLSCREEN"

if [ -n "$VM_NAME" ]
then
	isvmrun $VM_NAME 
	if [ $? -eq 0 ]
	then
		pecho "bring up tap device for $VM_NAME ..."
		for item in `ls -A $VM_CFG_DIR/*.mac 2>/dev/null| sort`
		do
		    tcnt=`cat ${item}.tap 2>/dev/null`
		    if [ -n "$tcnt" ]
		    then
		        brname=`cat ${item}.bridge 2>/dev/null|head -n1`
		        if [ -n "$brname" ]
		        then
		            $VM_IFCONFIG $brname >/dev/null 2>&1
		            if [ $? -eq 0 ]
		            then
		                $VM_IFCONFIG $brname 2>/dev/null | grep -q "member: tap$tcnt "
		                if [ $? -ne 0 ]
		                then
		                    $VM_SUDO_IFCONFIG $brname addm tap$tcnt || exit 1
		                fi
		            fi
		        fi
		        $VM_IFCONFIG tap$tcnt 2>&1 | grep 'flags=' | grep -q 'UP'
				if [ $? -ne 0 ]
				then
					$VM_SUDO_IFCONFIG tap$tcnt up >/dev/null 2>&1 || exit 1
				fi
		    fi
		done
	fi
fi

if [ "$viewer" = "1" ]
then
    if [ -z "$VM_NAME" ]
    then
        eecho "can not run -viewer, VM_NAME not defined"
        exit 1
    fi
    if [ "$vncgo" = "1" ]
    then
        runvnc 5 $manual 

        sleep 1

        pecho ""

        exit $?
    fi
    
    if [ "$sshgo" = "1" ]
    then
        runssh 5 $manual 

        sleep 1

        pecho ""

        exit $?
    fi

    if [ "$rdpgo" = "1" ]
    then

        runrdp 5 $manual 

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

# enable tap

if [ "$viewer" != "1" -a "$dovm" != "1" -a "$dostop" != "stop" ]
then
    isvmrun $VM_NAME 
    if [ $? -eq 0 ]
    then
        pecho ""
        pecho "$VM_NAME is running."
        pecho ""
        aftervm 
        vncstatus
        sleep 5
        exit 0
    fi
fi

vmvar=`set | grep '^VM_' | grep '=' | grep -v ';'`
if [ `id -u` -ne 0 ]
then
    pecho ""
    pecho "sudo ..."
    pecho ""
    sudo true
fi

test -n "$USER" && sudo chown -R $USER:$USER $MK_WORKBASE

if [ "$dostop" = "stop" ]
then
    stopvm
fi
#

pecho ""
pecho "NOTE: bhyve UEFI bootloader can not boot from GPT"
pecho ""
#pecho "config:"
#pecho ""
#echo "$vmvar"
#pecho ""


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
# -S for pci passthrough
export VM_CMD="$VM_SUDO_BHYVE -A -H -s 0,hostbridge -s 29,fbuf,tcp=${VM_VNC_BIND}:${VM_VNC_PORT},w=$VM_VNC_WIDTH,h=${VM_VNC_HIGH}$VM_VNC_WAIT -s 31,lpc $VM_CMD_OPTS"
VM_CMD="$VM_CMD -m $VM_MEM"
VM_CMD="$VM_CMD -c $VM_CPUS"
VM_CMD="$VM_CMD -l bootrom,/usr/local/share/uefi-firmware/BHYVE_UEFI.fd"

# for bootcd
ahcicnt=4
for item in `find $VM_DIR/ -depth 1 \( -type f -o -type l \) | sort`
do
    echo "$item" | grep -q '.iso$'
    if [ $? -eq 0 ]
    then
        VM_CMD="$VM_CMD -s ${VM_PCI_HD_NUM}${ahcicnt},${VM_CD_TYPE},$item"
        let ahcicnt=$ahcicnt+1 >/dev/null
        continue
    fi
    echo "$item" | grep -q '.disk$'
    if [ $? -eq 0 ]
    then
        VM_CMD="$VM_CMD -s ${VM_PCI_HD_NUM}${ahcicnt},${VM_HD_TYPE},$item"
        let ahcicnt=$ahcicnt+1 >/dev/null
        continue
    fi
    echo "$item" | grep -q '.device$'
    if [ $? -eq 0 ]
    then
        rawdev=`cat $item 2>/dev/null| head -n1`
        test -z "$rawdev" && continue
        test ! -f $rawdev -a ! -c $rawdev && pecho "WARNING: RAW device $rawdev($item) not found" && continue
        VM_CMD="$VM_CMD -s ${VM_PCI_HD_NUM}${ahcicnt},${VM_HD_TYPE},$rawdev"
        let ahcicnt=$ahcicnt+1 >/dev/null
        continue
    fi
done

export VM_CONSOLE_BR_IP="${VM_CONSOLE_BR_IP_NET}.${VM_CONSOLE_BR_IP_NUM}"

$VM_SUDO_IFCONFIG $VM_CONSOLE_BR >/dev/null 2>&1

if [ $? -ne  0 ]
then
    $VM_SUDO_IFCONFIG $VM_CONSOLE_BR create up || exit 1
    $VM_SUDO_IFCONFIG $VM_CONSOLE_BR inet $VM_CONSOLE_BR_IP/24 || exit 1
else
    brip=`$VM_SUDO_IFCONFIG $VM_CONSOLE_BR | grep 'inet ' | awk '{print $2}'`
    brmask=`$VM_SUDO_IFCONFIG $VM_CONSOLE_BR | grep 'inet ' | awk '{print $4}'`
    if [ "$brip" != "$VM_CONSOLE_BR_IP" -o "$brmask" != "0xffffff00" ]
    then
        pecho ""
        eecho "internal bridge $VM_CONSOLE_BR ip configure mismatch"
        pecho "NEED: $VM_CONSOLE_BR_IP 0xffffff00"
        pecho "GOT: $brip $brmask"
        pecho ""
        $VM_SUDO_IFCONFIG $VM_CONSOLE_BR destroy 2>/dev/null
        sleep 1
        $VM_SUDO_IFCONFIG $VM_CONSOLE_BR create up || exit 1
        $VM_SUDO_IFCONFIG $VM_CONSOLE_BR inet $VM_CONSOLE_BR_IP/24 || exit 1
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

export VM_CONSOLE_MAC=""

allnic="`ls -A $VM_CFG_DIR/*.mac 2>/dev/null| sort|uniq`"

for item in $allnic
do
    tcnt=`cat ${item}.tap 2>/dev/null`
    if [ -n "$tcnt" ]
    then
        $VM_SUDO_IFCONFIG tap$tcnt >/dev/null 2>&1
        # already exist
        if [ $? -eq 0 ]
        then
            $VM_SUDO_IFCONFIG tap$tcnt | grep -q 'status: no carrier' 
            if [ $? -eq 0 ]
            then
                iecho "device tap$tcnt exited but in status: no carrier"
                $VM_SUDO_IFCONFIG tap$tcnt destroy || exit 1
            else
                preether=`cat ${item}.ether 2>/dev/null`
                curether=`$VM_SUDO_IFCONFIG tap$tcnt 2>/dev/null| grep 'ether ' | awk '{print $2}'`
                if [ "$preether" = "$curether" ]
                then
                    $VM_SUDO_IFCONFIG tap$tcnt destroy || exit 1
                    pecho "previous device tap$tcnt removed: $curether"
                else
                    iecho "device tap$tcnt exited but is not configured for $VM_NAME"
                    tcnt=""
                fi
            fi
        fi
    fi
    if [ -z "$tcnt" ]
    then
        tapcnt=20
        for item2 in `seq 0 20`
        do
            $VM_SUDO_IFCONFIG tap$tapcnt >/dev/null 2>&1
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
    isnewmac=0
    mac=`cat $item 2>/dev/null`
    if [ -z "$mac" ]
    then
        mac=`genmac`
        isnewmac=1
    fi
    if [ -z "$mac" ]
    then
        eecho "generate MAC address for tap$tcnt failed"
        stopvm
        exit 1
    fi
    mac="`tolower $mac`"
    echo "$mac" > $item || exit 1
    mac=`echo "$mac"|tr '-' ':'`
    if [ $isnewmac -eq 0 ]
    then
        pecho "OLD MAC address for tap$tcnt $mac"
    else
        pecho "NEW MAC address for tap$tcnt $mac"
    fi
    VM_CMD="$VM_CMD -s ${VM_PCI_NIC_NUM}${ahcicnt},${VM_NIC_TYPE},tap$tcnt,mac=$mac"
    #VM_CMD="$VM_CMD -s ${VM_PCI_NIC_NUM}${ahcicnt},${VM_NIC_TYPE},tap$tcnt"

    let ahcicnt=$ahcicnt+1 >/dev/null

    $VM_SUDO_IFCONFIG tap$tcnt >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
        $VM_SUDO_IFCONFIG tap$tcnt create || exit 1
    fi
    curether=`$VM_SUDO_IFCONFIG tap$tcnt 2>/dev/null| grep 'ether ' | awk '{print $2}'`
    echo "$curether" > ${item}.ether || exit 1

    brname=`cat ${item}.bridge 2>/dev/null|head -n1`
    if [ "`basename $item`" = "zz-console.mac" ]
    then
        brname=$VM_CONSOLE_BR
        echo "$brname" > ${item}.bridge
        VM_CONSOLE_MAC="$mac"
        pecho "CONSOLE MAC: $VM_CONSOLE_MAC"
        echo "$VM_CONSOLE_MAC" > $VM_CFG_DIR/zz-console.hwaddr || exit 1
    fi
    if [ -n "$brname" ]
    then
        $VM_SUDO_IFCONFIG $brname >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
            # create 
            $VM_SUDO_IFCONFIG $brname create || exit 1
        fi
        $VM_SUDO_IFCONFIG $brname up || exit 1
        $VM_SUDO_IFCONFIG $brname addm tap$tcnt || exit 1
        # $VM_SUDO_IFCONFIG $brname 
    fi
    $VM_SUDO_IFCONFIG tap$tcnt up || exit 1
    # $VM_SUDO_IFCONFIG tap$tcnt 
done
# TODO: use serial console
#-s 30,xhci,tablet \
#-l com1,stdio \
#-l com1,/dev/nmdm0A \

ncpu=$hwncpu
let ncpu=$hwncpu-$VM_CPUS >/dev/null

# -l 0-0 is ok
vcpuno=0
for item in `seq $ncpu $maxcpu`
do
    VM_CMD="$VM_CMD -p $vcpuno:$item"
    let vcpuno=$vcpuno+1 >/dev/null
done

# VM_CMD="cpuset -l $ncpu-$maxcpu $VM_CMD vm$VM_NAME"
VM_CMD="$VM_CMD vm$VM_NAME"

if [ "`sysctl -n net.link.tap.user_open`" != "1" ]
then
	sudo sysctl -w net.link.tap.user_open=1 >/dev/null
fi
if [ "`sysctl -n net.link.tap.up_on_open`" != "1" ]
then
	sudo sysctl -w net.link.tap.up_on_open=1 >/dev/null
fi

sudo kldload vmm 2>/dev/null
# sudo kldload nmdm 2>/dev/null

echo "$VM_VNC_PORT" > $VM_CFG_DIR/zz-vnc.port

sudo true || exit 1

nohup sudo -E $MK_SCRIPT $xtrace $VM_NAME runvm > $VM_DIR/bhyve.log 2>&1 &

pecho ""
pecho "starting for $VM_NAME ..."
pecho ""
for aaa in `seq 1 10`
do
    pecho "."
    isvmrun $VM_NAME && iecho "$VM_NAME started." && break
    if [ -s "$VM_DIR/bhyve.log" ]
    then
        tail -n 20 $VM_DIR/bhyve.log
    fi
    sleep 1
done
isvmrun $VM_NAME 
if [ $? -ne 0 ]
then
    eecho "$VM_NAME failed to start." 
    cat $VM_DIR/bhyve.log.err
    exit 1
fi

vncstatus

$MK_SCRIPT $xtrace -viewer $VM_NAME vnc &

update_console_ip

nohup $MK_SCRIPT $xtrace -viewer $VM_NAME rdp > $VM_DIR/rdp.log 2>&1 &

exit 0

