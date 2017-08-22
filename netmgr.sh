#!/bin/sh

if [ `id -u` -ne 0 ]
then
    sudo $0 $@
    exit $?
fi

. /etc/initz.network.conf

# for wlan0
test -z "$WIFICLIENTIF" && WIFICLIENTIF="wlan0"

# for wlan1, softap
test -z "$SOFTAPIF" && SOFTAPIF="wlan1"

test -z "$LANBRIDGE" && LANBRIDGE="bridge0"

test -z "$APBRIDGE" && APBRIDGE="bridge1024"

test -z "$AP_ADDRS" && AP_ADDRS="172.16.252.254/24"

test -z "$CLIENTDHCP" && CLIENTDHCP="YES"

test -z "$SOFTAPTXPOWER" && SOFTAPTXPOWER="10"

test -z "$WIFICLIENTTXPOWER" && WIFICLIENTTXPOWER="30"

test -z "$WIFIRANDOMMAC" && WIFIRANDOMMAC="NO"

# load wlan kmods
kmods="wlan wlan_xauth wlan_ccmp wlan_tkip wlan_acl wlan_amrr wlan_rssadapt"
for onemod in $kmods
do
    /sbin/kldload $onemod 2>/dev/null
done
# kldstat|grep wlan

genmac(){
    local msg="$@"
    if [ -z "$msg" ]
    then
        echo -n 02-60-2F; dd bs=1 count=3 if=/dev/random 2>/dev/null |hexdump -v -e '/1 "-%02X"'
    else
        echo -n 02-60-2F; echo "$msg" | md5 | dd bs=1 count=3 2>/dev/null |hexdump -v -e '/1 "-%02X"'
    fi
}

genmac2(){
		genmac | tr '-' ':'
}

wired_reset(){
    service sshd start
    ifconfig $LANBRIDGE destroy 2>/dev/null
    sleep 1
    service netif stop >/dev/null
    sleep 1
    service netif start
    #
    ifconfig $APBRIDGE >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
        /sbin/ifaceboot $APBRIDGE up
    fi
    local addr=""
    local alias=""
    for addr in $AP_ADDRS
    do
        /sbin/ifconfig $APBRIDGE $addr $alias
        alias="alias"
    done
    #
    local allnic=""
    local addms=""
    local nic=""
    local nicflags=$LAN_NICS
    if [ "$nicflags" = "AUTO" -o "$nicflags" = "AUTOX" ]
    then
        LAN_NICS=`ifconfig -a | grep ": flags=" | tr ':' ' '| awk '{print $1}'| grep -v ^lo | grep -v ^bridge| grep -v ^pf| grep -v ^tap | grep -v ^wlan`
    fi
    for nic in $LAN_NICS
    do
        ifconfig $nic | grep -q 'ether '
        if [ $? -ne 0 ]
        then
            echo "skipped non-ether device: $nic"
            continue
        fi
        if [ -z "$addms" -a "$LAN_NICS" = "AUTOX" ]
        then
            addms="x"
            echo "skipped first-ether device for $nicflags: $nic"
            continue
        fi
        if [ -z "$addms" -o "$addms" = "x" ]
        then
            addms="addm $nic"
        else
            addms="$addms addm $nic"
        fi
        ifconfig $nic up
    done
    if [ -z "$addms" -o "$addms" = "x" ]
    then
        echo "warning: LAN_NICS not found or not defined($nicflags)."
    fi
    ifconfig $LANBRIDGE >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
        /sbin/ifaceboot $LANBRIDGE $addms up || exit 1
    fi
    local addr=""
    local alias=""
    for addr in $LAN_ADDRS
    do
        /sbin/ifconfig $LANBRIDGE $addr $alias
        alias="alias"
    done
    echo " ----"
    test -n "$WAN_GW" && route add -net 0/0 $WAN_GW
    echo " ----"
    sleep 1
    #ifconfig
    netstat -nr -4
    echo " ----"
    /sbin/ifconfig $LANBRIDGE
    echo " ----"
    /sbin/ifconfig $APBRIDGE
    echo " ----"
    service dnsmasq stop
    service dnsmasq start
    echo " ----"
    pfsess start
    echo " ----"
    echo "wired networking reseted."
    echo " ----"
}

wifi_client(){
    local arg1="$1"
    local code=0
    # sleep to prevent panic
    ifconfig $WIFICLIENTIF down 2>/dev/null
    sleep 1
    killall wpa_supplicant 2>/dev/null
    sleep 1
    ifconfig $WIFICLIENTIF destroy 2>/dev/null
    sleep 1
    if [ "$arg1" = "stop" ]
    then
        pfsess start 
        return $?
    fi
    local devlist="$WIFICLIENTNIC"
    if [ "$WIFICLIENTNIC" = 'AUTO' ]
    then
        local drvlist=`kldstat -v| grep 'if_' | grep -v 'if_lo' | grep -v 'if_lagg' | grep -v 'if_vlan' | grep -v 'if_bridge' | grep -v 'if_gif'| grep -v 'if_tun'| grep -v 'if_tap'| awk -F'if_' '{print $2}'| tr '_.' ' '| awk '{print $1}'`
        drvlist="$drvlist `dmesg | grep '[1-9]T[1-9]R'| grep ': '| tr ':[0-9]' ' '|awk '{print $1}'| sort|uniq`"
        local onedrv=''
        devlist=''
        for onedrv in $drvlist
        do
            local fndev=`dmesg | ''grep "^${onedrv}[0-9]:"| awk -F':' '{print $1}'| sort|uniq`
            if [ -z "$fndev" ]
            then
                continue
            fi
            fndev=`echo $fndev`
            # dedup
            echo "$devlist" | grep -q "$fndev" && echo "already exist: $fndev" && continue
            test -n "$SOFTAPNIC" -a "$SOFTAPNIC" = "$fndev" && echo "softap device skipped: $fndev" && continue
            echo "new device: $fndev"
            if [ -z "$devlist" ]
            then
                devlist=$fndev
            else
                devlist="$devlist $fndev"
            fi
        done
    fi
    if [ -z "$devlist" ]
    then
        echo "ERROR: wireless device not found"
        return 1
    else
        echo ""
        echo "TRYING WITH WIRELESS DEVICES: $devlist"
        echo ""
    fi
    local scanfile="/tmp/netmgr.wificlient.log"
    for wifidev in $devlist
    do
        sleep 3
        local connected=0
		local mac=""
		if [ "$WIFIRANDOMMAC" = "YES" ]
		then
			mac="ether `genmac2`"
			echo "USING RANDOM MAC: $mac"
		fi
        local brcmd="/sbin/ifaceboot $WIFICLIENTIF $wifidev wlanmode sta $mac up"
        echo "create wificlient device: $brcmd"
        $brcmd >/dev/null 2>&1
        /sbin/ifconfig $WIFICLIENTIF >/dev/null 2>&1
        test $? -ne 0 && echo "FAILED: $WIFICLIENTIF $wifidev wlanmode sta up" && continue
        sleep 1 && /sbin/ifconfig $WIFICLIENTIF txpower 30 2>/dev/null
        echo "bring up $WIFICLIENTIF($wifidev) ..."
        /sbin/ifconfig $WIFICLIENTIF up
		if [ "$WIFIRANDOMMAC" = "YES" ]
		then
			/sbin/ifconfig $WIFICLIENTIF | grep -i -q "$mac"
			if [ $? -ne 0 ]
			then
				echo "WARNING: random mac $mac not effect"
			else
				echo "RANDOM MAC $mac works"
			fi
		fi
        sleep 1
        local ssid5g=`ls -A /etc/wpa_supplicant.conf.* | awk -F'.conf.' '{print $2}'| grep -i '_5G$'|sort`
        local ssid2g=`ls -A /etc/wpa_supplicant.conf.* | awk -F'.conf.' '{print $2}'| grep -iv '_5G$'|sort`
        if [ -z "$ssid5g" -a -z "$ssid2g" ]
        then
            echo ""
            echo "ERROR: get ssid list from /etc/wpa_supplicant.conf.* failed"
            continue
        fi
        local ssidlist=''
        local item=''
        for item in $ssid5g $ssid2g
        do
            ssidlist="$ssidlist $item"
        done
        echo ""
        echo "scaning and match SSID:$ssidlist"
        echo ""
        local targetssid=''
		local scantimeout=20
        for aaa in `seq 0 10`
        do
            timeout 5 /sbin/ifconfig wlan0 scan > $scanfile || \
            timeout $scantimeout /sbin/ifconfig wlan0 scan > $scanfile
            local airssid=`cat ${scanfile}.5g | awk '{print $1}' | sort | uniq`
			local air5g=""
			local air2g=""
            for onessid in $airssid
            do
				echo "$onessid" | grep -i -q '_5G' && air5g="$air5g $onessid" && continue
				air2g="$air2g $onessid"
			done
            if [ -z "$airssid" ]
            then
				echo "air ssid not found, re-try($aaa) ..."
                sleep 2
				let scantimeout=$scantimeout+5 >/dev/null
                continue
            fi
			airssid="$air5g $air2g"
			echo "Aviable SSID:$airssid"
            for onessid in $airssid
            do
                for cssid in $ssidlist
                do
                    if [ "$cssid" = "$onessid" ]
                    then
                        targetssid="$onessid"
                        break
                    fi
                done
                test -n "$targetssid" && break
            done
            test -n "$targetssid" && break
        sleep 1
        done
        if [ -z "$targetssid" ]
        then
            echo ""
            echo "ERROR: ssid mismatched."
            echo ""
            continue
        fi
        ifconfig $WIFICLIENTIF txpower $WIFICLIENTTXPOWER 2>/dev/null
        echo "connecting to $targetssid ..."
        wpacfg="/etc/wpa_supplicant.conf.$targetssid"
        /usr/sbin/wpa_supplicant -B -i $WIFICLIENTIF -c $wpacfg
        echo ""
        echo "waiting for $WIFICLIENTIF($wifidev => $targetssid) ..."
        local bssid=''
        connected=0
        for aaa in `seq 1 60`
        do
			ifconfig $WIFICLIENTIF >/dev/null 2>&1
			if [ $? -ne 0 ]
			then
				echo "$WIFICLIENTIF has not be configured."
				break
			fi
            bssid=`ifconfig $WIFICLIENTIF | grep "ssid " | awk -F'bssid' '{print $2}'| awk '{print $1}'`
            test -n "$bssid" && ifconfig $WIFICLIENTIF | grep -q 'status: associated'
            test $? -eq 0 && connected=1 && break
            sleep 1
        done
        echo " ----"
        if [ $connected -eq 0 ]
        then
            echo "WIFI CLIENT CONNECT FAILED."
            echo " ----"
            continue
        fi
        
        echo -n "WIFI CLIENT CONNECTED($WIFICLIENTIF:$wifidev): " && ifconfig $WIFICLIENTIF | grep "ssid "
        echo " ----"
        #ifconfig $WIFICLIENTIF
            if [ "$CLIENTDHCP" = "YES" ]
            then
                dhclient $WIFICLIENTIF
            fi
        #
        #/sbin/ifconfig $WIFICLIENTIF
        service dnsmasq restart >/dev/null 2>&1
        pfsess start
        netstat -nr -4
        echo " ----"
        cat $scanfile | grep "$bssid"
        echo " ----"
        if [ $WIFIMONITOR -eq 0 ]
        then
            echo "`date` connected($WIFIRECONNECTCNT) on $WIFICLIENTIF($wifidev) $targetssid($bssid)."
            echo " ----"
            return 0
        fi
        echo "`date` monitor($WIFIRECONNECTCNT) on $WIFICLIENTIF($wifidev) $targetssid($bssid) ..."
        while [ : ]
        do
            sleep 3
            ifconfig $WIFICLIENTIF | grep -q 'status: associated'
            if [ $? -ne 0 ]
            then
                let WIFIRECONNECTCNT=$WIFIRECONNECTCNT+1 >/dev/null
                echo "`date` connection lost($WIFIRECONNECTCNT), re-rty ..."
                # call myself
                wifi_client stop >/dev/null 2>&1
                break
            fi
        done
    done
    #
    return 1
}

soft_ap(){
    local arg1="$1"
    local code=0
    cat /etc/hostapd.conf 2>/dev/null| grep -v '^#'|grep -q "^interface=$SOFTAPIF"
    if [ $? -ne 0 ]
    then
        echo "----"
        echo "error: interface=$SOFTAPIF not defined in /etc/hostapd.conf."
        echo -n "current define: " && cat /etc/hostapd.conf 2>/dev/null| grep -v '^#'|grep "^interface=$SOFTAPIF"
        echo "----"
        return 1
    fi
    killall hostapd 2>/dev/null
    # sleep to prevent panic
    sleep 1
    ifconfig $SOFTAPIF destroy 2>/dev/null
    sleep 1
    ifconfig $APBRIDGE >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
        /sbin/ifaceboot $APBRIDGE
    fi
    local addr=""
    local alias=""
    for addr in $AP_ADDRS
    do
        /sbin/ifconfig $APBRIDGE $addr $alias
        alias="alias"
    done
    if [ "$arg1" = "stop" ]
    then
        return $?
    fi
    test -z "$SOFTAPNIC" && echo "device for softap (SOFTAPNIC) not defined" && return 0
    local brcmd="/sbin/ifaceboot $SOFTAPIF $SOFTAPNIC wlanmode hostap"
    echo "create softap bridge: $brcmd"
    $brcmd >/dev/null 2>&1
    /sbin/ifconfig $SOFTAPIF >/dev/null 2>&1
    test $? -ne 0 && echo "FAILED: $SOFTAPIF $SOFTAPNIC wlanmode hostap" && return 1
    sleep 1
    ifconfig $SOFTAPIF txpower $SOFTAPTXPOWER 2>/dev/null
    /sbin/ifconfig $SOFTAPIF up
    sleep 1
    rm -f /var/run/hostapd/$SOFTAPIF
    sleep 1
    # /etc/rc.d/hostapd onestart
    nohup /usr/sbin/hostapd -P /var/run/hostapd.pid -d /etc/hostapd.conf > /var/log/hostapd.log 2>&1 </dev/zero &
    #
    sleep 1
    /sbin/ifconfig $SOFTAPIF up 
    sleep 3
    /sbin/ifconfig $SOFTAPIF
    /sbin/ifconfig $APBRIDGE addm $SOFTAPIF
    echo "waiting for $SOFTAPIF(15 seconds) ..."
    for aaa in `seq 1 15`
    do
        ifconfig $SOFTAPIF | grep -v 'ssid ""'|grep -q 'ssid '
        test $? -eq 0 && break
        sleep 1
    done
    echo " ----"
    echo -n "SOFT AP: " && ifconfig $SOFTAPIF | grep "ssid "
    echo " ----"
    /sbin/ifconfig $SOFTAPIF
    /sbin/ifconfig $APBRIDGE
    return $code
}

export WIFIRECONNECTCNT=0
export WIFIMONITOR=0
if [ -z "$1" ]
then
    wired_reset start
    soft_ap start
	curgw=`netstat -nr -4 | grep '^default' | awk '{print $2}'`
	if [ -n "$WAN_GW" -a "$curgw" = "$WAN_GW" ]
	then
		ping -c 2 -t 2 $WAN_GW
		ping -t 2 -c 2 8.8.8.8
		ping -c 2 -t 2 $WAN_GW >/dev/null 2>&1 && ping -t 2 -c 2 8.8.8.8 >/dev/null 2>&1
		if [ $? -ne 0 ]
		then
			echo " - "
			echo " - LAN gateway $WAN_GW exist but unusable, delete it."
			route delete -net 0/0 >/dev/null
			echo " - "
			WAN_GW=""
		fi
	else
		WAN_GW=""
	fi
	if [ -z "$WAN_GW" ]
	then
		wifi_client start
	else
		echo " - "
		echo " - LAN gateway $WAN_GW exist activated, wifi client disabled."
		echo " - "
	fi
    #
    /usr/sbin/pfsess start > /dev/null
    echo "PF firewall refreshed."
    #
    exit $?
fi
if [ "$1" = "pf" ]
then
    /usr/sbin/pfsess start > /dev/null
    echo "PF firewall refreshed."
fi
if [ "$1" = "stop" ]
then
    soft_ap stop
    wifi_client stop
    wired_reset stop
    /usr/sbin/pfsess start > /dev/null
    echo "PF firewall refreshed."
    exit $?
fi

if [ "$1" = "lan" ]
then
    if [ "$2" = "stop" ]
    then
        wired_reset stop
        exit 0
    fi
    wired_reset start
    exit $?
fi

if [ "$1" = "softap" ]
then
    if [ "$2" = "stop" ]
    then
        soft_ap stop
        exit 0
    fi
    soft_ap start
    exit $?
fi

if [ "$1" = "wificlient" ]
then
    if [ "$2" = "stop" ]
    then
        wifi_client stop
        exit 0
    fi
    code=0
    if [ "$2" = "monitor" ]
    then
        WIFIMONITOR=1
    fi
    while [ : ]
    do
        wifi_client start
        if [ $WIFIMONITOR -ne 1 ]
        then
            break
        fi
    done
    exit $?
fi
#
