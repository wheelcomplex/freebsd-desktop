#
# install 
#
# ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/amd64/amd64/ISO-IMAGES/11.0/FreeBSD-11.0-CURRENT-amd64-20151229-r292858-memstick.img
#
# initial pkg
#

#
# use sh for rsync
#

#

pw usermod root -s /bin/sh

sh -c 'ASSUME_ALWAYS_YES=yes pkg bootstrap -f' && pkg install -y bash wget sudo rsync && ln -s /usr/local/bin/bash /bin/bash && mount -t fdescfs fdesc /dev/fd

# allow wheel group sudo
echo '%wheel ALL=(ALL) ALL' >> /usr/local/etc/sudoers

bash

cat <<EOF > /root/.profile
#!/bin/sh
# $FreeBSD: head/etc/root/dot.profile 278616 2015-02-12 05:35:00Z cperciva $
#
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:~/bin
export PATH
HOME=/root
export HOME
TERM=${TERM:-xterm}
export TERM
PAGER=more
export PAGER
test -s ~/.shrc && . ~/.shrc
EOF

chmod +x /root/.profile

echo 'setenv SHELL /usr/local/bin/bash && sudo -s' >> /root/.cshrc
echo 'export SHELL=/usr/local/bin/bash && sudo -s' >> /root/.shrc
echo 'test -n "$PS1" && test -f /usr/local/share/bash-completion/bash_completion.sh && source /usr/local/share/bash-completion/bash_completion.sh' >> /root/.shrc

chmod +x /root/.shrc /root/.cshrc

#
# rhinofly login with bash
#

test -x /usr/local/bin/bash && pw usermod rhinofly -s /usr/local/bin/bash || pw usermod rhinofly -s /bin/sh

mkdir -p /usr/local/sbin/ 

cat <<'EOF' > /usr/local/sbin/pkgloop
#!/usr/local/bin/bash
MAXLOOP=128
if [ "$1" = '-M' -a -n "$2" ]
then
	MAXLOOP="$2"
	shift
	shift
fi
#
# install applications by root
#
cnt=0
exitcode=0
while [ $cnt -le $MAXLOOP ]
do
    let cnt=$cnt+1
    pkg $@
    exitcode=$?
    test $exitcode -eq 0 && break
    echo "`date` LOOP#$cnt: pkg $@"
    sleep 1
done
exit $exitcode
#
EOF

chmod +x /usr/local/sbin/pkgloop

# base pkg
# git included in git-gui
pkgloop install -y sudo pciutils usbutils vim rsync cpuflags axel git-gui wget ca_root_nss subversion pstree bind-tools pigz gtar dot2tex unzip && \
pkgloop install -y bash-completion

#
# fix: pkg: cached package xxxx: size mismatch, cannot continue
#
# pkg update -f

#

mkdir -p /usr/local/etc/bash_completion.d

# git completion
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O /usr/local/etc/bash_completion.d/git-completion.bash

# zfs completion
wget https://raw.githubusercontent.com/zfsonlinux/zfs/master/contrib/bash_completion.d/zfs -O /usr/local/etc/bash_completion.d/zfs

# devel/cpuflags

cpuflags clang

lspci

lsusb

# 

kldload snd_driver

cat /dev/sndstat

# Installed devices:
# pcm0: <Conexant CX20590 (Analog)> (play/rec) default
# pcm1: <Conexant CX20590 (Analog)> (play/rec)
# pcm2: <Intel Panther Point (HDMI/DP 8ch)> (play)
# 

#
# show disk info
#

camcontrol devlist

# check for TRIM support
camcontrol identify /dev/da0

# check for TRIM support
tunefs -p /dev/da0p1

#
# freebsd vs linux
#
# strace / truss
# tar / gtar
# tasksel / cpuset
#

top -I -a -t -S -P

#

cat <<EOF>> /boot/loader.conf
#
# keep system stable
# https://wiki.freebsd.org/ZFSTuningGuide
# use 3/4 of total memory
#vm.kmem_size="3G"
# use 1/2 of total memory
#vfs.zfs.arc_max="2G"
#disable prefetch for ssd disk
vfs.zfs.prefetch_disable="1"
#
vm.overcommit=2
#
kern.vty=vt
#
# more kernel modules listed in kld_list of /etc/rc.conf
#
EOF

# OR

cat <<EOF>> /boot/loader.conf
#
vm.overcommit=2
#
kern.vty=vt
#
# more kernel modules listed in kld_list of /etc/rc.conf
#
EOF

cat /boot/loader.conf

#
#
# NOTE: overwrite
#

cat <<'EOF' > /etc/rc.conf
#
hostname="n550jk.localdomain"

# kernel modules
kld_list="if_bridge bridgestp fdescfs linux linprocfs wlan_xauth snd_driver coretemp"
#

#
sshd_enable="YES"
moused_enable="YES"
ntpd_enable="YES"
powerd_enable="YES"
# Set dumpdev to "AUTO" to enable crash dumps, "NO" to disable
dumpdev="AUTO"
zfs_enable="YES"

#
ntpd_flags="-g"
syslogd_flags="-ss"
#
linux_enable="YES"
#

#
ifconfig_re0="DHCP"

#ifconfig_re0="inet 10.236.12.201/24"
#defaultrouter="10.236.12.1"

# ether 00:18:2a:e8:39:ea for 10.236.127.43
#ifconfig_re0="ether 00:18:2a:e8:39:ea DHCP"
#ifconfig_re0="DHCP"
#

# https://www.freebsd.org/doc/handbook/network-wireless.html

#### # for hostapd
#### wlans_run0="wlan0"
#### ifconfig_wlan0="wlanmode hostap up"
#### 
#### #
#### # https://www.freebsd.org/cgi/man.cgi?query=if_bridge&sektion=4
#### #
#### # https://forums.freebsd.org/threads/trying-to-set-up-a-network-bridge-for-dhcp.20287/#post-307943
#### # for SYNCDHCP
#### 
#### # https://www.freebsd.org/doc/handbook/network-bridging.html
#### ifconfig_em1="up"
#### ifconfig_em2="up"
#### ifconfig_em3="up"
#### 
#### # new usage of freebsd 11 ?
#### autobridge_interfaces="bridge0"
#### autobridge_bridge0="addm em1 addm em2 addm em3 addm wlan0 inet 172.236.127.43/24"
#### 
#### #
#### cloned_interfaces="bridge0"
#### ifconfig_bridge0="addm em1 addm em2 addm em3 addm wlan0 inet 172.236.127.43/24"
#### 

EOF

# coretemp
# sysctl -a | grep temperature
## hw.acpi.thermal.tz0.temperature: 65.1C
## dev.cpu.7.temperature: 57.1C
## dev.cpu.6.temperature: 57.1C
## dev.cpu.5.temperature: 60.1C
## dev.cpu.4.temperature: 60.1C
## dev.cpu.3.temperature: 59.1C
## dev.cpu.2.temperature: 59.1C
## dev.cpu.1.temperature: 67.1C
## dev.cpu.0.temperature: 67.1C


# https://www.freebsd.org/cgi/man.cgi?rc.conf(5)
#     kld_list	 (str) A list of kernel	modules	to load	right after the	local
#		 disks are mounted.  Loading modules at	this point in the boot
#		 process is much faster	than doing it via /boot/loader.conf
#		 for those modules not necessary for mounting local disk.


# for linux
mkdir -p /compat/linux/etc/ /compat/linux/proc

cat <<'EOF' > /compat/linux/etc/host.conf
#
order hosts, bind
multi on
#
EOF

# for linux
echo 'link /tmp shm' >> /etc/devfs.conf

#

cat <<EOF>> /etc/fstab
# for bash
fdesc /dev/fd fdescfs rw,late 0 0
proc /proc procfs rw,late 0 0

# for linux
linproc /compat/linux/proc linprocfs rw,late 0 0
#
EOF

# create
mv /etc/rc.local /etc/rc.local.orig.$$

# NOTE: overwrite
cat <<EOF> /etc/rc.local
#!/bin/sh

#
EOF

chmod +x /etc/rc.local

# TODO: PPPoE/ADSL WAN link


#
# fuck off bridge in /etc/rc.conf
#

cat <<'EOF' > /sbin/ifaceboot
#!/bin/bash
#
IFCONFIG_CMD="/sbin/ifconfig"
DHCPCLIENT_CMD="/sbin/dhclient"
KLDLOAD="/sbin/kldload"

#
export IFNAME="$1"
shift

export LOGCONSOLE='YES'

#
LOGGER="/usr/bin/logger -p user.notice -t $0"

# do not login
if [ -z "$USER" ]
    then
    LOGCONSOLE=''
fi

#
slog(){
    local msg="$@"
    test "$LOGCONSOLE" = 'YES' && echo "`date` $0 $msg" >&2
    $LOGGER "$msg"
}

#
pipelog(){
    local oneline
    while IFS= read -r oneline
    do
        slog "$oneline"
    done
}

# if_creator if
#
if_creator(){
    local ifphy="$1"
    case $IFNAME in
    bridge[0-9]*)
        bridge_creator $IFNAME
        return $?
    ;;
    wlan[0-9]*)
        # ifconfig wlan0 create wlandev ath0
        echo "$@" | grep -q 'wlanmode hostap'
        if [ $? -eq 0 ]
            then
            wlan_creator $IFNAME $ifphy hostap
            return $?
        else
            wlan_creator $IFNAME $ifphy
            return $?
        fi
    ;;
    *)
    ;;
    esac
}

# wlan_creator wlanif
#
wlan_creator(){
    slog "if_creator wlan: $@ ..."
    local ifname="$1"
    local ifphyname="$2"
    local ifmode="$3"
    echo "$ifname" | grep -q 'wlan[0-9]*' || return 127
    test -n "$ifphyname" || return 127
    local exitcode=0
    ${IFCONFIG_CMD} "${ifname}" destroy 2>/dev/null
    if [ "$ifmode" = 'hostap' ]; then
        $IFCONFIG_CMD "${ifname}" create wlandev "$ifphyname" wlanmode $ifmode 2>&1 | pipelog
        exitcode=${PIPESTATUS[0]}
        test $exitcode -ne 0 && slog "create ${ifname}($ifphyname) wlanmode $ifmode failed" && return $exitcode
    else
        $IFCONFIG_CMD "${ifname}" create wlandev "$ifphyname" 2>&1 | pipelog
        exitcode=${PIPESTATUS[0]}
        test $exitcode -ne 0 && slog "create ${ifname}($ifphyname) failed" && return $exitcode
    fi
    $KLDLOAD wlan_xauth 2>/dev/null
    return $exitcode
}

#
# bridge_creator bridgeif
#
bridge_creator(){
    local ifname="$1"
    # slog "bridge_creator $ifname ..."
    echo "$ifname" | grep -q 'bridge[0-9]*' || return 127
    local index=0
    index=`echo "$ifname" | awk -F'bridge' '{print $2}'`
    test -z "$index" && return 127
    test $index -ge 0 2>/dev/null || return 127
    local bridx=0
    local exitcode=0
    while [ : ]; do
        brname="bridge${bridx}"
        ${IFCONFIG_CMD} "${brname}" 2>/dev/null | grep -q -- "${brname}: flags="
        if [ $? -ne 0 ]; then
            $IFCONFIG_CMD bridge create 2>&1 | pipelog
            exitcode=${PIPESTATUS[0]}
            test $exitcode -ne 0 && slog "create $brname failed" && return $exitcode
        fi
        test $bridx -ge $index && break
        bridx=`expr $bridx + 1`
    done
    return $exitcode
}

#

slog "network interface configure: $IFNAME $@"
if [ -z "$IFNAME" ]
then
    slog "usage: $0 <ifname> [options]"
    exit $127
fi

# env 2>&1 | pipelog

if_creator $@ || exit $?

#

exitcode=0

$IFCONFIG_CMD $IFNAME up 2>&1 | pipelog
exitcode=${PIPESTATUS[0]}
test $exitcode -ne 0 && slog "network interface configure failed: $IFCONFIG_CMD $IFNAME up" && exit $exitcode

# ether 00:18:2a:e8:39:ea
cmd=''
arg=''
for item in $@
do
    if [ "$item" = 'up' ]
        then
        continue
    fi
    if [ "$item" = 'SYNCDHCP' ]
        then
        $DHCPCLIENT_CMD $IFNAME 2>&1 | pipelog
        exitcode=${PIPESTATUS[0]}
        test $exitcode -ne 0 && slog "network interface configure failed: $DHCPCLIENT_CMD $IFNAME"
        break
    fi
    if [ "$item" = 'DHCP' ]
        then
        $DHCPCLIENT_CMD -b $IFNAME 2>&1 | pipelog
        exitcode=${PIPESTATUS[0]}
        test $exitcode -ne 0 && slog "network interface configure failed: $DHCPCLIENT_CMD -b $IFNAME"
        break
    fi
    if [ "$cmd" = 'addm' -o "$cmd" = 'inet' -o "$cmd" = 'ether' ]
        then
        arg="$item"
    fi
    if [ "$item" = 'addm' -o "$item" = 'inet' -o "$item" = 'ether' ]
        then
        cmd=$item
        continue
    fi
    if [ -n "$cmd" ]
    then
        $IFCONFIG_CMD $IFNAME $cmd $arg 2>&1 | pipelog
        exitcode=${PIPESTATUS[0]}
        if [ $exitcode -ne 0 ]
            then
            slog "network interface configure failed: $IFCONFIG_CMD $IFNAME $cmd $arg" 
        fi
        if [ "$cmd" = 'addm' ]
            then
            $IFCONFIG_CMD $arg up
            exitcode=$?
            test $exitcode -ne 0 && slog "network interface configure failed: $IFCONFIG_CMD $arg up"
        fi
    fi
    cmd=''
    arg=''
done

#
$IFCONFIG_CMD $IFNAME up 2>&1 | pipelog
$IFCONFIG_CMD $IFNAME 2>&1 | pipelog

exit $exitcode
#

EOF

chmod +x /sbin/ifaceboot


# start on boot
cat <<'EOF' >> /etc/rc.local
# fix network interface configure in rc.conf
#    /sbin/ifaceboot wlan0 ath0 wlanmode hostap up
#
#    /sbin/ifconfig wlan0 txpower 5
#

#    /sbin/ifaceboot bridge0 addm em1 addm em2 addm em3 addm wlan0 inet 172.236.127.43/24

#
EOF

#
# dnsmasq dhcp server(with dns)
#

pkg install -y dnsmasq

#

cat <<'EOF'> /usr/local/etc/dnsmasq.conf
#
# port=0 to disable dns server part
#
port=53
#
no-resolv

server=10.236.8.8
server=10.237.8.8

# server=114.114.114.114
# server=8.8.8.8
# server=/google.com/8.8.8.8

all-servers

#
log-queries
#
# enable dhcp server
#
dhcp-range=172.236.127.51,172.236.127.90,2400h
#
#
log-dhcp
#
#
no-dhcp-interface=em0
#
#dhcp-range=vmbr0,10.236.12.21,10.236.12.30,3h
# option 6, dns server
#dhcp-option=vmbr0,6,10.236.8.8
# option 3, default gateway
#dhcp-option=vmbr0,3,10.236.12.1
# option 15, domain-name
#dhcp-option=vmbr0,15,localdomain
# option 119, domain-search
#dhcp-option=vmbr0,119,localdomain
#
#dhcp-range=vmbr9,198.119.0.21,198.119.0.199,3h
# option 6, dns server
#dhcp-option=vmbr9,6,198.119.0.11
# option 3, default gateway
#dhcp-option=vmbr9,3,198.119.0.11
# option 15, domain-name
#dhcp-option=vmbr9,15,localdomain
# option 119, domain-search
#dhcp-option=vmbr9,119,localdomain
#
# dhcp options
#
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 DHCPOFFER(vmbr0) 10.236.12.180 36:b8:a4:ad:46:05 
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 requested options: 1:netmask, 28:broadcast, 2:time-offset, 3:router, 
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 requested options: 15:domain-name, 6:dns-server, 119:domain-search, 
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 requested options: 12:hostname, 44:netbios-ns, 47:netbios-scope, 
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 requested options: 26:mtu, 121:classless-static-route, 42:ntp-server
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 next server: 10.236.12.11
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  1 option: 53 message-type  2
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option: 54 server-identifier  10.236.12.11
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option: 51 lease-time  10800
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option: 58 T1  5400
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option: 59 T2  9450
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option:  1 netmask  255.255.255.0
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option: 28 broadcast  10.236.12.255
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option:  3 router  10.236.12.11
#Nov  7 21:40:18 b2c-dc-pve1 dnsmasq-dhcp[8620]: 3744951815 sent size:  4 option:  6 dns-server  10.236.12.11
#
EOF

#

cat <<'EOF' >> /etc/syslog.conf
# dnsmasq server logging
!dnsmasq
*.*             /var/log/messages
!dnsmasq-dhcp
*.*             /var/log/messages
#
EOF

service syslogd restart

mv /etc/resolv.conf /etc/resolv.conf.orig.$$

cat <<'EOF'>/etc/resolv.conf
#
search localdomain
nameserver 127.0.0.1
#
EOF

chflags schg /etc/resolv.conf

# to unlock
# chflags noschg /etc/resolv.conf

#

cat <<'EOF' >> /etc/rc.conf
#
dnsmasq_enable="YES"
#
EOF

#

/usr/local/etc/rc.d/dnsmasq restart

#### ------------------------

#
# http://yaws.hyber.org/privbind.yaws
# http://crossbar.io/docs/Running-on-privileged-ports/
# binding to privileged ports
# net.inet.ip.portrange.reservedhigh
#

echo 'net.inet.ip.portrange.reservedlow=0' >> /etc/sysctl.conf
echo 'net.inet.ip.portrange.reservedhigh=1023' >> /etc/sysctl.conf

#

# anti-gfw 
pkgloop install -y shadowsocks-libev proxychains-ng

#
cp /usr/local/etc/proxychains.conf /usr/local/etc/proxychains.conf.$$
#
cat <<'EOF' > /usr/local/etc/proxychains.conf
# proxychains.conf  VER 4.x
#
#        HTTP, SOCKS4a, SOCKS5 tunneling proxifier with DNS.
strict_chain

# Quiet mode (no output from library)
quiet_mode

# Proxy DNS requests - no leak for DNS data
proxy_dns 

remote_dns_subnet 224

# Some timeouts in milliseconds
tcp_read_time_out 10000
tcp_connect_time_out 8000

## RFC1918 Private Address Ranges
localnet 10.0.0.0/255.0.0.0
localnet 172.16.0.0/255.240.0.0
localnet 192.168.0.0/255.255.0.0

#
[ProxyList]
# add proxy here ...
# meanwile
# defaults set to "ss"
socks5 	127.0.0.1 8080
#
EOF

#

cat <<'EOF'>> /usr/local/bin/ss-start.sh
#!/bin/sh
if [ `id -u` -ne 0 ]
then
        sudo $0
        exit $?
fi
#
rm -f ${HOME}/ss-*.core

killall ss-tunnel 2>/dev/null
killall ss-local 2>/dev/null

nohup /usr/local/bin/ss-tunnel -s ss-server-ip -p ss-server-port -l 8053 -b 127.0.0.1 -t 30 -k ss-server-password -m chacha20 -L 8.8.8.8:53 -u -v < /dev/zero >/var/log/ss-dns.log 2>&1 &
sleep 1
nohup /usr/local/bin/ss-local -s ss-server-ip -p ss-server-port -l 8080 -b 0.0.0.0 -t 30 -k ss-server-password -m chacha20 -v < /dev/zero >/var/log/ss-local.log 2>&1 &
sockstat -l | grep udp | grep ss| head -n3
sockstat -l | grep tcp | grep ss| head -n3
sleep 1
service dnsmasq restart
# launch chrome --proxy-server=socks5://127.0.0.1:8080
EOF

## wpa2-psk wifi client
# for open wifi: ifconfig wlan0 ssid xxxx && dhclient wlan0

pkgloop install -y wpa_supplicant

cp /usr/local/etc/wpa_supplicant.conf /usr/local/etc/wpa_supplicant.conf.dist

echo 'wpa_supplicant_program="/usr/local/sbin/wpa_supplicant"' >> /etc/rc.conf

cat <<'EOF' >/usr/local/etc/wpa_supplicant.conf
#####wpa_supplicant configuration file ###############################
#
update_config=0

#
ctrl_interface=/var/run/wpa_supplicant

eapol_version=1

ap_scan=1

fast_reauth=1

# Simple case: WPA-PSK, PSK as an ASCII passphrase, allow all valid ciphers
network={
	ssid="tutux-mini-139-wifi"
	psk="yourpassword"
	scan_ssid=1
	key_mgmt=WPA-PSK
	proto=RSN
	pairwise=CCMP TKIP
	group=CCMP TKIP
	priority=5
}
EOF

#
# debug
#

/usr/local/sbin/wpa_supplicant -d -i wlan0 -c /usr/local/etc/wpa_supplicant.conf

# on boot startup

cat <<'EOF' >> /etc/rc.local
#
/usr/local/sbin/wpa_supplicant -B -i wlan0 -c /usr/local/etc/wpa_supplicant.conf
sleep 5
dhclient wlan0
#
EOF

#
# addon pkgs
#
# https://www.freebsd.org/doc/handbook/pkgng-intro.html
#

pkg audit -F && pkg upgrade && pkg autoremove


#


#
# base system source
#

rm -rf /usr/src && svn checkout https://svn.FreeBSD.org/base/head /usr/src && svn update /usr/src

# #
# # upgrade by source
# #
# # https://www.freebsd.org/doc/handbook/synching.html
# #
# pkg install -y ca_root_nss subversion
# #
# # ports
# #
# svn checkout https://svn.FreeBSD.org/ports/head /usr/ports && svn update /usr/ports
# 
# #
# # doc
# #
# svn checkout https://svn.FreeBSD.org/doc/head /usr/doc && svn update /usr/doc
# 
# 
# #
# # base system source
# #
# 
# svn checkout https://svn.FreeBSD.org/base/head /usr/src && svn update /usr/src
# 
