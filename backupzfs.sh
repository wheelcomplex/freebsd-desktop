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

item_uniq(){
	local all="$@"
	local res="`doitem_uniq $all`"
	echo "$res"
}

doitem_uniq(){
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

usage(){
    pecho "$MK_SCRIPT [-x] [-t tag] <[host@]src dataset> <[host@]dst dataset>"
    exit 1
}

# 30 days
export EXPIRETS=`expr 30 \* 24 \* 60 \* 60`
export xtrace=""
export CLEAN=""
export debug=""
export snapshot="0"
export progress="0"
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
    if [ "$aaa" = "-T" ]
    then
        snapshot="1"
        continue
    fi
    if [ "$aaa" = "-v" ]
    then
        progress="1"
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
    if [ "$aaa" = "-D" ]
    then
        debug="YES"
        continue
    fi
    if [ "$aaa" = "-C" ]
    then
        CLEAN="YES"
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

SRCDS=`pathprune $SRCDS`
DSTDS=`pathprune $DSTDS`

SRCINFO=${SRCHOST}${SRCTR}${SRCDS}
DSTINFO=${DSTHOST}${DSTTR}${DSTDS}

pecho "zfs sync tag $MK_TAG from $SRCINFO => $DSTINFO ..."
pecho "source information ..."

srcimp=0
SRCPOOL=`echo $SRCDS|awk -F'/' '{print $1}'`
ss list $SRCPOOL >/dev/null 2>&1
if [ $? -ne 0 ]
then
	pecho "src pool $SRCPOOL no exist, try to import ..."
	sc zpool export -f $SRCPOOL >/dev/null 2>&1
	sc zpool import -N -f $SRCPOOL || exit 1
	srcimp=1
fi

ss list $DSTPOOL >/dev/null 2>&1
if [ $? -ne 0 ]
then
	pecho "import $SRCPOOL failed."
	exit 1
else
	pecho "src pool $SRCPOOL ready."
fi

ss list $SRCDS >/dev/null 2>&1
if [ $? -ne 0 ]
then
	eecho "$SRCDS no exist"
	exit 1
fi

cleanshapshot(){
	local site="$1"
	local dstds="$2"
	local scmd=ss
	if [ "$site" = "remote" ]
	then
		scmd=ds
	fi
	local limits=`date +%s`
	let limits=${limits}-${EXPIRETS}
	limits=`date -j -f %s ${limits} +%Y%m%d%H%M%S`
	pecho "cleaning snapshots old then ${EXPIRETS}($limits) for $site $dstds ..."

	$scmd list -H -o name,creation -s creation $dstds | head -n 1 > /tmp/zfs.${site}.${MK_TAG}.clean.list || exit 1
	local oname=""
	local ots=""
	local sts=""
	read oname ots < /tmp/zfs.${site}.${MK_TAG}.clean.list
	let sts=${ots:0:14}+1-1 2>/dev/null
	if [ $? -ne 0 ]
	then
		pecho "invalid source zfs list output for creation time(need patched zfs): $ots"
		exit 1
	fi
	$scmd list -t snapshot -H -o name,creation -s creation -r $dstds > /tmp/zfs.${site}.${MK_TAG}.clean.list || exit 1
	while read oname ots; 
	do 
		sts=${ots:0:14}
		if [ $sts -ge $limits ]
		then
			continue
		fi
		pecho "clean $sts - $oname"
		$scmd destroy -f $oname || exit 1
	done < /tmp/zfs.${site}.${MK_TAG}.clean.list
	pecho "clean $site $dstds done."
	return 0
}

if [ "$CLEAN" = "YES" ]
then
	cleanshapshot source $SRCDS || exit 1
fi

if [ "$snapshot" = "1" ]
then
	ss list -t snapshot ${SRCDS}@${MK_TAG} >/dev/null 2>&1
	if [ $? -ne 0 ]
	then
		ss snapshot -r ${SRCDS}@${MK_TAG} || exit 1
		pecho "src snapshot ${SRCDS}@${MK_TAG} created."
	else
		pecho "src snapshot ${SRCDS}@${MK_TAG} already existed."
	fi
fi

cat /dev/null > /tmp/zfs.src.${MK_TAG}.sn.list || exit 1
for oneds in `ss list -r -H -o name $SRCDS`
do
	ss list -t snapshot -H -o name -S creation -r $oneds | uniq >> /tmp/zfs.src.${MK_TAG}.sn.list || exit 1
done

srcdslist=''

# NOTE: does not sync base SRCDS 

dslen=${#SRCDS}
parents=""
prebase=''
for onesn in `cat /tmp/zfs.src.${MK_TAG}.sn.list`
do
	test -n "$prebase" && parents="$parents $prebase" && prebase=""
	suffix=${onesn:${dslen}};
	dsname="`echo $suffix | awk -F'@' '{print $1}'`"
	dsmark="`echo $dsname | tr '/' '_'`"
	echo "$suffix" >> /tmp/zfs.src.${MK_TAG}.suffix-$dsmark-ds.list
	srcdslist="$srcdslist $dsname"
	prebase=`dirname $onesn`
	test "$prebase" = "." && prebase=''
done

srcdslist=`item_uniq $srcdslist`

parents=`item_uniq $parents`

# test -n "$parents" && pecho "parents: $parents"

pecho "dest information ..."

dstimp=0
DSTPOOL=`echo $DSTDS|awk -F'/' '{print $1}'`
ds list $DSTPOOL >/dev/null 2>&1
if [ $? -ne 0 ]
then
	pecho "pool $DSTPOOL no exist, try to import ..."
	dc zpool export -f $DSTPOOL >/dev/null 2>&1
	dc zpool import -N -f $DSTPOOL || exit 1
	dstimp=1
fi

ds list $DSTPOOL >/dev/null 2>&1
if [ $? -ne 0 ]
then
	pecho "import $DSTPOOL failed."
	exit 1
else
	pecho "dst $DSTPOOL ready."
fi

dstcreate(){
	local dstds="$1"
	local dsname=""
	ds list $dstds >/dev/null 2>&1
	if [ $? -eq 0 ]
	then
		return 0
	fi
	local item=''
	for item in `echo $dstds | tr '/' ' '`
	do
		if [ -z "$dsname" ]
		then
			dsname="$item"
		else
			dsname="$dsname/$item"
		fi
		ds list $dsname >/dev/null 2>&1
		if [ $? -eq 0 ]
		then
			continue
		else
			pecho "$dsname no exist, create it ..."
			ds create $dsname
		fi
		
		ds list $dsname >/dev/null 2>&1
		if [ $? -ne 0 ]
		then
			eecho "create $dsname failed"
			exit 1
		else
			pecho "$dsname created."
		fi
	done
}

dstcreate $DSTDS

if [ "$CLEAN" = "YES" ]
then
	cleanshapshot dest $DSTDS || exit 1
fi

cat /dev/null > /tmp/zfs.dst.${MK_TAG}.sn.list || exit 1
for oneds in `ds list -r -H -o name $DSTDS`
do
	ds list -t snapshot -H -o name -S creation -r $oneds | uniq >> /tmp/zfs.dst.${MK_TAG}.sn.list || exit 1
done

dslen=${#DSTDS}
for onesn in `cat /tmp/zfs.dst.${MK_TAG}.sn.list`
do
	suffix=${onesn:${dslen}};
	dsname="`echo $suffix | awk -F'@' '{print $1}'`"
	dsmark="`echo $dsname | tr '/' '_'`"
	echo "$suffix" >> /tmp/zfs.dst.${MK_TAG}.suffix-$dsmark-ds.list
done

pecho "matching and sync ..."

dup="-D "
if [ $nodedup -eq 1 ]
then
	dup=""
fi

prg=""
if [ $progress -eq 1 ]
then
	prg="-v "
fi

srcdslist="# $srcdslist"
#pecho "dataset: $srcdslist"
for dsname in $srcdslist
do
	dsmark="`echo $dsname | tr '/' '_'`"
	test "$dsname" = "#" && dsmark="" && dsname=""
	matchfx=""
	firstfx=""
	srcds=${SRCDS}${dsname}
	nosend=0
	for onep in $parents
	do
		if [ "$srcds" = "$onep" ]
		then
			wecho ""
			wecho "parent dataset skipped: $srcds"
			wecho ""
			nosend=1
			break
		fi
	done
	test "$nosend" -ne 0 && continue
	pecho "sync $srcds ..."

	touch "/tmp/zfs.dst.${MK_TAG}.suffix-$dsmark-ds.list" || exit 1
	touch "/tmp/zfs.src.${MK_TAG}.suffix-$dsmark-ds.list" || exit 1

	while read srcfx
	do
		test -z "$firstfx" && firstfx=$srcfx && test "$debug" = "YES" && pecho "first snapshot: $firstfx"
		while read dstfx
		do
			if [ "$srcfx" = "$dstfx" ]
			then
				matchfx=$dstfx
				# break, find the newest match
				test "$debug" = "YES" && pecho "MATCH, last matchfx: $matchfx"
				break
			else
				test "$debug" = "YES" && pecho "mismatch, src $srcfx, dst $dstfx, last matchfx: $matchfx"
			fi
		done < /tmp/zfs.dst.${MK_TAG}.suffix-$dsmark-ds.list
		#
		# break, find the newest match
		test -n "$matchfx" && break
	done < /tmp/zfs.src.${MK_TAG}.suffix-$dsmark-ds.list

	dstcreate ${DSTDS}$dsname

	if [ -z "$firstfx" ]
	then
		pecho "src snapshot not exist, creating ..."
		firstfx="${dsname}@${MK_TAG}"
		matchfx=""
		srcsnapshot="${SRCDS}${firstfx}"
	
		ss list -t snapshot ${srcsnapshot} >/dev/null 2>&1
		if [ $? -ne 0 ]
		then
			ss snapshot ${srcsnapshot} || exit 1
			ss list -t snapshot ${srcsnapshot} >/dev/null 2>&1
			if [ $? -ne 0 ]
			then
				pecho "src snapshot ${srcsnapshot} failed."
				exit 1
			else
				pecho "src snapshot ${srcsnapshot} created."
			fi
		else
			pecho "src snapshot exist ? should not happen"
			exit 1
		fi
	fi

	if [ -z "$matchfx" ]
	then
		ds list ${DSTDS}$dsname >/dev/null 2>&1
		if [ $? -eq 0 ]
		then
			pecho "destroy dest befor sync: ${DSTDS}$dsname ..."
			ds destroy -rf ${DSTDS}$dsname || exit 1
		fi
		wecho ""
		wecho "snapshots out of sync, full sync ${SRCDS}${firstfx} to ${DSTDS}$dsname in $DSTINFO ..."
		wecho ""
		ss send $dup$prg ${SRCDS}${firstfx} | ds recv -F ${DSTDS}$dsname
		if [ $? -ne 0 ]
		then
			eecho "full sync ${SRCDS}${firstfx} to ${DSTDS}$dsname in $DSTINFO failed."
			exit 1
		fi
	else
		if [ "$firstfx" = "$matchfx" ]
		then
			pecho "destination $DSTINFO ${DSTDS}$dsname already synced with source: $SRCINFO ${SRCDS}${firstfx}"
			pecho ""
			continue
		fi
		pecho "sync $SRCINFO($matchfx - $firstfx) to $DSTINFO ..."
		ss send $dup$prg -I $SRCDS${matchfx} $SRCDS${firstfx} | ds recv -F ${DSTDS}$dsname
		if [ $? -ne 0 ]
		then
			eecho "sync $SRCINFO($matchfx - $firstfx) to $DSTINFO failed."
			pecho "re-try full sync ..."
			ds list ${DSTDS}$dsname >/dev/null 2>&1
			if [ $? -eq 0 ]
			then
				pecho "destroy snapshot in dest ${DSTDS}$dsname ..."
				ds destroy -rf ${DSTDS}$dsname || exit 1
			fi
			ss send $dup$prg ${SRCDS}${firstfx} | ds recv -F ${DSTDS}$dsname
			if [ $? -ne 0 ]
			then
				eecho "re-try full sync ${SRCDS}${firstfx} to ${DSTDS}$dsname in $DSTINFO failed."
				exit 1
			fi
			pecho "full sync(re-try) done."
		fi
	fi
done
if [ $srcimp -ne 0 ]
then
	if [ -n "$ZBAK_DELAY_EXPORT_FILE" ]
	then
		echo "${SRCHOST}${SRCTR}$SRCPOOL" >> $ZBAK_DELAY_EXPORT_FILE
	else
		sc zpool export -f $SRCPOOL >/dev/null 2>&1
		if [ $? -ne 0 ]
		then
			pecho "src pool $SRCPOOL export failed."
		else
			pecho "src pool $SRCPOOL exported."
		fi
	fi
fi
if [ $dstimp -ne 0 ]
then
	if [ -n "$ZBAK_DELAY_EXPORT_FILE" ]
	then
		echo "${DSTHOST}${DSTTR}$DSTPOOL" >> $ZBAK_DELAY_EXPORT_FILE
	else
		dc zpool export -f $DSTPOOL >/dev/null 2>&1
		if [ $? -ne 0 ]
		then
			pecho "dest pool $DSTPOOL export failed."
		else
			pecho "dest pool $DSTPOOL exported."
		fi
	fi
fi
pecho ""
pecho "all done."
pecho ""
exit 0
#


