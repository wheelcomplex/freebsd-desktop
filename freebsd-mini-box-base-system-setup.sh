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

sh -c 'ASSUME_ALWAYS_YES=yes pkg bootstrap -f' && pkg install -y bash wget sudo && ln -s /usr/local/bin/bash /bin/bash && mount -t fdescfs fdesc /dev/fd

# allow wheel group sudo
echo '%wheel ALL=(ALL) ALL' >> /usr/local/etc/sudoers

bash

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
pkgloop install -y sudo pciutils usbutils vim rsync cpuflags axel git-gui wget ca_root_nss subversion pstree bind-tools pigz gtar dot2tex

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

camcontrol identify /dev/da0


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
hostname="flatbsd-nb.localdomain"

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

# kernel modules
kld_list="if_bridge bridgestp fdescfs linux linprocfs wlan_xauth snd_driver coretemp"
#

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

# anti-gfw 
pkgloop install -y shadowsocks-libev

cat <<'EOF'>> /etc/rc.local
# for dns forward
nohup /usr/local/bin/ss-tunnel -s your-remote-server-ip -p remote-server-port -l 8053 -b 127.0.0.1 -t 30 -k remote-server-password -m chacha20 -L 8.8.8.8:53 -u -v < /dev/zero >/var/log/ss-dns.log 2>&1 &
# for socks-5 client
nohup /usr/local/bin/ss-local -s your-remote-server-ip -p remote-server-port -l 8080 -b 127.0.0.1 -t 30 -k remote-server-password -m chacha20 -v < /dev/zero >/var/log/ss-local.log 2>&1 &
# launch chrome --proxy-server=socks5://127.0.0.1:8080
EOF

#
pkgloop install -y proxychains-ng

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

## wpa2-psk wifi client
# for open wifi: ifconfig wlan0 ssid xxxx && dhclient wlan0

pkgloop install -y wpa_supplicant

cp /usr/local/etc/wpa_supplicant.conf /usr/local/etc/wpa_supplicant.conf.dist

echo 'wpa_supplicant_program="/usr/local/sbin/wpa_supplicant"' >> /etc/rc.conf

cat <<'EOF' >/usr/local/etc/wpa_supplicant.conf
##### Example wpa_supplicant configuration file ###############################
#
# This file describes configuration file format and lists all available option.
# Please also take a look at simpler configuration examples in 'examples'
# subdirectory.
#
# Empty lines and lines starting with # are ignored

# NOTE! This file may contain password information and should probably be made
# readable only by root user on multiuser systems.

# Note: All file paths in this configuration file should use full (absolute,
# not relative to working directory) path in order to allow working directory
# to be changed. This can happen if wpa_supplicant is run in the background.

# Whether to allow wpa_supplicant to update (overwrite) configuration
#
# This option can be used to allow wpa_supplicant to overwrite configuration
# file whenever configuration is changed (e.g., new network block is added with
# wpa_cli or wpa_gui, or a password is changed). This is required for
# wpa_cli/wpa_gui to be able to store the configuration changes permanently.
# Please note that overwriting configuration file will remove the comments from
# it.
update_config=1

# global configuration (shared by all network blocks)
#
# Parameters for the control interface. If this is specified, wpa_supplicant
# will open a control interface that is available for external programs to
# manage wpa_supplicant. The meaning of this string depends on which control
# interface mechanism is used. For all cases, the existence of this parameter
# in configuration is used to determine whether the control interface is
# enabled.
#
# For UNIX domain sockets (default on Linux and BSD): This is a directory that
# will be created for UNIX domain sockets for listening to requests from
# external programs (CLI/GUI, etc.) for status information and configuration.
# The socket file will be named based on the interface name, so multiple
# wpa_supplicant processes can be run at the same time if more than one
# interface is used.
# /var/run/wpa_supplicant is the recommended directory for sockets and by
# default, wpa_cli will use it when trying to connect with wpa_supplicant.
#
# Access control for the control interface can be configured by setting the
# directory to allow only members of a group to use sockets. This way, it is
# possible to run wpa_supplicant as root (since it needs to change network
# configuration and open raw sockets) and still allow GUI/CLI components to be
# run as non-root users. However, since the control interface can be used to
# change the network configuration, this access needs to be protected in many
# cases. By default, wpa_supplicant is configured to use gid 0 (root). If you
# want to allow non-root users to use the control interface, add a new group
# and change this value to match with that group. Add users that should have
# control interface access to this group. If this variable is commented out or
# not included in the configuration file, group will not be changed from the
# value it got by default when the directory or socket was created.
#
# When configuring both the directory and group, use following format:
# DIR=/var/run/wpa_supplicant GROUP=wheel
# DIR=/var/run/wpa_supplicant GROUP=0
# (group can be either group name or gid)
#
# For UDP connections (default on Windows): The value will be ignored. This
# variable is just used to select that the control interface is to be created.
# The value can be set to, e.g., udp (ctrl_interface=udp)
#
# For Windows Named Pipe: This value can be used to set the security descriptor
# for controlling access to the control interface. Security descriptor can be
# set using Security Descriptor String Format (see http://msdn.microsoft.com/
# library/default.asp?url=/library/en-us/secauthz/security/
# security_descriptor_string_format.asp). The descriptor string needs to be
# prefixed with SDDL=. For example, ctrl_interface=SDDL=D: would set an empty
# DACL (which will reject all connections). See README-Windows.txt for more
# information about SDDL string format.
#
ctrl_interface=/var/run/wpa_supplicant

# IEEE 802.1X/EAPOL version
# wpa_supplicant is implemented based on IEEE Std 802.1X-2004 which defines
# EAPOL version 2. However, there are many APs that do not handle the new
# version number correctly (they seem to drop the frames completely). In order
# to make wpa_supplicant interoperate with these APs, the version number is set
# to 1 by default. This configuration value can be used to set it to the new
# version (2).
# Note: When using MACsec, eapol_version shall be set to 3, which is
# defined in IEEE Std 802.1X-2010.
eapol_version=1

# AP scanning/selection
# By default, wpa_supplicant requests driver to perform AP scanning and then
# uses the scan results to select a suitable AP. Another alternative is to
# allow the driver to take care of AP scanning and selection and use
# wpa_supplicant just to process EAPOL frames based on IEEE 802.11 association
# information from the driver.
# 1: wpa_supplicant initiates scanning and AP selection; if no APs matching to
#    the currently enabled networks are found, a new network (IBSS or AP mode
#    operation) may be initialized (if configured) (default)
# 0: driver takes care of scanning, AP selection, and IEEE 802.11 association
#    parameters (e.g., WPA IE generation); this mode can also be used with
#    non-WPA drivers when using IEEE 802.1X mode; do not try to associate with
#    APs (i.e., external program needs to control association). This mode must
#    also be used when using wired Ethernet drivers.
#    Note: macsec_qca driver is one type of Ethernet driver which implements
#    macsec feature.
# 2: like 0, but associate with APs using security policy and SSID (but not
#    BSSID); this can be used, e.g., with ndiswrapper and NDIS drivers to
#    enable operation with hidden SSIDs and optimized roaming; in this mode,
#    the network blocks in the configuration file are tried one by one until
#    the driver reports successful association; each network block should have
#    explicit security policy (i.e., only one option in the lists) for
#    key_mgmt, pairwise, group, proto variables
# Note: ap_scan=2 should not be used with the nl80211 driver interface (the
# current Linux interface). ap_scan=1 is optimized work working with nl80211.
# For finding networks using hidden SSID, scan_ssid=1 in the network block can
# be used with nl80211.
# When using IBSS or AP mode, ap_scan=2 mode can force the new network to be
# created immediately regardless of scan results. ap_scan=1 mode will first try
# to scan for existing networks and only if no matches with the enabled
# networks are found, a new IBSS or AP mode network is created.
ap_scan=1

# MPM residency
# By default, wpa_supplicant implements the mesh peering manager (MPM) for an
# open mesh. However, if the driver can implement the MPM, you may set this to
# 0 to use the driver version. When AMPE is enabled, the wpa_supplicant MPM is
# always used.
# 0: MPM lives in the driver
# 1: wpa_supplicant provides an MPM which handles peering (default)
#user_mpm=1

# Maximum number of peer links (0-255; default: 99)
# Maximum number of mesh peering currently maintained by the STA.
#max_peer_links=99

# Timeout in seconds to detect STA inactivity (default: 300 seconds)
#
# This timeout value is used in mesh STA to clean up inactive stations.
#mesh_max_inactivity=300

# cert_in_cb - Whether to include a peer certificate dump in events
# This controls whether peer certificates for authentication server and
# its certificate chain are included in EAP peer certificate events. This is
# enabled by default.
#cert_in_cb=1

# EAP fast re-authentication
# By default, fast re-authentication is enabled for all EAP methods that
# support it. This variable can be used to disable fast re-authentication.
# Normally, there is no need to disable this.
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

