#!/bin/bash

if [ `id -u` -ne 0 ]
then
	echo "sudo ..."
    sudo $0 $@
    exit $?
fi

REMOTES="172.16.0.1,172.16.0.3"

test -z "$ZBAK_DELAY_EXPORT_FILE" && export ZBAK_DELAY_EXPORT_FILE=${HOME}/.zbackup.delay.export.list && cat /dev/null > $ZBAK_DELAY_EXPORT_FILE

export xtrace=""
export utag=""
export shut=""
needval=''
for aaa in $@
do
	if [ "$needval" = "-t" ]
	then
		echo "$aaa" | grep -q '^-' && echo "invalid switch: $aaa" && usage
		utag="$aaa"
		needval=''
		continue
	fi
    if [ "$aaa" = "-t" ]
    then
        needval="$aaa"
        continue
    fi
    if [ "$aaa" = "-R" ]
    then
        shut="$aaa"
		echo ""
		echo "WARNING: will reboot after backup"
		echo ""
        continue
    fi
    if [ "$aaa" = "-S" ]
    then
        shut="$aaa"
		echo ""
		echo "WARNING: will shutdown after backup"
		echo ""
        continue
    fi
    if [ "$aaa" = "-x" ]
    then
        set -x
        xtrace="-x"
        continue
    fi
    echo "$aaa" | grep -q '^-' && echo "unknow switch: $aaa" && continue
    echo "Too many parameters: $aaa"
done

export MK_TAG

if [ -z "$MK_TAG" ]
then
	MK_TAG=`date +%Y%m%d%H%M%S`
	test -n "$utag" && MK_TAG="${MK_TAG}-$utag"
fi

echo ""
echo "ZBACKUP TAG: $MK_TAG"
echo ""

# default to backup
TANK="ztank"

# sync to live system
test "$1" = "-sync" && TANK="tank" && shift

HOSTNAME=`hostname -s`

LOCALROOTFS=`mount|grep " on / " | tail -n1 | awk '{print $1}'`
test -z "$LOCALROOTFS" && echo "error: local rootfs not found" && exit 1

zfs list tank/$HOSTNAME >/dev/null 2>&1
test $? -ne 0 && echo "local dataset tank/$HOSTNAME not found." && exit 1

SRCLIST=''

srcbase="tank/$HOSTNAME"
tlen=${#srcbase}
for oneds in `zfs list -H -o name -r tank/$HOSTNAME`
do
	if [ "$TANK" = "tank" -a "$oneds" = "$LOCALROOTFS" ]
	then
		echo "local rootfs $LOCALROOTFS skipped for $TANK"
		continue
	fi
	suffix=${oneds:${tlen}};
	SRCLIST="$SRCLIST $suffix"
done

REMOTES="$(echo $REMOTES|tr ',' ' ')"
tmplist=''
localip=''
for onehost in $REMOTES
do
	netstat -nr | grep 'link#' | grep -q "^${onehost}"
	if [ $? -eq 0 ]
	then
		localip="$onehost"
		if [ "$TANK" = "tank" ]
		then
			echo "local ip, skipped: $onehost" && continue
		fi
	fi
	tmplist="$tmplist $onehost"
done
REMOTES=$tmplist

if [ "$TANK" = "tank" ]
then
	echo ""
	echo "sync$SRCLIST to $TANK($REMOTES) ..."
	echo ""
else
	echo ""
	echo "backup$SRCLIST to $TANK($REMOTES) ..."
	echo ""
fi

stopbgtail(){
	kill `ps axuww| grep "$tailcmd" | grep -v grep | awk '{print $2}'` 2>/dev/null
}

bgtail(){
	stopbgtail
    $tailcmd | grep 'estimated size'
}

logfile=/tmp/`basename $0`.log
echo "temp log to $logfile"

export tailcmd="tail -f $logfile"

errcnt=0
for onehost in $REMOTES
do
	ping -t 2 -c 2 $onehost >/dev/null
	if [ $? -ne 0 ]
	then
	    echo "error: ping $onehost failed."
		let errcnt=$errcnt+1 >/dev/null
	    continue
	fi
	if [ "$onehost" != "$localip" ]
	then
		RHOSTNAME="`ssh $onehost hostname -s`"
		REMOTEROOTFS=`ssh $onehost mount|grep " on / " | tail -n1 | awk '{print $1}'`
		test -z "$REMOTEROOTFS" && echo "error: remote $onehost rootfs not found" && exit 1
	fi

	for dsname in $SRCLIST
	do
		SRC="tank/${HOSTNAME}$dsname"

		touch $logfile && bgtail $logfile &

		if [ "$onehost" != "$localip" ]
		then
			if [ "$TANK" = "tank" ]
			then
				# sync to live system, use remote hostname
				DST="$TANK/${RHOSTNAME}$dsname"
			else
				# sync to backup, use local hostname
				DST="$TANK/${HOSTNAME}$dsname"
			fi

			test "$DST" = "$REMOTEROOTFS" && echo "error: can not sync to remote $onehost rootfs $REMOTEROOTFS" && continue

			echo "info: sync $SRC to $onehost($DST) ..."

			backupzfs.sh -v $SRC ${onehost}@$DST > $logfile 2>&1
	    	if [ $? -ne 0 ]
	    	then
	    	    echo "error: send to $onehost failed."
				cat $logfile
				let errcnt=$errcnt+1 >/dev/null

				stopbgtail

	    	    continue
	    	fi
			stopbgtail
		else
			# local backup
			if [ "$TANK" = "tank" ]
			then
				# sync to live system, use remote hostname
				echo "error: can not sync to local live system $onehost" && continue
			else
				# sync to backup, use local hostname
				DST="$TANK/${HOSTNAME}$dsname"
			fi
			echo "info: sync $SRC to local $onehost($DST) ..."

			backupzfs.sh -v $SRC $DST > $logfile 2>&1
	    	if [ $? -ne 0 ]
	    	then
	    	    echo "error: send to $onehost failed."
				cat $logfile
				let errcnt=$errcnt+1 >/dev/null
				stopbgtail
	    	    continue
	    	fi
			stopbgtail
		fi
	done
done
if [ -s "$ZBAK_DELAY_EXPORT_FILE" ]
then
	echo "exporting zfs pool from $ZBAK_DELAY_EXPORT_FILE ..."
	for oneline in `cat $ZBAK_DELAY_EXPORT_FILE | sort -r | uniq`
	do
		rhost=`echo $oneline| awk -F'@' '{print $1}'`
		poolname=`echo $oneline| awk -F'@' '{print $2}'`
		if [ -z "$poolname" ]
		then
			poolname="$oneline"
			rhost=""
		fi
		if [ -n "$rhost" ]
		then
			ssh $rhost zpool export -f $poolname
			if [ $? -eq 0 ]
			then
				echo "remote $rhost $poolname exported."
			else
				echo "error: remote $rhost $poolname export failed."
			fi
		else
			zpool export -f $poolname
			if [ $? -eq 0 ]
			then
				echo "local $poolname exported."
			else
				echo "error: local $poolname export failed."
			fi
		fi
	done
fi
if [ "$shut" = "-R" ]
then
	echo "reboot after backup ..."
	sleep 5
	for onehost in $REMOTES
	do
		netstat -nr | grep 'link#' | grep -q "^${onehost}"
		if [ $? -eq 0 ]
		then
			localip="$onehost"
			echo "local ip, reboot later: $onehost" && continue
		fi
		ping -t 2 -c 2 $onehost >/dev/null
		if [ $? -ne 0 ]
		then
		    echo "error: ping $onehost failed."
		    continue
		fi
		ssh $onehost init 6
	done
	sleep 5
	sudo init 6
	sleep 15
	echo "failed to reboot."
	exit 1
fi
if [ "$shut" = "-S" ]
then
	echo "shutdown after backup ..."
	sleep 5
	for onehost in $REMOTES
	do
		netstat -nr | grep 'link#' | grep -q "^${onehost}"
		if [ $? -eq 0 ]
		then
			localip="$onehost"
			echo "local ip, shutdown later: $onehost" && continue
		fi
		ssh $onehost init 0
		ping -t 2 -c 2 $onehost >/dev/null
		if [ $? -ne 0 ]
		then
		    echo "error: ping $onehost failed."
		    continue
		fi
	done
	sleep 5
	sudo init 0
	sleep 15
	echo "failed to shutdown."
	exit 1
fi
exit $errcnt
#
