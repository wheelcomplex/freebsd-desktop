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
pw usermod root -s /bin/sh

su -

kldload linux

cat <<EOF > /root/.profile
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
echo '[[ $PS1 && -f /usr/local/share/bash-completion/bash_completion.sh ]] && source /usr/local/share/bash-completion/bash_completion.sh' >> /root/.shrc

chmod +x /root/.shrc /root/.cshrc

#

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

pkg bootstrap

# base pkg
# git included in git-gui
pkgloop install -y bash bash-completion sudo pciutils usbutils vim rsync cpuflags axel git-gui wget ca_root_nss subversion pstree bind-tools pigz gtar

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

# allow wheel group sudo
echo '%wheel ALL=(ALL) ALL' >> /usr/local/etc/sudoers

# for bash
ln -s /usr/local/bin/bash /bin/bash

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

camcontrol identify /dev/da0


#
# freebsd vs linux
#
# strace / truss
#

top -I -a -t -S -P

#

cat <<EOF>> /boot/loader.conf
#
# keep system stable
# https://wiki.freebsd.org/ZFSTuningGuide
# use 3/4 of total memory
vm.kmem_size="3G"
# use 1/2 of total memory
vfs.zfs.arc_max="2G"
#disable prefetch for ssd disk
vfs.zfs.prefetch_disable="1"

# base mod
#
zfs_load="YES"
geom_eli_load="YES"

fdescfs_load="YES"
linux_load="YES"
linprocfs_load="YES"
#
# networking
#
if_bridge_load="YES"
bridgestp_load="YES"
#
wlan_xauth_load="YES"
#
kern.vty=vt
#
snd_driver_load="YES"
#
EOF

cat /boot/loader.conf


#
#
# NOTE: overwrite
#

cat <<'EOF' > /etc/rc.conf
#
hostname="yinjiajin-freebsd-devel-001.localdomain"

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
ifconfig_em0="inet 10.236.12.201/24"
defaultrouter="10.236.12.1"

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

# kernel modules
kld_list="if_bridge bridgestp fdescfs linux linprocfs wlan_xauth snd_driver"
#

EOF

#


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
# bring root ro bash
#

# for chromium
cat <<'EOF' >> /etc/sysctl.conf
# for chromium
kern.ipc.shm_allow_removed=1

#
EOF

#### ------------------------

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

#
# http://yaws.hyber.org/privbind.yaws
# http://crossbar.io/docs/Running-on-privileged-ports/
# binding to privileged ports
# net.inet.ip.portrange.reservedhigh
#

echo 'net.inet.ip.portrange.reservedlow=0' >> /etc/sysctl.conf
echo 'net.inet.ip.portrange.reservedhigh=1023' >> /etc/sysctl.conf

#



#
# addon pkgs
#
# https://www.freebsd.org/doc/handbook/pkgng-intro.html
#

pkg audit -F && pkg upgrade && pkg autoremove


#

