#
# install 
#
# ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/amd64/amd64/ISO-IMAGES/11.0/FreeBSD-11.0-CURRENT-amd64-20151229-r292858-memstick.img
#
# initial pkg
#

echo '127.0.0.1 pos.baidu.com' >> /etc/hosts

#
# use sh for rsync
#

#

pw usermod root -s /bin/sh

# start on boot

# remove orig network
cat /etc/rc.conf| grep ifconfig_

sed -i -e '/ifconfig_/d' /etc/rc.conf
sed -i -e '/defaultrouter/d' /etc/rc.conf

cat /etc/rc.conf

## wpa2-psk wifi client
# for open wifi: ifconfig wlan0 ssid xxxx && dhclient wlan0

cp /etc/wpa_supplicant.conf /etc/wpa_supplicant.conf.dist.$$

cat <<'EOF' >/etc/wpa_supplicant.conf
#####wpa_supplicant configuration file ###############################
#
update_config=0

#
#ctrl_interface=/var/run/wpa_supplicant

#eapol_version=1

ap_scan=1

#fast_reauth=1

# Simple case: WPA-PSK, PSK as an ASCII passphrase, allow all valid ciphers
network={
    #ssid="aluminium-136"
    #psk="13609009086"
    ssid="Xiaomi_0800"
    psk="meiyoumimaa"
    scan_ssid=1
    key_mgmt=WPA-PSK
    proto=RSN
    pairwise=CCMP TKIP
    group=CCMP TKIP
    priority=5
}
#
EOF

#
# debug
#

dmesg | grep -C 5 -i RF
dmesg | grep -C 5 -i Wireless

# for wifi client
ifconfig wlan0 create wlandev rtwn0 wlanmode sta up

# list ssid
ifconfig wlan0 scan;sleep 3;ifconfig wlan0 scan;

/usr/sbin/wpa_supplicant -d -i wlan0 -c /etc/wpa_supplicant.conf

/usr/sbin/wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
sleep 5
dhclient wlan0

# allow wheel group sudo

# pkg bootstrap

# for aarch64 in FreeBSD 12: 
# http://www.raspbsd.org/raspberrypi.html https://wiki.freebsd.org/arm64/rpi3

export ABI=FreeBSD:11:aarch64; sh -c 'ASSUME_ALWAYS_YES=yes pkg bootstrap -f' && echo 'ABI = "FreeBSD:11:aarch64";' >> /usr/local/etc/pkg.conf

# for arm64
# https://raspberrypi.stackexchange.com/questions/68354/freebsd-shared-object-libarchive-so-6-not-found-required-by-pkg
# for error: Shared object "libarchive.so.6" not found, required by "pkg"

ls -alh /usr/lib/libarchive.so*

test ! -f /usr/lib/libarchive.so.6 && ln -vs /usr/lib/libarchive.so /usr/lib/libarchive.so.6

# for amd64

sh -c 'ASSUME_ALWAYS_YES=yes pkg bootstrap -f' 

pkg install -f -y kermit bash wget sudo rsync tree && ln -f /usr/local/bin/bash /bin/bash; \
echo '%wheel ALL=(ALL) ALL' >> /usr/local/etc/sudoers && \
cat /usr/local/etc/sudoers|tail -n 10 && mkdir -p /dev/fd && mount -t fdescfs fdesc /dev/fd;df -h

# cd /usr/ports/shells/bash && make install clean

bash

cat <<'EOF' > /root/.kermrc
; This is /etc/kermit/kermrc
; It is executed on startup if ~/.kermrc is not found.
; See "man kermit" and http://www.kermit-project.org/ for details on
; configuring this file, and /etc/kermit/kermrc.full
; for an example of a complex configuration file

; If you want to run additional user-specific customisations in
; addition to this file, place them in ~/.mykermrc

; Execute user's personal customization file (named in environment var
; CKERMOD or ~/.mykermrc)
;

#if def \$(CKERMOD) assign _myinit \$(CKERMOD)
#if not def _myinit assign _myinit \v(home).mykermrc

#xif exist \m(_myinit)  {		; If it exists,
#    echo Executing \m(_myinit)...	; print message,
#    take \m(_myinit)			; and TAKE the file.
#}

set line /dev/cuaU0

set speed 115200

set flow-control none

set carrier-watch off

set handshake none

robust

set file type bin

set file name lit

set rec pack 1000

set send pack 1000

set window 5

connect

#
EOF

chmod 0700 /root/.kermrc

cat <<'EOF' > /root/.profile
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

test -s /etc/profile && . /etc/profile

test -s ~/.shrc && . ~/.shrc
#

if [ -f "$HOME/.bashrc" ]; then
. "$HOME/.bashrc"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    echo "$PATH" | grep -q -- "$HOME/bin" || PATH="$HOME/bin:$PATH"
fi
EOF

chmod +x /root/.profile

cat <<'EOF'> /root/.bashrc
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
    else
    color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

#
test -f "${HOME}/.env-all" && source "${HOME}/.env-all"
#

EOF

cat <<'EOF'> /root/.env-all
#!/bin/bash

test -z "$PATH" && export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:~/bin"

#LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
#unset LIBRARY_PATH

#C_INCLUDE_PATH=/usr/include/x86_64-linux-gnu
#unset C_INCLUDE_PATH

#CPLUS_INCLUDE_PATH=/usr/include/x86_64-linux-gnu
#unset CPLUS_INCLUDE_PATH

#export LIBRARY_PATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
#unset LIBRARY_PATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH

# need for ctrl-s in vim
# stty stop ''
#
[[ $PS1 && -f /usr/local/share/bash-completion/bash_completion.sh ]] && source /usr/local/share/bash-completion/bash_completion.sh
test -x ${HOME}/.git-completion.bash && . ${HOME}/.git-completion.bash

echo " ---"
# start ssh-agent
eval `ssh-agent -s`
ssh-add
alias ssh="ssh -Y -X"
echo "ssh X11 forward enabled"
echo " ---"
#
EOF

chmod +x /root/.bashrc /root/.env-all

#
# root login with bash
#

test -x /usr/local/bin/bash && pw usermod root -s /usr/local/bin/bash || pw usermod root -s /bin/sh

su -

#
# david login with bash
#

test -x /usr/local/bin/bash && pw usermod david -s /usr/local/bin/bash || pw usermod david -s /bin/sh

mkdir -p /usr/local/sbin/ 

# for rpi3 aarch64 gen random MAC address
cat <<'EOF' > /sbin/genmac
#!/bin/sh
echo -n 00-60-2F; dd bs=1 count=3 if=/dev/random 2>/dev/null |hexdump -v -e '/1 "-%02X"'
EOF

chmod +x /sbin/genmac

#
# fix bridge in /etc/rc.conf
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
        # ifconfig wlan0 create wlandev rtwn0
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
etherarg=''
dhcparg=''
for item in $@
do
    if [ "$item" = 'up' ]
        then
        continue
    fi
    if [ "$item" = 'SYNCDHCP' ]
        then
        dhcparg="$item"
        continue
    fi
    if [ "$item" = 'DHCP' ]
        then
        dhcparg="$item"
        continue
    fi
    if [ "$cmd" = 'addm' -o "$cmd" = 'inet' -o "$cmd" = 'ether' -o "$cmd" = 'hwaddr' ]
        then
        arg="$item"
    fi
    if [ "$cmd" = 'ether' -o "$cmd" = 'hwaddr' ]
    then
        etherarg="$arg"
        continue
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

if [ -z "$etherarg" ]
then
    # set ether addr of bridge to ether of first member
    mnic=`$IFCONFIG_CMD $IFNAME | grep 'member:' | tail -n 1|awk '{print $2}'`
    if [ -n "$mnic" ]
    then
        etherarg=`$IFCONFIG_CMD $mnic | grep 'ether '| awk '{print $2}'`
    fi
fi
if [ -n "$etherarg" ]
then
    slog "network interface set ether $etherarg ..."
    $IFCONFIG_CMD $IFNAME ether $etherarg
    exitcode=$?
    test $exitcode -ne 0 && slog "network interface configure failed: $IFCONFIG_CMD $IFNAME ether $etherarg"
fi

#
$IFCONFIG_CMD $IFNAME up 2>&1 | pipelog

if [ "$dhcparg" = 'SYNCDHCP' ]
    then
    slog "network interface $dhcparg ..."
    $DHCPCLIENT_CMD $IFNAME 2>&1 | pipelog
    exitcode=${PIPESTATUS[0]}
    test $exitcode -ne 0 && slog "network interface $dhcparg failed: $DHCPCLIENT_CMD $IFNAME"
elif [ "$dhcparg" = 'DHCP' ]
    then
    slog "network interface $dhcparg ..."
    $DHCPCLIENT_CMD -b $IFNAME 2>&1 | pipelog
    exitcode=${PIPESTATUS[0]}
    test $exitcode -ne 0 && slog "network interface $dhcparg failed: $DHCPCLIENT_CMD -b $IFNAME"
fi

$IFCONFIG_CMD $IFNAME 2>&1 | pipelog

exit $exitcode
#

EOF

chmod +x /sbin/ifaceboot

cat <<'EOF' > /usr/local/sbin/lsblk
#!/usr/local/bin/bash
sysctl -n kern.geom.conftxt
for disk in `sysctl -n kern.geom.conftxt | grep DISK | grep -v LABEL|grep -v PART| awk '{print $3}'`
do
    echo " --- $disk"
    gpart show $disk
    echo " -"
done
echo " -"
camcontrol devlist
echo " -"
#
EOF

chmod +x /usr/local/sbin/lsblk

/usr/local/sbin/lsblk

# /usr/local/sbin/lsblk
#### 0 DISK da0 15819866112 512 hd 255 sc 63
#### 1 PART da0s1 15815671808 512 i 1 o 4194304 ty !12 xs MBR xt 12
#### 2 LABEL ext2fs/16GSDCARD 15815671808 512 i 0 o 0
#### 0 DISK ada1 2000398934016 512 hd 16 sc 63
#### 1 LABEL diskid/DISK-S34RJ9AG162507 2000398934016 512 i 0 o 0
#### 0 DISK ada0 16013942784 512 hd 16 sc 63
#### 1 PART ada0p3 801112064 512 i 3 o 15032406016 ty freebsd-swap xs GPT xt 516e7cb5-6ecf-11d6-8ff8-00022d09712b
#### 1 PART ada0p2 15031566336 512 i 2 o 839680 ty freebsd-ufs xs GPT xt 516e7cb6-6ecf-11d6-8ff8-00022d09712b
#### 1 PART ada0p1 819200 512 i 1 o 20480 ty efi xs GPT xt c12a7328-f81f-11d2-ba4b-00a0c93ec93b
#### 2 LABEL msdosfs/EFI 819200 512 i 0 o 0
#### 2 LABEL gptid/4af9aaa1-2d1b-11e6-9c03-00e04c680974 819200 512 i 0 o 0
#### 
####  --- da0
#### =>      63  30898113  da0  MBR  (15G)
####         63      8129       - free -  (4.0M)
####       8192  30889984    1  !12  (15G)
#### 
####  -
####  --- ada1
#### gpart: No such geom: ada1.
####  -
####  --- ada0
#### =>      40  31277152  ada0  GPT  (15G)
####         40      1600     1  efi  (800K)
####       1640  29358528     2  freebsd-ufs  (14G)
####   29360168   1564672     3  freebsd-swap  (764M)
####   30924840    352352        - free -  (172M)
#### 
####  -
#### 

cat <<'EOF' > /usr/local/sbin/fastpkg
#!/bin/bash
if [ `id -u` -ne 0 ]
then
    sudo $0 $@
    exit $?
fi
act="$1"
if [ "$act" != 'install' -a "$act" != 'fetch'  -a "$act" != 'upgrade' ]
then
    pkg $@
    exit $?
fi
shift

test "$1" = '-y' && shift

target="$@"

echo "fast pkg ${act}ing $target ..."

tmpfile="/tmp/fastpkg.$$.list"
echo "n" | pkg $act $target > $tmpfile 2>&1

list=`cat $tmpfile | grep -A 1000 "to be "| grep -v "to be "| grep -v 'Installed packages'| grep -v "The process will"|grep -v "to be downloaded."| grep -v "Proceed with this action"| grep -v 'ABI changed'| grep -v 'Number of packages to be'|grep -v 'Proceed '|awk -F': ' '{print $1}'| grep -v '^$'|awk '{print $1}'`;
dlinfo=`cat $tmpfile |grep "to be downloaded."`

needl=1
test -z "$dlinfo" && dlinfo="0 KiB to be downloaded." && needl=0

echo "$dlinfo ..."
echo " ---"

maxjobs(){
        local max="$1"
        local verb="$2"
        test -z "$max" && max=5
        if [ $max -eq $max ] 2>/dev/null
        then
            max=$max
        else
            max=5
        fi
        test -n "$verb" && echo "`date` waiting for max jobs $max ..."
        statcnt=0
        while [ : ]
        do
            if [ `jobs 2>&1 | grep -ic 'running'` -le $max ]
            then
                return 0
            fi
            let statcnt=$statcnt+1 >/dev/null 2>&1
            if [ $statcnt -eq 10 -a -n "$verb" ]
            then
                statcnt=0
                echo "`date` waiting for ..."
                ps axuww| grep 'pkg fetch' | grep -v grep | awk -F'-y ' '{print $2}'|uniq
            fi
            sleep 1
        done
}

if [ $needl -eq 1 ]
then
    for onepkg in $list
    do 
        maxjobs 8;echo $onepkg;
        pkg fetch -y $onepkg > /dev/null & 
    done
    maxjobs 0 verb
fi
if [ "$act" = 'fetch' ]
then
    echo ""
    exit 0
fi
if [ "$act" = "install" ]
then
    pkg install -y $target
    exit $?
fi
pkg $act -y
exit $?
#
EOF

chmod +x /usr/local/sbin/fastpkg

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
    fastpkg $@
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
# xauth for X11 Forward

# for rpi3 aarch64 FreeBSD 12
fastpkg install -y sudo pciutils usbutils rsync cpuflags axel git-gui wget ca_root_nss subversion pstree \
screen bind-tools pigz gtar unzip xauth mtools vim-lite

# amd64
fastpkg install -y sudo pciutils usbutils vim rsync cpuflags axel git-gui wget ca_root_nss subversion pstree \
screen bind-tools pigz gtar dot2tex unzip xauth fusefs-ntfs mtools && ln -s `which ntfs-3g` /usr/sbin/mount_ntfs-3g

# man ntfs-3g
# /usr/sbin/mount_ntfs-3g -o ro,uid=1000,gid=1000 /dev/da0s1 /mnt/msdos/
# /dev/ad4s1		/wxp		ntfs-3g	rw,uid=0,gid=0,late		0	0

#

fastpkg install -y bash-completion

#
# fix: pkg: cached package xxxx: size mismatch, cannot continue
#
# pkg update -f

#

mkdir -p /usr/local/etc/bash_completion.d

# git completion
wget --no-check-certificate https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O /usr/local/etc/bash_completion.d/git-completion.bash

# zfs completion
wget --no-check-certificate https://raw.githubusercontent.com/zfsonlinux/zfs/master/contrib/bash_completion.d/zfs -O /usr/local/etc/bash_completion.d/zfs

# devel/cpuflags

chmod +x /usr/local/bin/cpuflags

cpuflags clang

lspci

lsusb

usbconfig

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
camcontrol identify /dev/ada0

camcontrol identify /dev/ada0 | grep TRIM

gpart show ada0

# check for TRIM support in ufs
tunefs -p /dev/ada0p1

# check for TRIM support in zfs
sysctl -a | grep trim | grep 'zfs'

#
# freebsd vs linux
#
# strace / truss
# tar / gtar
# tasksel / cpuset
#

top -I -a -t -S -P

#
# amd64
cat <<EOF>> /boot/loader.conf
#
hint.apic.0.clock=0
kern.hz=100
hint.atrtc.0.clock=0
drm.i915.enable_rc6=7
hw.pci.do_power_nodriver=3
#
hint.p4tcc.0.disabled=1
hint.acpi_throttle.0.disabled=1
#
aesni_load="YES"
# wait for storage, in ms
kern.cam.boot_delay=10000
kern.cam.scsi_delay=10000
# vfs.mountroot.timeout in second
vfs.mountroot.timeout=15
#
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


# arm64
cat <<EOF>> /boot/loader.conf
#
hint.apic.0.clock=0
kern.hz=100
hint.atrtc.0.clock=0
drm.i915.enable_rc6=7
hw.pci.do_power_nodriver=3
#
hint.p4tcc.0.disabled=1
hint.acpi_throttle.0.disabled=1
#
aesni_load="YES"
# wait for storage, in ms
kern.cam.boot_delay=10000
kern.cam.scsi_delay=10000
# vfs.mountroot.timeout in second
vfs.mountroot.timeout=15
#
#
# keep system stable
# https://wiki.freebsd.org/ZFSTuningGuide
# use 3/4 of total memory
vm.kmem_size="920"
# use 1/2 of total memory
vfs.zfs.arc_max="128M"
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


cat /boot/loader.conf

#

cat <<'EOF' >> /etc/rc.conf
# kernel modules
# if_iwm for intel 3165 wifi/Intel Corporation Wireless 7265 (rev 61)
kld_list="fuse linux linux64 nmdm vmm wlan wlan_xauth wlan_ccmp wlan_tkip wlan_acl wlan_amrr wlan_rssadapt if_rtwn if_rtwn_usb if_iwm geom_uzip if_bridge bridgestp fdescfs linux linprocfs snd_driver coretemp vboxdrv"
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
dnsmasq_enable="YES"
#
#
dbus_enable="YES"
hald_enable="YES"
xdm_enable="YES"
slim_enable="YES"
gnome_enable="NO"
#
#
### http://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/firewalls-pf.html
###%### pf_enable="YES"                 # Set to YES to enable packet filter (pf)
###%### pf_rules="/etc/pf.conf"         # rules definition file for pf
###%### pf_program="/sbin/pfctl"        # where the pfctl program lives
###%### pf_flags=""                     # additional flags for pfctl
###%### pflog_enable="YES"              # Set to YES to enable packet filter logging
###%### pflog_logfile="/var/log/pflog"  # where pflogd should store the logfile
#
performance_cx_lowest="Cmax"
economy_cx_lowest="Cmax"
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
#     kld_list     (str) A list of kernel    modules    to load    right after the    local
#         disks are mounted.  Loading modules at    this point in the boot
#         process is much faster    than doing it via /boot/loader.conf
#         for those modules not necessary for mounting local disk.

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
tmpfs    /compat/linux/dev/shm    tmpfs    rw,mode=1777,late    0    0
#
EOF

# for arm*
cat <<EOF>> /etc/fstab
# for bash
fdesc /dev/fd fdescfs rw,late 0 0
proc /proc procfs rw,late 0 0

# for linux
# linproc /compat/linux/proc linprocfs rw,late 0 0
#
EOF

cat /etc/fstab

# TODO: PPPoE/ADSL WAN link

#
# dnsmasq dhcp server(with dns)
#

pkgloop install -y dnsmasq

#

cat <<'EOF'> /usr/local/etc/dnsmasq.conf
#
# port=0 to disable dns server part
#
port=53
#
no-resolv

server=8.8.8.8
server=8.8.4.4

# server=114.114.114.114
# server=8.8.8.8
# server=/google.com/8.8.8.8

# blacklist: baidu.com
address=/.baidu.com/127.0.0.1
address=/.baidustatic.com/127.0.0.1

# line 1 returns 198.51.100.100 for the host vpn.example.org.
# line 2 specifies 192.168.1.1 as the upstream DNS server for all other example.org queries such as admin.example.org.
# address=/vpn.example.org/198.51.100.100
# server=/example.org/192.168.1.1
server=/libs.baidu.com/8.8.8.8
server=/developer.baidu.com/8.8.8.8
server=/pan.baidu.com/8.8.8.8
server=/yun.baidu.com/8.8.8.8
server=/pcs.baidu.com/8.8.8.8
server=/pcsdata.baidu.com/8.8.8.8
server=/passport.baidu.com/8.8.8.8
server=/wappass.baidu.com/8.8.8.8
server=/zhidao.baidu.com/8.8.8.8

all-servers

#
log-queries
#
# enable dhcp server
#
# dhcp-range=172.16.0.91,172.16.0.110,240h
#
#
log-dhcp
#
#
# no-dhcp-interface=em0
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
# # tftp options
# #
# # For each device you want to TFTP boot, you need a dhcp-host entry with the MAC address and the IP to give that client. 
# # You'll need to look up the MAC address of the device and add a line here for it to be recognized.
# dhcp-host=d4:ca:6d:a5:84:7e,192.168.10.101
# 
# # The name of the boot file to be provided to dhcp-hosts. This file should be saved in the 'tftp-root' folder (see below)
# dhcp-boot=vmlinux
# 
# # Enable dnsmasq's built in tftp/bootp server
# enable-tftp
# 
# # Designate where TFTP/BOOTP files will be served from on this server
# tftp-root=/no-exist-tftproot
# log-queries
# log-dhcp
#
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
!dnsmasq-tftp
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
# or
# chflags 0 /etc/resolv.conf

#

/usr/local/etc/rc.d/dnsmasq restart

sleep 1 && tail -n 20 /var/log/messages

#### ------------------------

# on boot startup
# check /etc/rc.local
#

cat <<'EOF' > /sbin/liverootfs.sh
#!/bin/sh
rootds=`mount | grep " on / (zfs,"| tail -n 1| awk '{print $1}'`
if [ -z "$rootds" ]
then
    echo "error: root dataset not found"
    mount
    exit 1
fi
zfs destroy -r $rootds@-live- 2>/dev/null
umount -f /mnt/liverootfs 2>/dev/null
zfs snapshot $rootds@-live- && mkdir -p /mnt/liverootfs && \
mount -t zfs -o ro $rootds@-live- /mnt/liverootfs
if [ $? -ne 0 ]
then
    echo "error: mount -t zfs -o ro $rootds@-live- /mnt/liverootfs failed"
    exit 1
fi
mount | grep -- " on / (zfs,"
mount | grep -- "$rootds@-live-"
exit 0
#


EOF

chmod +x /sbin/liverootfs.sh

cat <<'EOF' > /sbin/ss-start.sh
#!/bin/sh
SSHOST1="168.235.xx.8"
SSHOST2="202.5.xx.245"
SSHOST3="192.xx.180.94"
if [ `id -u` -ne 0 ]
then
        echo " - sudo:"
        sudo $0 $@
        exit $?
fi
#
cd ${HOME} || exit 1

rm -f ${HOME}/ss-*.core

killall ss-tunnel 2>/dev/null
killall ss-local 2>/dev/null

sleep 1

SSHOST="${SSHOST1}"
if [ "$1" = '1' ]
then
    SSHOST="${SSHOST1}"
fi

if [ "$1" = '2' ]
then
    SSHOST="${SSHOST2}"
fi

if [ "$1" = '3' ]
then
    SSHOST="${SSHOST3}"
fi

nohup /usr/local/bin/ss-tunnel -s ${SSHOST} -p 9394 -l 8053 -b 127.0.0.1 -t 30 -k ss-password -m chacha20 -L 8.8.8.8:53 -u -v < /dev/zero >/var/log/ss-dns.log 2>&1 &
sleep 1
nohup /usr/local/bin/ss-local -s ${SSHOST} -p 9394 -l 8080 -b 0.0.0.0 -t 30 -k ss-password -m chacha20 -v < /dev/zero >/var/log/ss-local.log 2>&1 &
sleep 1
sockstat -l | grep udp | grep ss| head -n3
sockstat -l | grep tcp | grep ss| head -n3
sleep 1
ps axuww| grep -- '/usr/local/bin/ss-'
service dnsmasq restart
EOF

chmod +x /sbin/ss-start.sh

pkg install -y hostapd pciutils usbutils

#

dmesg | grep -C 10 -i wlan

lspci && usbconfig list && lsusb

# rtwn0: MAC/BBP RT3070 (rev 0x0201), RF RT3020 (MIMO 1T1R), address 10:6f:3f:2c:09:fb

#
# 03:00.0 Network controller: Qualcomm Atheros AR928X Wireless Network Adapter (PCI-Express) (rev 01)
# using AR9280

ifconfig wlan1 create wlandev rtwn1 wlanmode hostap up

ifconfig wlan1 list caps

ifconfig wlan1 list caps | grep -i hostap

# drivercaps=4f8def41<STA,FF,IBSS,PMGT,HOSTAP,AHDEMO,TXPMGT,SHSLOT,SHPREAMBLE,MONITOR,MBSS,WPA1,WPA2,BURST,WME,WDS,TXFRAG>
# cryptocaps=1f<WEP,TKIP,AES,AES_CCM,TKIPMIC>
# htcaps=701ce<CHWIDTH40,SHORTGI40,TXSTBC>
#
# you need HOSTAP + TKIP
#

# NOTE: TKIP is faster then CCMP

cat <<'EOF' > /etc/hostapd.conf
#
# https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf
#
interface=wlan1
driver=bsd
#
# SSID to be used in IEEE 802.11 management frames
ssid=tutux-136-mini
wpa_passphrase=13609009086

# Country code (ISO/IEC 3166-1).
country_code=US

# Operation mode (a = IEEE 802.11a, b = IEEE 802.11b, g = IEEE 802.11g)
hw_mode=g
channel=11

wpa=2
wpa_key_mgmt=WPA-PSK

# NOTE: TKIP is faster then CCMP
#wpa_pairwise=TKIP CCMP
wpa_pairwise=TKIP
ctrl_interface=/var/run/hostapd
ctrl_interface_group=wheel
#
# Levels (minimum value for logged events):
#  0 = verbose debugging
#  1 = debugging
#  2 = informational messages
#  3 = notification
#  4 = warning
#
logger_syslog=0
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2
#
EOF


# aarch64 autoload kmod disabled?
kmods="wlan wlan_xauth wlan_ccmp wlan_tkip wlan_acl wlan_amrr wlan_rssadapt"
for onemod in $kmods
do
    /sbin/kldload $onemod 2>/dev/null
done
kldstat|grep wlan

hostapd -d /etc/hostapd.conf

#

cat <<'EOF' >> /etc/rc.conf
#
hostapd_enable="YES"
#
gateway_enable="YES"
#
#
EOF

#

#
# SNAT firewall
#

cat <<'EOF' > /etc/pf.conf
#
# simple pf
#
#------------------------------------------------------------------------
# macros
#------------------------------------------------------------------------
#
# interfaces
ext_if  = "wlan0"
ext_vpn_if  = "ng0"
lan_if = "bridge0"

skipped_if = "{ lo }"

# Transparent Proxy
http_port = "80"
cache_host = "127.0.0.1"
cache_port = "9080"

dns_port = "53"
dnscache_host = "127.0.0.1"
dnscache_port = "53"

#------------------------------------------------------------------------
# options
#------------------------------------------------------------------------
# config
set block-policy return
set loginterface $ext_if
set loginterface $ext_vpn_if
set skip on $skipped_if
set state-policy if-bound

# scrub
scrub all reassemble tcp no-df
scrub in all fragment reassemble
scrub out all random-id

#------------------------------------------------------------------------
# redirection (and nat, too!)
#------------------------------------------------------------------------
# network address translation

# for pptp/gre
# no nat on $ext_if proto gre from any to any
# no nat on $ext_vpn_if proto gre from any to any

nat on $ext_if inet from ! ($ext_if) to any -> ($ext_if)
nat on $ext_vpn_if inet from ! ($ext_vpn_if) to any -> ($ext_vpn_if)

# redirect only IPv4 web traffic to squid 
#rdr pass on $lan_if inet proto tcp from any to any port $http_port -> $cache_host port $cache_port

# redirect dns traffic to local dnsmasq 
rdr pass on $lan_if inet proto tcp from any to any port $dns_port -> $dnscache_host port $dnscache_port

#------------------------------------------------------------------------
# firewall policy
#------------------------------------------------------------------------
# default pass
pass in quick from any to any
pass out quick from any to any
#
EOF

#

cat <<'EOF'> /usr/sbin/pfsess
#!/bin/sh
#
# check kmod of pf
#

kldload pf
kldload pflog

pfctl -e
# pf enabled

echo "/etc/pf.conf"
pfctl -vnf /etc/pf.conf

echo ""
errcode=0
if [ "$1" = "stop" -o "$1" = "start" ]
then
    sysctl -w net.inet.ip.forwarding=0
    pfctl -F nat && pfctl -F queue && pfctl -F rules
    errcode=$?
    sleep 1 
fi
if [ "$1" = "start" ]
then
    sysctl -w net.inet.ip.forwarding=1
    pfctl -f /etc/pf.conf
    errcode=$?
    sleep 1 
fi
#
echo "pf state"
pfctl -s rules && pfctl -s nat && pfctl -s state
#
exit $errcode
#
EOF

chmod +x /usr/sbin/pfsess

# for all
cat <<'EOF' > /sbin/netmgr.sh
#!/bin/sh

. /etc/initz.network.conf

# for wlan0
WIFICLIENTIF="wlan0"
# for wlan1, softap
SOFTAPIF="wlan1"

BRIDGEIF="bridge0"

# YES to add wifi client to bridge
CLIENTBRIDGE="NO"

#
CLIENTDHCP="YES"

# load wlan kmods
kmods="wlan wlan_xauth wlan_ccmp wlan_tkip wlan_acl wlan_amrr wlan_rssadapt"
for onemod in $kmods
do
    /sbin/kldload $onemod 2>/dev/null
done
# kldstat|grep wlan

wired_reset(){
    service sshd start
    ifconfig $BRIDGEIF destroy 2>/dev/null
    sleep 1
    service netif stop
    sleep 1
    service netif start
    #
    local allnic=""
    local addms=""
    local nic=""
    local nicflags=$LAN_NICS
    if [ "$nicflags" = "AUTO" -o "$nicflags" = "AUTOX" ]
    then
        LAN_NICS=`ifconfig -a | grep ": flags=" | tr ':' ' '| awk '{print $1}'| grep -v ^lo | grep -v ^bridge| grep -v ^pf`
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
    done
    if [ -z "$addms" -o "$addms" = "x" ]
    then
        echo "warning: LAN_NICS not found or not defined($nicflags)."
        return 0
    fi
    #
    /sbin/ifaceboot $BRIDGEIF $addms
    local addr=""
    local alias=""
    for addr in $LAN_ADDRS
    do
        /sbin/ifconfig $BRIDGEIF $addr $alias
        alias="alias"
    done
    test -n "$WAN_GW" && route add -net 0/0 $WAN_GW
    echo " ----"
    sleep 1
    ifconfig
    netstat -nr
    echo " ----"
    echo "wired networking reseted."
    echo " ----"
}

wifi_client(){
    local arg1="$1"
    local code=0
    # sleep to prevent panic
    killall wpa_supplicant 2>/dev/null
    sleep 1
    ifconfig $WIFICLIENTIF destroy 2>/dev/null
    sleep 1
    if [ "$arg1" = "stop" ]
    then
        return $?
    fi
    test -z "$WIFICLIENTNIC" && echo "device for wifi client (WIFICLIENTNIC) not defined" && return 0
    /sbin/ifaceboot $WIFICLIENTIF $WIFICLIENTNIC wlanmode sta up
    /sbin/ifconfig $WIFICLIENTIF >/dev/null 2>&1
    test $? -ne 0 && echo "FAILED: $WIFICLIENTIF $WIFICLIENTNIC wlanmode sta up" && return 1
    sleep 1 && /sbin/ifconfig $WIFICLIENTIF txpower 30
    /sbin/ifconfig $WIFICLIENTIF up
    sleep 1
    /usr/sbin/wpa_supplicant -B -i $WIFICLIENTIF -c /etc/wpa_supplicant.conf
    echo ""
    echo "waiting for $WIFICLIENTIF(90 seconds) ..."
    for aaa in `seq 1 90`
    do
        ifconfig $WIFICLIENTIF | grep -q 'status: associated'
        test $? -eq 0 && break
        sleep 1
    done
    echo " ----"
    echo -n "WIFI CLIENT CONNECTED: " && ifconfig $WIFICLIENTIF | grep "ssid "
    echo " ----"
    ifconfig $WIFICLIENTIF
    if [ "$CLIENTBRIDGE" = "YES" ]
    then
        sleep 1
        /sbin/ifconfig $WIFICLIENTIF up 
        sleep 3
        /sbin/ifconfig $BRIDGEIF addm $WIFICLIENTIF
        sleep 1
        if [ "$CLIENTDHCP" = "YES" ]
        then
            dhclient $BRIDGEIF
        fi
    else
        if [ "$CLIENTDHCP" = "YES" ]
        then
            dhclient $WIFICLIENTIF
        fi
    fi
    #
    /sbin/ifconfig $WIFICLIENTIF
    /sbin/ifconfig $BRIDGEIF
    service dnsmasq restart
    netstat -nr
    #
    /usr/sbin/pfsess start > /dev/null
    #
    return $?
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
    if [ "$arg1" = "stop" ]
    then
        return $?
    fi
    test -z "$SOFTAPNIC" && echo "device for softap (SOFTAPNIC) not defined" && return 0
    /sbin/ifaceboot $SOFTAPIF $SOFTAPNIC wlanmode hostap
    /sbin/ifconfig $SOFTAPIF >/dev/null 2>&1
    test $? -ne 0 && echo "FAILED: $SOFTAPIF $SOFTAPNIC wlanmode hostap" && return 1
    sleep 1 && /sbin/ifconfig $SOFTAPIF txpower 30
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
    /sbin/ifconfig $BRIDGEIF addm $SOFTAPIF
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
    /sbin/ifconfig $BRIDGEIF
    return $code
}

if [ -z "$1" ]
then
    wired_reset start
    soft_ap start
    wifi_client start
    exit $?
fi

if [ "$1" = "stop" ]
then
    soft_ap stop
    wifi_client stop
    wired_reset stop
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
    wifi_client start
    exit $?
fi
#

EOF

chmod +x /sbin/netmgr.sh

# anti-gfw 
pkgloop install -y shadowsocks-libev proxychains-ng && \
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
socks5     127.0.0.1 8080
#
EOF

#


# create
test -f /etc/rc.local && mv /etc/rc.local /etc/rc.local.orig.$$

# NOTE: overwrite

cat <<'EOF' > /etc/rc.local
#!/bin/sh

# aarch64 bug
# test "`uname -p`" = "aarch64" && killall syslogd 2>/dev/null

# mount live root
/sbin/liverootfs.sh $@

/sbin/netmgr.sh $@
/sbin/ss-start.sh
/sbin/netmgr.sh softap stop

EOF

chmod +x /etc/rc.local

# for n550jk
cat <<'EOF' > /etc/initz.network.conf

# LAN_ADDRS="172.18.0.254/24 172.16.0.254/24"
LAN_ADDRS="172.16.0.3/24"
# AUTOX to skip first ether nic
LAN_NICS="AUTO"
WAN_GW="172.16.0.254"

# SOFTAPNIC="rtwn1"

# WIFICLIENTNIC="rtwn0"

EOF

# for pi3
cat <<'EOF' > /etc/initz.network.conf

# LAN_ADDRS="172.18.0.254/24 172.16.0.254/24"
LAN_ADDRS="172.16.0.254/24"
# AUTOX to skip first ether nic
LAN_NICS="AUTO"
# WAN_GW="172.16.0.254"

SOFTAPNIC="rtwn1"

WIFICLIENTNIC="rtwn0"

EOF

#
# UTF-8
#

locale -a

# https://fcitx-im.org/wiki/Configure_(Other)

#
# https://www.b1c1l1.com/blog/2011/05/09/using-utf-8-unicode-on-freebsd/
#
grep -q 'LC_COLLATE=C' /etc/login.conf
if [ $? -ne 0 ]
then
cat <<'EOF' > /tmp/utf8.patch
--- /etc/login.conf.orig_TAB_2016-06-01 19:36:34.034145000 +0800
+++ /etc/login.conf_TAB_2016-06-01 19:40:12.960218000 +0800
@@ -26,7 +26,7 @@
 _TAB_:passwd_format=sha512:\
 _TAB_:copyright=/etc/COPYRIGHT:\
 _TAB_:welcome=/etc/motd:\
-_TAB_:setenv=MAIL=/var/mail/$,BLOCKSIZE=K:\
+_TAB_:setenv=MAIL=/var/mail/$,BLOCKSIZE=K,LC_COLLATE=C:\
 _TAB_:path=/sbin /bin /usr/sbin /usr/bin /usr/local/sbin /usr/local/bin ~/bin:\
 _TAB_:nologin=/var/run/nologin:\
 _TAB_:cputime=unlimited:\
@@ -46,7 +46,9 @@
 _TAB_:umtxp=unlimited:\
 _TAB_:priority=0:\
 _TAB_:ignoretime@:\
-_TAB_:umask=022:
+_TAB_:umask=022:\
+_TAB_:charset=UTF-8:\
+_TAB_:lang=en_US.UTF-8:
 
 
 #
EOF

ttt=`echo -e -n "\t"`

sed -i -e "s#_TAB_#$ttt#g" /tmp/utf8.patch && patch -p0 < /tmp/utf8.patch
sed -i -e 's#:setenv=MAIL=/var/mail/$,BLOCKSIZE=K:\\#:setenv=MAIL=/var/mail/$,BLOCKSIZE=K,LC_COLLATE=C:\\#g' /etc/login.conf

fi

cap_mkdb /etc/login.conf

su -

locale

### LANG=en_US.UTF-8
### LC_CTYPE="en_US.UTF-8"
### LC_COLLATE=C
### LC_TIME="en_US.UTF-8"
### LC_NUMERIC="en_US.UTF-8"
### LC_MONETARY="en_US.UTF-8"
### LC_MESSAGES="en_US.UTF-8"
### LC_ALL=
### 

#

cp -a /etc/profile /etc/profile.orig.$$

# NOTE: overwrite
cat <<'EOF' > /etc/profile
#!/bin/sh
# $FreeBSD: head/etc/profile 208116 2010-05-15 17:49:56Z jilles $
#
# System-wide .profile file for sh(1).
#
# Uncomment this to give you the default 4.2 behavior, where disk
# information is shown in K-Blocks
# BLOCKSIZE=K; export BLOCKSIZE
#
# For the setting of languages and character sets please see
# login.conf(5) and in particular the charset and lang options.
# For full locales list check /usr/share/locale/*
# You should also read the setlocale(3) man page for information
# on how to achieve more precise control of locale settings.
#
# Check system messages
# msgs -q
# Allow terminal messages
# mesg y

#
# default
#

export GTK_IM_MODULE=fcitx
export GTK3_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/games:/usr/local/games"

#
# FreeBSD does not use follow setting ?
#
# LC_PAPER=en_US.UTF-8
# LC_ADDRESS=en_US.UTF-8
# LC_TELEPHONE=en_US.UTF-8
# LC_IDENTIFICATION=en_US.UTF-8
# LC_MEASUREMENT=en_US.UTF-8
# LC_NAME=en_US.UTF-8
#
EOF

source /etc/profile && locale

# convert GBK filename to utf-8
# http://unix.stackexchange.com/questions/290713/how-to-convert-gbk-to-utf-8-in-a-mixed-encoding-directory
# http://edyfox.codecarver.org/html/linux_gbk2utf8.html

pkg install -y convmv

# convmv -f gbk -t utf8 *
# convmv -r -f gbk -t utf-8 --notest *

#
# http://yaws.hyber.org/privbind.yaws
# http://crossbar.io/docs/Running-on-privileged-ports/
# binding to privileged ports
# net.inet.ip.portrange.reservedhigh
#

echo 'net.inet.ip.portrange.reservedlow=0' >> /etc/sysctl.conf
echo 'net.inet.ip.portrange.reservedhigh=1023' >> /etc/sysctl.conf

#

# seafile-server in http
# https://manual.seafile.com/deploy/using_sqlite.html
# https://manual.seafile.com/build_seafile/freebsd.html
# https://thebluber.wordpress.com/2015/04/21/install-seafile-server-seahub-on-freebsd/

# install by root

pkg search seafile

sudo pkg install -y seafile-client seafile-gui seafile-server seahub

ls -alh /usr/local/www/haiwen/seafile-server/

mkdir -p /home/david/ds/nzhomeseafile/seafile-data

# run by root for ccnet

sudo /usr/local/www/haiwen/seafile-server/setup-seafile.sh

# rhinofly@s1:~/palfish/seafile-server-6.0.9$ ./setup-seafile.sh 
# -----------------------------------------------------------------
# This is your config information:
# 
# server name:        nzhome
# server ip/domain:   nzhome.cloud.newhamlet.com
# seafile data dir:   /home/david/ds/nzhomeseafile/seafile-data
# fileserver port:    8082
# 
# If you are OK with the configuration, press [ENTER] to continue.
# 
# Generating ccnet configuration in /usr/local/www/haiwen/ccnet...
# 
# done
# Successly create configuration dir /usr/local/www/haiwen/ccnet.
# 
# Generating seafile configuration in /home/david/ds/nzhomeseafile/seafile-data ...
# 
# Done.
# 
# -----------------------------------------------------------------
# Seahub is the web interface for seafile server.
# Now let's setup seahub configuration. Press [ENTER] to continue
# -----------------------------------------------------------------
# 
# creating seafile-server-latest symbolic link ... done
# 
# 
# -----------------------------------------------------------------
# Your seafile server configuration has been completed successfully.
# -----------------------------------------------------------------
# 
# run seafile server:     sysrc seafile_enable=YES
#                         service seafile { start | stop | restart }
# run seahub  server:     sysrc seahub_enable=YES
# fastcgi (optional):     sysrc seahub_fastcgi=1
#                         service seahub { start | stop | restart }
# run reset-admin:        ./reset-admin.sh
# 
# -----------------------------------------------------------------
# If the server is behind a firewall, remember to open these tcp ports:
# -----------------------------------------------------------------
# 
# port of seafile fileserver:   8082
# port of seahub:               8000
# 
# When problems occur, refer to
# 
#       https://github.com/haiwen/seafile/wiki
# 
# for more information.
# 

### use fast-cgi server with nginx
sudo sysrc seafile_enable=YES
sudo sysrc seahub_enable=YES
sudo sysrc seahub_fastcgi=YES

cat <<'EOF'> /tmp/nzhome.cloud.newhamlet.com.conf
server {
    # http server
    listen 8001;
    
    server_name nzhome.cloud.newhamlet.com;

    charset utf-8;

    access_log  /var/log/nginx/http.nzhome.cloud.newhamlet.com.access.log  main;
    error_log       /var/log/nginx/nzhome.seahub.error.log;

    root /usr/local/empty;
    index index.html;

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    location ~ /\.ht {
        deny  all;
    }
    location ^~ /data/ {
        deny  all;
    }
    
    proxy_set_header X-Forwarded-For $remote_addr;

    server_tokens off;
    
    location / {
            fastcgi_pass    127.0.0.1:8000;
            fastcgi_param   SCRIPT_FILENAME     $document_root$fastcgi_script_name;
            fastcgi_param   PATH_INFO           $fastcgi_script_name;

            fastcgi_param   SERVER_PROTOCOL        $server_protocol;
            fastcgi_param   QUERY_STRING        $query_string;
            fastcgi_param   REQUEST_METHOD      $request_method;
            fastcgi_param   CONTENT_TYPE        $content_type;
            fastcgi_param   CONTENT_LENGTH      $content_length;
            fastcgi_param   SERVER_ADDR         $server_addr;
            fastcgi_param   SERVER_PORT         $server_port;
            fastcgi_param   SERVER_NAME         $server_name;
            fastcgi_param   REMOTE_ADDR         $remote_addr;
            #fastcgi_param   HTTPS               on;
            #fastcgi_param   HTTP_SCHEME         https;

            fastcgi_read_timeout 36000;
            client_max_body_size 0;
    }
    location /seafhttp {
        rewrite ^/seafhttp(.*)$ $1 break;
        proxy_pass http://127.0.0.1:8082;
        client_max_body_size 0;
        proxy_connect_timeout  36000s;
        proxy_read_timeout  36000s;
        proxy_send_timeout  36000s;
        send_timeout  36000s;
    }
    location /media {
        root /usr/local/www/haiwen/seafile-server-latest/seahub;
    }
}
EOF

sudo cp /tmp/nzhome.cloud.newhamlet.com.conf /usr/local/etc/nginx/conf.d/nzhome.cloud.newhamlet.com.conf

sudo service nginx restart

sockstat -l -4| grep 8001

service seafile start
service seahub start

# access
http://nzhome.cloud.newhamlet.com:8001

# server config
# https://manual-cn.seafile.com/config/

cd /home/david/ds/nzhomeseafile/

# NOTE: appending
cat <<'EOF' >>/usr/local/www/haiwen/conf/seahub_settings.py
# email notify
EMAIL_USE_TLS = False
EMAIL_HOST = '127.0.0.1'
EMAIL_HOST_USER = 'seafile-notify@nzhome.cloud.newhamlet.com'
# no auth
EMAIL_HOST_PASSWORD = ''
EMAIL_PORT = '25'
DEFAULT_FROM_EMAIL = EMAIL_HOST_USER
SERVER_EMAIL = EMAIL_HOST_USER
#
FILE_SERVER_ROOT = 'http://nzhome.cloud.newhamlet.com/seafhttp'
#
# Enalbe or disalbe registration on web. Default is `False`.
ENABLE_SIGNUP = True

# Activate or deactivate user when registration complete. Default is `True`.
# If set to `False`, new users need to be activated by admin in admin panel.
ACTIVATE_AFTER_REGISTRATION = False

# Whether to send email when a system admin adding a new member. Default is `True`.
# NOTE: since version 1.4.
SEND_EMAIL_ON_ADDING_SYSTEM_MEMBER = True

# Attempt limit before showing a captcha when login.
LOGIN_ATTEMPT_LIMIT = 3

# Whether a user's session cookie expires when the Web browser is closed.
SESSION_EXPIRE_AT_BROWSER_CLOSE = False

EOF

# NOTE: overwrite
# https://manual.seafile.com/config/seafile-conf.html
cat <<'EOF' >/usr/local/www/haiwen/conf/ccnet.conf 
[General]
USER_NAME = nzhome
ID = 3fd76645bd6f949326582fcea4ae256bd42dcbdd
NAME = nzhome
# from nginx 8001
SERVICE_URL = http://nzhome.cloud.newhamlet.com:8001

[Client]
PORT = 13419

EOF

# NOTE: overwrite
# https://manual.seafile.com/config/seafile-conf.html
cat <<'EOF' >/usr/local/www/haiwen/conf/seafile.conf 
[fileserver]
port=8082
host=127.0.0.1
EOF

/usr/local/www/haiwen/seafile-server/reset-admin.sh

### end of seafile-server


# ssh remote forward
# https://help.ubuntu.com/community/SSH/OpenSSH/PortForwarding
# need GatewayPorts yes in /etc/ssh/sshd_config for 0.0.0.0:8822
# ssh -f -N -n -T -R 0.0.0.0:8822:10.236.150.26:22 public-ssh-server
# ssh -f -N -n -T -R 0.0.0.0:9922:10.236.150.21:22 public-ssh-server
