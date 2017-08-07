#!/bin/bash

# https://wiki.freebsd.org/bhyve/UEFI

export MK_PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
export PATH="$MK_PATH"
export MK_SCRIPT="$0"
export MK_OPTS="$@"

# YES to enable debug
export PDEBUG=""

tolower(){
    local msg="$@"
    echo "${msg^^}"
}

tolower(){
    local msg="$@"
    echo "${msg,,}"
}

item_uniq_r(){
	local all="$@"
	local aaa=''
	for aaa in $all
	do
		echo "$aaa"
	done | sort -r | uniq
}

item_uniq(){
	local all="$@"
	local aaa=''
	for aaa in $all
	do
		echo "$aaa"
	done | sort | uniq
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

wecho(){
        pecho "WARNING: $@"
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
    pecho "$MK_SCRIPT [-x] [-t tag] <[host@]src dataset> <[host@]dst dataset>"
    exit 1
}

export xtrace=""
export nodedup="0"
export utag=""
export SRCHOST=""
export SRCDS=""
export SRCTR=""
export SRCSSH=""
export DSTHOST=""
export DSTDS=""
export DSTTR=""
export DSTSSH=""
needval=''
for aaa in $@
do
	if [ "$needval" = "-t" ]
	then
		echo "$aaa" | grep -q '^-' && eecho "invalid switch: $aaa" && usage
		utag="$aaa"
		needval=''
		continue
	fi
    if [ "$aaa" = "-t" ]
    then
        needval="$aaa"
        continue
    fi
    if [ "$aaa" = "-dup" ]
    then
        nodedup="1"
        continue
    fi
    if [ "$aaa" = "-x" ]
    then
        set -x
        xtrace="-x"
        continue
    fi
    echo "$aaa" | grep -q '^-' && eecho "unknow switch: $aaa" && continue
	echo "$aaa" | grep -q '@'
	if [ $? -eq 0 ]
	then
		onehost=`echo $aaa|awk -F'@' '{print $1}'`
		oneds=`echo $aaa|awk -F'@' '{print $2}'`
		onetr="@"
		onessh="ssh $onehost "
		test -z "$onehost" -o -z "$oneds" && eecho "invalid dataset parameter: $aaa" && usage
	else
		onehost=""
		oneds="$aaa"
		onetr=""
		onessh=""
	fi
	if [ -z "$SRCDS" ]
	then
		SRCDS=$oneds
		SRCHOST=$onehost
		SRCTR=$onetr
		SRCSSH=$onessh
		continue
	fi
	if [ -z "$DSTDS" ]
	then
		DSTDS=$oneds
		DSTHOST=$onehost
		DSTTR=$onetr
		DSTSSH=$onessh
		continue
	fi
	eecho "Too many parameters: $aaa"
done

if [ -z "$SRCDS" -o -z "$DSTDS" ]
then
	eecho "too few parameters: $@"
	usage
fi

if [ `id -u` -ne 0 ]
then
    pecho ""
    pecho "sudo ..."
    pecho ""
    sudo $MK_SCRIPT $MK_OPTS
	exit $?
fi

export MK_TAG

if [ -z "$MK_TAG" ]
then
	MK_TAG=`date +%Y%m%d%H%M%S`
	test -n "$utag" && MK_TAG="${MK_TAG}-$utag"
fi

SRCINFO=${SRCHOST}${SRCTR}${SRCDS}
DSTINFO=${DSTHOST}${DSTTR}${DSTDS}

pecho "zfs sync tag $MK_TAG from $SRCINFO => $DSTINFO ..."

sc(){
	local msg="$@"
	${SRCSSH}${msg}
	return $?
}

dc(){
	local msg="$@"
	${DSTSSH}${msg}
	return $?
}

ss(){
	sc zfs $@
	return $?
}

ds(){
	dc zfs $@
	return $?
}


ss(){
	sc zfs $@
	return $?
}

pecho "source information ..."

ss list $SRCDS >/dev/null 2>&1
if [ $? -ne 0 ]
then
	eecho "$SRCDS no exist"
	exit 1
fi
ss list -t snapshot -H -o name -r $SRCDS | sort > /tmp/zfs.src.${MK_TAG}.sn.list || exit 1

srcdslist=''

# NOTE: does not sync base SRCDS 

cat /dev/null > /tmp/zfs.src.${MK_TAG}.suffix.list
dslen=${#SRCDS}
for onesn in `cat /tmp/zfs.src.${MK_TAG}.sn.list`
do
	suffix=${onesn:${dslen}};
	dsname="`echo $suffix | awk -F'@' '{print $1}'`"
	dsmark="`echo $dsname | tr '/' '_'`"
	echo "$suffix" >> /tmp/zfs.src.${MK_TAG}.suffix-$dsmark-ds.list
	srcdslist="$srcdslist $dsname"
done

pecho "dest information ..."

ds list $DSTDS >/dev/null 2>&1
if [ $? -ne 0 ]
then
	pecho "$SRCDS no exist, create it ..."
	ds create $DSTDS || exit 1
	pecho "$DSTDS created."
fi

ds list $DSTDS >/dev/null 2>&1
if [ $? -ne 0 ]
then
	eecho "create $DSTDS failed"
	exit 1
fi

ds list -t snapshot -H -o name -r $DSTDS | sort > /tmp/zfs.dst.${MK_TAG}.sn.list || exit 1

cat /dev/null > /tmp/zfs.dst.${MK_TAG}.suffix.list
dslen=${#DSTDS}
for onesn in `cat /tmp/zfs.dst.${MK_TAG}.sn.list`
do
	suffix=${onesn:${dslen}};
	dsname="`echo $suffix | awk -F'@' '{print $1}'`"
	dsmark="`echo $dsname | tr '/' '_'`"
	echo "$suffix" >> /tmp/zfs.dst.${MK_TAG}.suffix-$dsmark-ds.list
done

ss snapshot -r ${SRCDS}@${MK_TAG} | exit 1

pecho "matching and sync ..."

srcdslist=`item_uniq $srcdslist`

dup="-D "
if [ $nodedup -eq 1 ]
then
	dup=""
fi

for dsname in $srcdslist
do
	pecho "sync $oneds($SRCDS) ..."
	dsmark="`echo $dsname | tr '/' '_'`"
	matchfx=""
	lastfx=''
	if [ -s "/tmp/zfs.dst.${MK_TAG}.suffix-$dsmark-ds.list" ]
	then
		while read srcfx
		do
			lastfx=$srcfx
			while read dstfx
			do
				if [ "$srcfx" = "$dstfx" ]
				then
					matchfx=$dstfx
					# do not break, find the last match
				fi
			done < /tmp/zfs.dst.${MK_TAG}.suffix-$dsmark-ds.list
			#
		done < /tmp/zfs.src.${MK_TAG}.suffix-$dsmark-ds.list
	fi
	if [ -z "$matchfx" -o -z "$lastfx" ]
	then
		wecho "snapshots mismatch, send ${SRCDS}${dsname}@${MK_TAG} to ${DSTDS}$dsname in $DSTINFO ..."
		ss send $dup-v ${SRCDS}${dsname}@${MK_TAG} | ds recv -F ${DSTDS}$dsname
		if [ $? -ne 0 ]
		then
			eecho "send ${SRCDS}${dsname}@${MK_TAG} to ${DSTDS}$dsname in $DSTINFO failed, re-try ..."
			ds list ${DSTDS}$dsname >/dev/null 2>&1
			if [ $? -eq 0 ]
			then
				ds destroy -rf ${DSTDS}$dsname || exit 1
			fi
			ss send $dup-v ${SRCDS}${dsname}@${MK_TAG} | ds recv -F ${DSTDS}$dsname
			if [ $? -ne 0 ]
			then
				eecho "re-try send ${SRCDS}${dsname}@${MK_TAG} to ${DSTDS}$dsname in $DSTINFO failed."
				exit 1
			fi
		fi
	else
		pecho "sync $SRCINFO($matchfx - $dsname@$MK_TAG) to $DSTINFO ..."
		ss send $dup-v -I $SRCDS${matchfx} $SRCDS${dsname}@${MK_TAG} | ds recv -F ${DSTDS}$dsname
		if [ $? -ne 0 ]
		then
			eecho "sync $SRCINFO($matchfx - $dsname@$MK_TAG) to $DSTINFO failed."
			exit 1
		fi
	fi
done
pecho ""
pecho "all done."
pecho ""
exit 0
#


