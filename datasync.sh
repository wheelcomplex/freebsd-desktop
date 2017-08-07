#!/bin/bash

if [ `id -u` -ne 0 ]
then
	echo "sudo ..."
    sudo $0 $@
    exit $?
fi

REMOTES="172.16.0.1,172.16.0.3,172.16.0.5,172.16.0.254"

# NTE: DO NOT SYNC tank/davidrootfs  
SRCLIST='
tank/aarch64rootfs
tank/cross        
tank/davidds      
tank/davidhome    
tank/davidvm      
'
REMOTES="$(echo $REMOTES|tr ',' ' ')"
tmplist=''
for onehost in $REMOTES
do
	netstat -nr | grep 'link#' | grep -q "^${onehost}"
	if [ $? -eq 0 ]
	then
		echo "local ip, skipped: $onehost" && continue
	fi
	tmplist="$tmplist $onehost"
done
REMOTES=$tmplist

errcnt=0
for SRC in $SRCLIST
do
	for onehost in $REMOTES
	do
		echo "info: sync $SRC to $onehost($SRC) ..."
	    ping -t 2 -c 2 $onehost >/dev/null
	    if [ $? -ne 0 ]
	    then
	        echo "error: ping $onehost failed."
			let errcnt=$errcnt+1 >/dev/null
	        continue
	    fi
		backupzfs.sh $SRC ${onehost}@$SRC
	    if [ $? -ne 0 ]
	    then
	        echo "error: send to $onehost failed."
			let errcnt=$errcnt+1 >/dev/null
	        continue
	    fi
	done
done
exit $errcnt
#
