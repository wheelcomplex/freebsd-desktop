#!/bin/bash

if [ `id -u` -ne 0 ]
then
	echo "sudo ..."
    sudo $0 $@
    exit $?
fi

REMOTES="172.16.0.1,172.16.0.3,172.16.0.5,172.16.0.254"

SRC="tank"
DST="ztank/davidbk"

REMOTES="$(echo $REMOTES|tr ',' ' ')"
errcnt=0
for onehost in $REMOTES
do
	netstat -nr | grep 'link#' | grep -q "^${onehost}"
	if [ $? -eq 0 ]
	then
		echo "local ip, skipped: $onehost" && continue
	fi
		echo "info: sync $SRC to $onehost($DST) ..."
        ping -t 2 -c 2 $onehost >/dev/null
        if [ $? -ne 0 ]
        then
            echo "error: ping $onehost failed."
			let errcnt=$errcnt+1 >/dev/null
            continue
        fi
		backupzfs.sh $SRC ${onehost}@$DST
        if [ $? -ne 0 ]
        then
            echo "error: send to $onehost failed."
			let errcnt=$errcnt+1 >/dev/null
            continue
        fi
done
exit $errcnt
#
