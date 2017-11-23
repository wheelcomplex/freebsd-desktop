#
# install 
#
# ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/amd64/amd64/ISO-IMAGES/11.0/FreeBSD-11.0-CURRENT-amd64-20151229-r292858-memstick.img
#
# initial pkg
#

# privacy protect
echo '127.0.0.1 pos.baidu.com' >> /etc/hosts

#
# use sh for rsync
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
    local exitcode=0
    # slog "bridge_creator $ifname ..."
    echo "$ifname" | grep -q 'bridge[0-9]*' || return 127
    ${IFCONFIG_CMD} "${ifname}" 2>/dev/null
    if [ $? -ne 0 ]; then
        $IFCONFIG_CMD ${ifname} create 2>&1 | pipelog
        exitcode=${PIPESTATUS[0]}
        test $exitcode -ne 0 && slog "create $ifname failed" && return $exitcode
    fi
    return 0
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
screen bind-tools pigz gtar dot2tex unzip xauth fusefs-ntfs mtools mountsmb2 && ln -s `which ntfs-3g` /usr/sbin/mount_ntfs-3g

# man ntfs-3g
# /usr/sbin/mount_ntfs-3g -o ro,uid=1000,gid=1000 /dev/da0s1 /mnt/msdos/
# /dev/ad4s1		/wxp		ntfs-3g	rw,uid=0,gid=0,late		0	0

# list windows shares
smbclient -I 172.16.254.41 -Udavid -L 172.16.254.41
# 
# Enter david's password: 
# Domain=[DESKTOP-OOHVMSR] OS=[Windows 10 Education 10586] Server=[Windows 10 Education 6.3]
# 
# 	Sharename       Type      Comment
# 	---------       ----      -------
# 	ADMIN$          Disk      远程管理
# 	C$              Disk      默认共享
# 	D$              Disk      默认共享
# 	IPC$            IPC       远程 IPC
# 	winshare        Disk      win10 for david

# mount
sudo mount_smbfs -T 5 -I 172.16.254.41 -Udavid //david@DESKTOP-U6M9VA0/winshare /mnt/tmp

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
# http://www.freshports.org/graphics/drm-next-kmod
pkg install -yf drm-next-kmod

cat <<'EOF' >> /etc/rc.conf
# kernel modules
# if_iwm for intel 3165 wifi/Intel Corporation Wireless 7265 (rev 61)
kld_list="/boot/modules/i915kms.ko fuse linux linux64 nmdm vmm wlan wlan_xauth wlan_ccmp wlan_tkip wlan_acl wlan_amrr wlan_rssadapt if_rtwn if_rtwn_usb if_iwm geom_uzip if_bridge bridgestp fdescfs linux linprocfs snd_driver coretemp vboxdrv"
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
# log-queries
#
# enable dhcp server
#
# dhcp-range=172.16.0.91,172.16.0.110,240h
#
#

#
# dhcp for vm console
dhcp-range=vmcon,172.16.254.1,172.16.254.100,20h
# option 3, default gateway
dhcp-option=vmcon,3
# option 6, dns server
dhcp-option=vmcon,6
# option 15, domain-name
dhcp-option=vmcon,15,vmconsole.localdomain

# dhcp for vm nat
dhcp-range=172.16.253.1,172.16.253.100,20h

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

if [ `id -u` -ne 0 ]
then
    echo "sudo ..."
    sudo $0 $@
    exit $?
fi

rootds=`mount | grep " on / (zfs,"| tail -n 1| awk '{print $1}'`
if [ -z "$rootds" ]
then
    echo "error: root dataset not found"
    mount
    exit 1
fi
export MK_TAG

if [ -z "$MK_TAG" ]
then
    MK_TAG="`date +%Y%m%d%H%M%S`-liverootfs"
fi
fs=$rootds@${MK_TAG}
umount -f /mnt/liverootfs 2>/dev/null
zfs snapshot $fs && mkdir -p /mnt/liverootfs && \
mount -t zfs -o ro $fs /mnt/liverootfs
if [ $? -ne 0 ]
then
    echo "error: mount -t zfs -o ro $fs /mnt/liverootfs failed"
    exit 1
fi
mount | grep -- " on / (zfs,"
mount | grep -- "$fs"
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
ext_vpn_if  = "bridge0"
lan_if = "bridge8191"

skipped_if = "{ lo bridge8192 }"

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
# rdr pass on $lan_if inet proto tcp from any to any port $dns_port -> $dnscache_host port $dnscache_port

#------------------------------------------------------------------------
# firewall policy
#------------------------------------------------------------------------
# default pass
pass in quick from any to any
pass out quick from any to any
#

EOF

#

# dynamic gateway

cat <<'EOF' > /etc/pf.conf
#
# simple pf
#

# interfaces
ext_if  = "wlan0"

workvm = "172.16.253.254"

# skipped_if = "{ lo bridge8192 }"
skipped_if = "{ lo }"

#

include "/etc/pf.dyn.conf"

include "/etc/pf.rdr.conf"

#------------------------------------------------------------------------
# options
#------------------------------------------------------------------------
# config
set block-policy return
set loginterface $ext_if
set skip on $skipped_if
set state-policy if-bound

# scrub
scrub in on $ext_if all

#rdr
pass in on $ext_if proto tcp from ! ($ext_if) to egress port 3389 rdr-to $workvm

# nat
nat on $ext_if inet from ! ($ext_if) to any -> ($ext_if)

# default pass
pass in quick from any to any
pass out quick from any to any
#
EOF

#

cat <<'EOF' > /etc/pf.rdr.conf
workvm = "127.0.0.1"
EOF

cat <<'EOF'> /usr/sbin/pfsess
#!/bin/sh
#
# check kmod of pf
#

GWNIC=`netstat -nr -4 | grep default | awk '{print $4}'| head -n 1`

if [ -z "$GWNIC" ]
then
    echo "ERROR: GATEWAY NOT FOUND"
    GWNIC=wlan99
fi

echo "GATEWAY DEVICE: $GWNIC"
echo "ext_if  = $GWNIC" > /etc/pf.dyn.conf || exit 1

pfctl -vnf /etc/pf.conf

kldload pf 2>/dev/null
kldload pflog 2>/dev/null

echo ""
errcode=0

pfctl -d  >/dev/null 2>&1

sysctl -w net.inet.ip.forwarding=0 >/dev/null
pfctl -F nat >/dev/null 2>&1 && pfctl -F queue >/dev/null 2>&1 && pfctl -F rules >/dev/null 2>&1
errcode=$?
sleep 1 
if [ "$1" = "stop" ]
then
    exit $errcode
fi

sysctl -w net.inet.ip.forwarding=1 >/dev/null
pfctl -e  >/dev/null 2>&1
# pf enabled

#
pfctl -f /etc/pf.conf >/dev/null
errcode=$?
#
echo "pf state"
pfctl -s rules && echo "" && pfctl -s nat
# && echo "" && pfctl -s state
echo ""
#
exit $errcode
#

EOF

chmod +x /usr/sbin/pfsess

# for all
cat <<'EOF' > /sbin/netmgr.sh
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

EOF

chmod +x /sbin/netmgr.sh

# David note: make sure dhcp works on ap bridge

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
# WAN_GW="172.16.0.254"

SOFTAPNIC="ath0"

WIFICLIENTNIC="AUTO"

BRIDGEIF="bridge8191"

SOFTAPTXPOWER="5"

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

# nginx web server + proxy

fastpkg install -y nginx


cat <<'EOF'>/usr/share/nginx/html/robots.txt
Disallow: /
EOF

# using www-data

cat <<'EOF' > /etc/nginx/nginx.conf 
#
user  www-data;
worker_processes  2;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$scheme://$http_host$request_uri" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
EOF

mkdir -p /etc/nginx/ssl

# for letsencrypt
mkdir -p /usr/share/nginx/html/.well-known

# all server

cat <<'EOF'> /etc/nginx/conf.d/default.conf
server {
        # http2 server
        listen 443 ssl http2 default_server;
        listen [::]:443 ssl http2 default_server;
        
        server_name _;
        
        ssl_certificate /etc/letsencrypt/live/david.city/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/david.city/privkey.pem;
        
        ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
        
        ssl_dhparam  /etc/nginx/ssl/dhparam.pem;
        
        ssl_session_cache shared:SSL:5m;
        
        ssl_session_timeout 1h;

        charset utf-8;

        access_log  /var/log/nginx/ssl.access.log  main;

        add_header Strict-Transport-Security "max-age=15768000; includeSubDomains: always;";

       location / {
           root   /usr/share/nginx/html;
           index  index.html index.htm;
       }

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    
        access_log  /var/log/nginx/http.access.log  main;

        # redirect http requests to https
        location / {
            # uncomment return 301 after letencrypto setup ok
            # should be http_host instead of server_name.
            return         301 https://$http_host$request_uri;
            root   /usr/share/nginx/html;
            # index  index.html index.htm;
        }
        # for letsencrypt
        location ~ /.well-known {
            root   /usr/share/nginx/html;
            allow all;
        }
}
EOF

nginx -t && service nginx restart


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


#
# install 
#
# ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/amd64/amd64/ISO-IMAGES/11.0/FreeBSD-11.0-CURRENT-amd64-20151229-r292858-memstick.img
#

# https://cooltrainer.org/a-freebsd-desktop-howto/

#
# TODO: check https://www.banym.de/freebsd/install-freebsd-11-on-thinkpad-t420
#

# date format: %R %a %d-%m-%Y

#
# install desktop
#

# mini X

fastpkg install -y git-gui meld  pinentry-curses pinentry-tty geany jpeg-turbo xv rdesktop xpdf zh-xpdf-zhfont gnome-screenshot

# http://www.pc-freak.net/blog/how-to-take-area-screenshots-in-gnome-take-quick-area-selection-screenshots-in-g-linux-and-bsd/

fastpkg install -y virt-viewer chromium firefox-esr openjdk icedtea-web

# for aarch64
allxfce4=`export ABI=FreeBSD:11:aarch64;pkg search xfce | grep '^xfce' | awk '{print $1}'`;
fastpkg install -y git-gui meld  pinentry-curses pinentry-tty geany jpeg-turbo xv rdesktop xpdf zh-xpdf-zhfont virt-viewer firefox-esr $allxfce4


# for armv6 rpi2
# fastpkg install -y git-gui meld pinentry-curses pinentry-tty geany jpeg-turbo xv

#
# https://www.freebsd.org/doc/handbook/x11.html
#

# for amd64

# pkgloop is alias/script of pkg

allxfce4=`pkg search xfce | grep '^xfce' | awk '{print $1}'`

echo $allxfce4

# zh-fcitx-googlepinyin

pkgloop install -y ${allxfce4} xorg xf86-video-scfb xdm slim xlockmore zh-fcitx zh-fcitx-cloudpinyin \
zh-fcitx-table-extra zh-fcitx-configtool gnome-desktop xf86-video-intel

# libreoffice or apache-openoffice
pkgloop install -y virtualbox-ose virtualbox-ose-kmod virtualbox-ose-additions libreoffice noto

# virtualbox-ose-additions virtualbox-ose-kmod

# for fcitx
fastpkg remove -y ibus gnome-session

#
# install virtualbox from ports
# get list from make missing in /usr/ports/emulators/virtualbox-ose

# https://forums.freebsd.org/threads/13883/
## 
## And if you mean "which port depends on which ports", either run pkg_info -rR <portglob> for an installed port, 
## or run make build-depends-list && make run-depends-list in a port directory under /usr/ports. 
## 
## Finally: if you wonder which dependencies you still need to install for a port, run make missing in a port directory under /usr/ports.
## 

fastpkg install patch zip yasm pkgconf gsoap dejagnu expect xorg-macros libcheck xcb-proto makedepend libclc py27-markupsafe py27-babel py27-pytz \
py27-docutils py27-pytest py27-mock py27-pbr py27-pip py27-pytest-capturelog py27-pytest-timeout py27-pytest-xdist py27-setuptools_scm \
py27-execnet py27-pexpect py27-virtualenv py27-scripttest py27-pretend py27-freezegun py27-dateutil py27-nose py27-sqlite3 xmlto getopt docbook-xsl \
docbook docbook-sgml iso8879 docbook-xml xmlcharent sdocbook-xml w3m boehm-gc libatomic_ops asciidoc p5-Test-Exception p5-Sub-Uplevel p5-Test-NoWarnings \
p5-Test-Simple p5-Test-Warn p5-Test-Pod bzr cython py27-paramiko py27-cryptography py27-cffi py27-pycparser py27-pyasn1 py27-idna py27-ipaddress \
py27-enum34 py27-iso8601 py27-ecdsa py27-funcsigs py27-pygments py27-alabaster py27-snowballstemmer py27-pystemmer py27-imagesize swig13 cmake \
scons libarchive liblz4 lzo2 cmake-modules ninja presentproto bigreqsproto xcmiscproto xf86bigfontproto nasm bdftopcf intltool p5-XML-Parser qt4-moc \
qt4-qmake qt4-rcc qt4-uic qt4-linguist qt4-designer qt4-declarative qt4-script qt4-sql qt4-svg qt4-xmlpatterns qt4-qt3support qt4-webkit \
v4l_compat qt4-assistant qt4-help qt4-clucene qt4-doc qt4-linguisttools py27-jinja py27-sphinx gmake gsed texinfo help2man p5-Locale-gettext gettext-tools

cd /usr/ports/emulators/virtualbox-ose && make fetch install clean

# sudo fastpkg install -y gnome3-lite

#
# for chromium
cat <<'EOF' >> /etc/sysctl.conf
# for chromium
kern.ipc.shm_allow_removed=1
#
EOF

# fix libkvm.so.7 not found from chrome
# cd /usr/src/ && make world install?

#
# install https://github.com/jamiesonbecker/owa-user-agent/ if you access microsoft exchange OWA
#

#

cp /etc/X11/xorg.conf /etc/X11/xorg.conf.orig.$$

X -configure && cat /root/xorg.conf.new > /etc/X11/xorg.conf

# /etc/X11/xorg.conf for i5-box, using vesa

cp /etc/X11/xorg.conf /etc/X11/xorg.conf.orig.$$

# default to scfb driver, change as you wish
# for asus ul80 + dell 2412m
# for dual VGA card, make sure config activated card (intel?) as Card0
cat <<'EOF'> /etc/X11/xorg.conf
#
Section "ServerLayout"
    Identifier     "X.org Configured"
    Screen      0  "Screen0" 0 0
    Screen      1  "Screen1" LeftOf "Screen0"
    InputDevice    "Mouse0" "CorePointer"
    InputDevice    "Keyboard0" "CoreKeyboard"
EndSection

Section "Files"
    ModulePath   "/usr/local/lib/xorg/modules"
    FontPath     "/usr/local/share/fonts/misc/"
    FontPath     "/usr/local/share/fonts/TTF/"
    FontPath     "/usr/local/share/fonts/OTF/"
    FontPath     "/usr/local/share/fonts/Type1/"
    FontPath     "/usr/local/share/fonts/100dpi/"
    FontPath     "/usr/local/share/fonts/75dpi/"
EndSection

Section "Module"
    Load "glx"
    Load "dbe"
    Load "extmod"
    Load "dri"
    Load "record"
    Load "dri2"
EndSection

Section "InputDevice"
    Identifier  "Keyboard0"
    Driver      "kbd"
EndSection

Section "InputDevice"
    Identifier  "Mouse0"
    Driver      "mouse"
    Option        "Protocol" "auto"
    Option        "Device" "/dev/sysmouse"
    Option        "ZAxisMapping" "4 5 6 7"
EndSection

Section "Monitor"
    Identifier   "Monitor0"
    VendorName   "Monitor Vendor"
    ModelName    "Monitor Model"
EndSection

Section "Device"
    #Option "AccelMethod" "sna"
    Identifier  "Card0"
#    Driver      "vesa"
#    Driver      "intel"
    Driver      "scfb"
    BusID       "PCI:0:2:0"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device     "Card0"
    Monitor    "Monitor0"
    SubSection "Display"
        Viewport   0 0
        Depth     1
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     4
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     8
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     15
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     16
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     24
        #Modes "1366x768"
    EndSubSection
EndSection

Section "Monitor"
    Identifier    "Monitor1"
    VendorName    "Dell"
    ModelName    "U2412M"
    ModeLine    "1920x1200"    154.0 1920 1968 2000 2080 1200 1203 1209 1235 -HSync +VSync
    Option       "DPMS"          "true"
    Option       "PreferredMode" "1920x1200"
EndSection

Section "Screen"
    Identifier "Screen1"
    Device     "Card0"
    Monitor    "Monitor1"
    SubSection "Display"
        Viewport   0 0
        Depth     1
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     4
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     8
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     15
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     16
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     24
        #Modes "1366x768"
    EndSubSection
EndSection

#
EOF

#
# use vesa when card driver not avable
# #    Driver      "vesa"

# 
# duel card
cat <<'EOF' > /etc/X11/xorg.conf
Section "ServerLayout"
    Identifier     "X.org Configured"
    Screen      0  "Screen0" 0 0
    Screen      1  "Screen1" RightOf "Screen0"
    InputDevice    "Mouse0" "CorePointer"
    InputDevice    "Keyboard0" "CoreKeyboard"
EndSection

Section "Files"
    ModulePath   "/usr/local/lib/xorg/modules"
    FontPath     "/usr/local/share/fonts/misc/"
    FontPath     "/usr/local/share/fonts/TTF/"
    FontPath     "/usr/local/share/fonts/OTF/"
    FontPath     "/usr/local/share/fonts/Type1/"
    FontPath     "/usr/local/share/fonts/100dpi/"
    FontPath     "/usr/local/share/fonts/75dpi/"
EndSection

Section "Module"
    Load "glx"
    Load "dbe"
    Load "extmod"
    Load "dri"
    Load "record"
    Load "dri2"
EndSection

Section "InputDevice"
    Identifier  "Keyboard0"
    Driver      "kbd"
EndSection

Section "InputDevice"
    Identifier  "Mouse0"
    Driver      "mouse"
    Option        "Protocol" "auto"
    Option        "Device" "/dev/sysmouse"
    Option        "ZAxisMapping" "4 5 6 7"
EndSection

Section "Monitor"
    Identifier   "Monitor0"
    VendorName   "Monitor Vendor"
    ModelName    "Monitor Model"
EndSection

Section "Monitor"
    Identifier   "Monitor1"
    VendorName   "Monitor Vendor"
    ModelName    "Monitor Model"
EndSection

# NOTE: activated intel should be Card0
Section "Device"
        ### Available Driver options are:-
        ### Values: <i>: integer, <f>: float, <bool>: "True"/"False",
        ### <string>: "String", <freq>: "<f> Hz/kHz/MHz",
        ### <percent>: "<f>%"
        ### [arg]: arg optional
        #Option     "NoAccel"                # [<bool>]
        #Option     "AccelMethod"            # <str>
        #Option     "Backlight"              # <str>
        #Option     "DRI"                    # <str>
        #Option     "ColorKey"               # <i>
        #Option     "VideoKey"               # <i>
        #Option     "Tiling"                 # [<bool>]
        #Option     "LinearFramebuffer"      # [<bool>]
        #Option     "SwapbuffersWait"        # [<bool>]
        #Option     "TripleBuffer"           # [<bool>]
        #Option     "XvPreferOverlay"        # [<bool>]
        #Option     "HotPlug"                # [<bool>]
        #Option     "ReprobeOutputs"         # [<bool>]
        #Option     "XvMC"                   # [<bool>]
        #Option     "ZaphodHeads"            # <str>
        #Option     "TearFree"               # [<bool>]
        #Option     "PerCrtcPixmaps"         # [<bool>]
        #Option     "FallbackDebug"          # [<bool>]
        #Option     "DebugFlushBatches"      # [<bool>]
        #Option     "DebugFlushCaches"       # [<bool>]
        #Option     "DebugWait"              # [<bool>]
        #Option     "BufferCache"            # [<bool>]
    Identifier  "Card0"
    Driver      "intel"
    BusID       "PCI:0:2:0"
EndSection

# NOTE: inactivated nv should be Card1
Section "Device"
        ### Available Driver options are:-
        ### Values: <i>: integer, <f>: float, <bool>: "True"/"False",
        ### <string>: "String", <freq>: "<f> Hz/kHz/MHz",
        ### <percent>: "<f>%"
        ### [arg]: arg optional
        #Option     "SWcursor"               # [<bool>]
        #Option     "HWcursor"               # [<bool>]
        #Option     "NoAccel"                # [<bool>]
        #Option     "ShadowFB"               # [<bool>]
        #Option     "UseFBDev"               # [<bool>]
        #Option     "Rotate"                 # [<str>]
        #Option     "VideoKey"               # <i>
        #Option     "FlatPanel"              # [<bool>]
        #Option     "FPDither"               # [<bool>]
        #Option     "CrtcNumber"             # <i>
        #Option     "FPScale"                # [<bool>]
        #Option     "FPTweak"                # <i>
        #Option     "DualHead"               # [<bool>]
    Identifier  "Card1"
    Driver      "nv"
    BusID       "PCI:1:0:0"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device     "Card0"
    Monitor    "Monitor0"
    SubSection "Display"
        Viewport   0 0
        Depth     1
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     4
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     8
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     15
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     16
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     24
        #Modes "1366x768"
    EndSubSection
EndSection

Section "Monitor"
    Identifier    "Monitor1"
    VendorName    "Dell"
    ModelName    "U2412M"
    ModeLine    "1920x1200"    154.0 1920 1968 2000 2080 1200 1203 1209 1235 -HSync +VSync
    Option       "DPMS"          "true"
    Option       "PreferredMode" "1920x1200"
EndSection

Section "Screen"
    Identifier "Screen1"
    Device     "Card0"
    Monitor    "Monitor1"
    SubSection "Display"
        Viewport   0 0
        Depth     1
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     4
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     8
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     15
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     16
        #Modes "1366x768"
    EndSubSection
    SubSection "Display"
        Viewport   0 0
        Depth     24
        #Modes "1366x768"
    EndSubSection
EndSection

EOF

#
# check X driver status in X
#
glxinfo | grep -C 3 vendor
glxinfo | grep -C 3 render

glxgears

#########  Do _NOT_ use /etc/ttys to start xdm at boot time.  This will result in xdm
#########  hanging or restarting constantly. Instead, add xdm_enable="YES" to
#########  /etc/rc.conf. GDM will be started automatic on the next reboot.

#
# xdm/xfce start on boot
#

cat <<'EOF'>> /etc/rc.conf
#
dbus_enable="YES"
hald_enable="YES"
xdm_enable="YES"
slim_enable="YES"
gnome_enable="NO"
#
EOF

mv /usr/local/etc/slim.conf /usr/local/etc/slim.conf.$$

cp /usr/local/etc/slim.conf.sample /usr/local/etc/slim.conf

cat <<'EOF' >> /usr/local/etc/slim.conf
#
default_user    david
focus_password    yes
#
#
EOF

#
# should already exist
#
mkdir -p /usr/local/share/xsessions/backups/
mv /usr/local/share/xsessions/*.desktop /usr/local/share/xsessions/backups/
cat <<'EOF' > /usr/local/share/xsessions/xfce.desktop
[Desktop Entry]
Version=1.0
Name=Xfce Session
Comment=Use this session to run Xfce as your desktop environment
Exec=startxfce4
Icon=
Type=Application
DesktopNames=XFCE
EOF


# session list
ls -lah /usr/local/share/xsessions/
#

# https://www.google.com/chrome/browser/desktop/index.html?standalone=1&platform=win64

#
# virtualbox
#

# on boot, or add to kld_list in rc.conf
echo 'vboxdrv_load="YES"' >> /boot/loader.conf

cat <<'EOF' >> /etc/rc.conf
vboxnet_enable="YES"
vboxguest_enable="YES"
vboxservice_enable="YES"
devfs_system_ruleset="system"
EOF

cat <<'EOF' >> /etc/devfs.rules
#
[system=10]
add path 'usb/*' mode 0660 group operator
#
EOF

echo 'rm -rf /tmp/.vbox-*-ipc' >> /etc/rc.local

# video for libGL error: failed to open drm device: Permission denied

id david

pw groupmod video -m david

pw groupmod vboxusers -m david
pw groupmod operator -m david
pw groupmod wheel -m david
pw groupmod dialer -m david
id david

#
# fcitx
#

fastpkg install -y zh-fcitx zh-fcitx-cloudpinyin \
zh-fcitx-table-extra zh-fcitx-configtool fcitx-qt5 fcitx-m17n

# fcitx-qt5 for firefox?

#
# configure fcitx input
#

cat <<'EOF' > /usr/bin/fcitx-autostart
#!/bin/sh

# sleep for a little while to avoid duplicate startup

kill `ps axuww| grep -i fcitx|grep -v grep| grep -v fcitx-autostart | awk '{print $2}'` 2>/dev/null

sleep 1

fcitx -r -d
echo "FCITX STARTED."
sleep 3
EOF

chmod +x /usr/bin/fcitx-autostart

# remove ibus

pkg remove -y ibus

#
# NOTE:
#      for xfce4-terminal, right-click mouse and select Input Methods-> fcitx to active chinese input
#      or pkg remove ibus to make fcitx to default input method

# switch sound output device/port
# https://forums.freebsd.org/threads/47852/

# use xfce4-mixer to active stereo mode
cat /dev/sndstat
# Installed devices:
# pcm0: <Intel Haswell (HDMI/DP 8ch)> (play)
# pcm1: <Realtek (0x0668) (Internal Analog)> (play/rec)
# pcm2: <Realtek (0x0668) (Left Analog)> (play/rec) default
# No devices installed from userspace.

# FreeBSD Audio Driver (64bit 2009061500/amd64)
# Installed devices:
# pcm0: <Intel Haswell (HDMI/DP 8ch)> on hdaa0  (1p:1v/0r:0v)
# pcm1: <Realtek (0x0668) (Internal Analog)> on hdaa1  (1p:3v/1r:1v)
# pcm2: <Realtek (0x0668) (Left Analog)> on hdaa1  (1p:2v/2r:1v) default
# No devices installed from userspace.
# 

# 1, default speaker, 2, Analog
sudo sysctl -w hw.snd.default_unit=2


#
# run linux apps
#
# https://www.freebsd.org/doc/handbook/linuxemu.html
#
# FreeBSD provides 32-bit binary compatibility with Linux
#

# flashplayer for firefox

# https://www.freebsd.org/doc/handbook/desktop-browsers.html

# pkg remove firefox firefox-i18n flashplayer

# install and configure linux-c6 first

# here

pkg remove -y firefox
fastpkg install firefox-esr firefox-esr-i18n

mount -t fdescfs fdesc /dev/fd
mount -t procfs proc /proc

# install linux-flashplayer

cd /usr/ports/www/linux-flashplayer

missingpkg=`make missing | awk -F'/' '{print $2}'` && \
echo $missingpkg && pkg install $missingpkg

# pkg: No packages available to install matching 'linux-c6-sqlite3' have been found in the repositories

# pkg search linux-c6-sqlite
pkg install -y linux-c6-sqlite linux-c6-cyrus-sasl-lib linux-c6-elfutils-libelf

make install

pkg install -y flashplayer

nspluginwrapper -v -a -i
# Auto-install plugins from /usr/local/lib/browser_plugins
# Looking for plugins in /usr/local/lib/browser_plugins
# Auto-install plugins from /usr/local/lib/browser_plugins/linux-flashplayer
# Looking for plugins in /usr/local/lib/browser_plugins/linux-flashplayer
# Install plugin /usr/local/lib/browser_plugins/linux-flashplayer/libflashplayer.so
#   into /usr/local/lib/browser_plugins/npwrapper.libflashplayer.so
# Auto-install plugins from /root/.mozilla/plugins
# Looking for plugins in /root/.mozilla/plugins
#

# http://isflashinstalled.com/ to check is this install works

# ======================================================================
# Message from nspluginwrapper-1.4.4_7:
# ================================================================
# 
# The nspluginwrapper is installed on a per user basis. All of
# the commands can be run as an unprivileged user.
# 
# ================================================================
# 
# To install all the plugins from their default locations:
# 
# nspluginwrapper -v -a -i
# 
# ================================================================
# 
# To install a specific plugin:
# 
# nspluginwrapper -i path/to/plugin.so
# 
# ================================================================
# 
# To remove a specific plugin:
# 
# nspluginwrapper -r path/to/plugin.so
# 
# ================================================================
# 
# To view all currently installed plugins:
# 
# nspluginwrapper -l
# 
# ================================================================
# 

# about:plugins


# https://github.com/churchers/vm-bhyve

fastpkg install -y bhyve-firmware grub2-bhyve uefi-edk2-bhyve-csm uefi-edk2-bhyve tightvnc
 
# bhyve mgr

mkdir /vm

zfs create tank/davidvm
zfs set mountpoint=legacy tank/davidvm
mount -t zfs tank/davidvm /vm

cat <<'EOF'> /home/david/home/bin/workvm.sh
#!/bin/bash

# https://wiki.freebsd.org/bhyve/UEFI

export MK_PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
export PATH="$MK_PATH"
export MK_SCRIPT="$0"
export MK_OPTS="$@"
export MK_WORKBASE="/vm"

export VM_SUDO_IFCONFIG="sudo ifconfig"
export VM_SUDO_BHYVE="sudo bhyve"
export VM_SUDO_BHYVECTL="sudo bhyvectl"

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
    pecho "$MK_SCRIPT [-x] [-novnc] [-viewer] <vm name> [stop] [vnc] [rdp] [ssh]"
    exit 1
}

stopvm(){

    $VM_SUDO_BHYVECTL --destroy --vm=vm$VM_NAME >/dev/null >&1
    sleep 1

    isvmrun $VM_NAME && eecho "stop $VM_NAME failed."

    pecho "clean up tap device ..."
    for item in `ls -A $VM_CFG_DIR/*.mac 2>/dev/null| sort`
    do
        tcnt=`cat ${item}.tap 2>/dev/null`
        if [ -n "$tcnt" ]
        then
            brname=`cat ${item}.bridge 2>/dev/null|head -n1`
            if [ -n "$brname" ]
            then
                $VM_SUDO_IFCONFIG $brname >/dev/null 2>&1
                if [ $? -eq 0 ]
                then
                    $VM_SUDO_IFCONFIG $brname 2>/dev/null | grep -q "member: tap$tcnt "
                    if [ $? -eq 0 ]
                    then
                        $VM_SUDO_IFCONFIG $brname deletem tap$tcnt || exit 1
                    fi
                fi
            fi
            $VM_SUDO_IFCONFIG tap$tcnt >/dev/null 2>&1 && \
            $VM_SUDO_IFCONFIG tap$tcnt destroy >/dev/null 2>&1
        fi
    done
    pecho "stopped"
    exit 0
}

runvm(){

    pecho ""
    pecho "CMD: $VM_CMD"
    pecho ""

    aftervm & 

    cat /dev/null > $VM_DIR/bhyve.log.err
    
    for aaa in `seq 0 5`
    do
        $VM_CMD 2>&1 
        cat $VM_DIR/bhyve.log | grep -q 'vm_reinit'
        if [ $? -eq 0 ]
        then
            cat $VM_DIR/bhyve.log | grep -C 10 'vm_reinit' > $VM_DIR/bhyve.log.err
            cat /dev/null > $VM_DIR/bhyve.log
            pecho ""
            pecho "vm_reinit error, re-try $VM_NAME"
            pecho ""
            cat $VM_DIR/bhyve.log >> $VM_DIR/bhyve.log.err
        else
            break
        fi
        sleep 1
    done

    for aaa in `seq 0 5`
    do
        echo -n '.'
        isvmrun $VM_NAME 
        if [ $? -ne 0 ]
        then
            pecho ""
            pecho "$VM_NAME stopped." && break
            pecho ""
        fi
        sleep 1
    done
    echo ""
    stopvm
    exit $?
}

runrdp(){
    export APPNAME=rdp
    trap 'handle_trap' INT QUIT HUP
    pecho "run $APPNAME, log to $VM_DIR/${APPNAME}.log"
    if [ "$2" = "manual" ]
    then
        bgrdp $@ 2>&1 | tee -i $VM_DIR/${APPNAME}.log 
        return $?
    else
        bgrdp $@ 2>&1 | tee -i $VM_DIR/${APPNAME}.log
        return $?
    fi
}

update_console_ip(){
    test -z "$VM_CONSOLE_MAC" && VM_CONSOLE_MAC=`cat $VM_CFG_DIR/console.hwaddr 2>/dev/null`
    if [ -z "$VM_CONSOLE_MAC" ]
    then
        eecho ""
        eecho "VM_CONSOLE_MAC NOT FOUND: $VM_CFG_DIR/console.hwaddr"
        eecho ""
        return 1
    fi

    # got console ip from dnsmasq
    pecho "fetch console ip($VM_CONSOLE_MAC) from dnsmasq lease ..."
    VM_CONSOLE_IP=`cat /var/db/dnsmasq.leases | grep -i "${VM_CONSOLE_MAC}$"| awk '{print $3}'| head -n1`
    for item in `seq 0 90`
    do
        if [ -z "$VM_CONSOLE_IP" ]
        then
            sleep 1
            continue
        else
            break
        fi
        VM_CONSOLE_IP=`cat /var/db/dnsmasq.leases | grep -i "${VM_CONSOLE_MAC}$"| awk '{print $3}'| head -n1`
    done
    if [ -z "$VM_CONSOLE_IP" ]
    then
        eecho ""
        eecho "FETCH CONSOLE IP FAILED"
        eecho ""
        return 1
    fi
    pecho "waiting for console ip $VM_CONSOLE_IP($VM_CONSOLE_MAC) up ..."
    for aaa in `seq 0 30`
    do
        ping -t 1 -c 1 $VM_CONSOLE_IP >/dev/null 2>&1
        if [ $? -eq 0 ]
        then
            break
        fi
        sleep 1
    done
    ping -t 1 -c 1 $VM_CONSOLE_IP >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
        pecho "CONSOLE IP $VM_CONSOLE_IP ALIVE"
    else
        pecho "CONSOLE IP $VM_CONSOLE_IP UNREACHABLE"
    fi
    local presum=`md5 /etc/pf.rdr.conf`
    echo "$VM_CONSOLE_IP" > $VM_CFG_DIR/console.ip || exit 1
    echo "workvm = \"$VM_CONSOLE_IP\"" > /etc/pf.rdr.conf || exit 1
    pecho ""
    pecho "CONSOLE IP $VM_CONSOLE_IP updated into /etc/pf.rdr.conf"
    pecho ""
    if [ "$presum" != "`md5 /etc/pf.rdr.conf`" ]
    then
        pfsess start
    fi
    return 0
}

bgrdp(){
    local trycnt="$1"
    local manual="$2"
    test -z "$trycnt" -o "$trycnt" = "manual" && trycnt=3

    update_console_ip || return 1

    pecho ""
    pecho "RDP: user $VM_RDP_USER, screen $VM_RDP_WH, IP $VM_CONSOLE_IP"
    pecho ""
    # -x 0x80 for font smooth, 0x81 0x8f
    export VM_RDP_BASE="rdesktop -x 0x80 -a 32 -f -k en-us -D"
    export VM_RDP_VIEWER_CMD="$VM_RDP_BASE -T $VM_NAME -u $VM_RDP_USER -p $VM_RDP_PASSWORD -z -r clipboard:PRIMARYCLIPBOARD -g $VM_RDP_WH $VM_CONSOLE_IP"
    # pecho "RPD CMD: $VM_RDP_VIEWER_CMD"
    pecho ""
    pecho "Ctrl + Alt + Enter to toggle between window and fullscreen"
    pecho ""

    if [ "$manual" = "manual" ]
    then
        pecho ""
        pecho "manual rdesktop command: $VM_RDP_VIEWER_CMD"
        pecho ""
        return 0
    fi
    ps axuww| grep -- "$VM_RDP_BASE" | grep -v grep | grep -- "-T $VM_NAME" | grep -- "-u $VM_RDP_USER -p $VM_RDP_PASSWORD" | grep -q -- "-g $VM_RDP_WH"
    if [ $? -eq 0 ]
    then
        eecho "rdesktop viewer already running."
        ps axuww | grep -- "-u $VM_RDP_USER -p $VM_RDP_PASSWORD" | grep -- "-T $VM_NAME" | grep -- "-g $VM_RDP_WH"
        sleep 5
        return 1
    fi
    for aaa in `seq 0 $trycnt`
    do
        echo -n '.'
        isvmrun $VM_NAME && pecho " $VM_NAME running ..." && break
        sleep 1
    done

    pecho ""
    pecho ""
    pecho ""
    pecho ""
    pecho "Verify console ip $VM_CONSOLE_IP ..."
    pecho ""
    for aaa in `seq 0 30`
    do
        echo -n '.'
        ping -t 1 -c 1 $VM_CONSOLE_IP >/dev/null 2>&1 && pecho " $VM_CONSOLE_IP alive ..." && break
        sleep 1
    done

    echo ""

    $VM_RDP_VIEWER_CMD 
    return $?
}

runssh(){
    local trycnt="$1"
    local manual="$2"
    test -z "$trycnt" -o "$trycnt" = "manual" && trycnt=3
}

runvnc(){
    export APPNAME=vnc
    pecho "run $APPNAME, log to $VM_DIR/${APPNAME}.log"
    if [ "$2" = "manual" ]
    then
        bgvnc $@ 2>&1 | tee -i $VM_DIR/${APPNAME}.log 
        return $?
    else
        bgvnc $@ 2>&1 | tee -i $VM_DIR/${APPNAME}.log
        return $?
    fi
}

bgvnc(){
    local trycnt="$1"
    local manual="$2"
    test -z "$trycnt" -o "$trycnt" = "manual" && trycnt=10

    trap 'handle_trap' INT QUIT HUP EXIT TREM
    # trap 'handle_trap' INT QUIT HUP

    # NOTE: using tigervnc
    VM_VNC_PORT=`cat $VM_CFG_DIR/vnc.port 2>/dev/null | head -n 1`
    if [ -z "$VM_VNC_PORT" ]
    then
        eecho "can not run -viewer, VM_VNC_PORT not defined in $VM_CFG_DIR/vnc.port"
        exit 1
    fi

    export VM_VNC_VIEWER_CMD="$VM_VNC_BASE ${VM_VNC_BIND}:$VM_VNC_PORT"
    pecho "starting vncviewer for $VM_NAME: ${VM_VNC_BIND}:$VM_VNC_PORT ..."
    if [ "$manual" = "manual" ]
    then
        pecho ""
        pecho "manual vncviewer command: $VM_VNC_VIEWER_CMD"
        pecho ""
        return 0
    fi
    ps axuww| grep -- "$VM_VNC_BASE" | grep -v grep | grep -q -- ":$VM_VNC_PORT"
    if [ $? -eq 0 ]
    then
        pecho ""
        eecho "vnc viewer already running."
        ps axuww| grep -- "$VM_VNC_VIEWER_CMD" | grep -v grep
        pecho ""
        sleep 10
        return 1
    fi
    for aaa in `seq 0 $trycnt`
    do
        sockstat -4 -l | grep ":$VM_VNC_PORT"
        sockstat -4 -l | grep -q ":$VM_VNC_PORT" && isvmrun $VM_NAME && break
        sleep 1
    done
    sockstat -4 -l | grep -q ":$VM_VNC_PORT" && isvmrun $VM_NAME
    if [ $? -ne 0 ]
    then
        eecho "vnc port $VM_VNC_PORT is not listening"
        sleep 10
        return 1
    fi
    $VM_VNC_VIEWER_CMD
    return $?
}
##
#     1       HUP (hang up)
#     2       INT (interrupt)
#     3       QUIT (quit)
#     6       ABRT (abort)
#     9       KILL (non-catchable, non-ignorable kill)
#     14      ALRM (alarm clock)
#     15      TERM (software termination signal)
##
handle_trap ( ) {
    #trap '' INT QUIT HUP EXIT 
    pecho "$APPNAME: signaled"
}

isvmrun(){
    # return 0 for running
    local VM_NAME="$1"
    test -z "$VM_NAME" && efecho "need vm name arg"&&exit 1
    ps axuww| grep bhyve | grep -v grep | grep -q "bhyve: vm$VM_NAME "
    return $?
}

vncstatus(){
    if [ -z "$VM_VNC_PORT" ]
    then
        VM_VNC_PORT=`cat $VM_CFG_DIR/vnc.port 2>/dev/null | head -n 1`
    fi
    if [ -z "$VM_VNC_PORT" ]
    then
        eecho "VM_VNC_PORT not defined in $VM_CFG_DIR/vnc.port"
        return 1
    fi
    for aaa in `seq 1 10`
    do
        ps axuww| grep -- "$VM_VNC_BASE" | grep -v grep | grep -q -- ":$VM_VNC_PORT"
        if [ $? -eq 0 ]
        then
            pecho ""
            pecho "vnc viewer started."
            ps axuww| grep -- "$VM_VNC_BASE" | grep -v grep | grep -- ":$VM_VNC_PORT"
            pecho ""
            sleep 5
            return 0
        fi
    done
    return 1
}

aftervm(){

    pecho ""

    if [ "$novnc" != "1" ]
    then
        # runvnc 5 
        nohup $MK_SCRIPT -viewer $VM_NAME vnc >>  $VM_DIR/bhyve.log 2>&1 &
    else
        pecho ""
        
        runvnc 5 manual 
    fi
    
    pecho ""

}

export xtrace=""
export viewer=0
export novnc=0
export manual=""
export rdpgo="0"
export sshgo="0"
export vncgo="0"
export dostop=""
export VM_NAME=""
export dovm="0"
for aaa in $@
do
    if [ "$aaa" = "-viewer" ]
    then
        viewer=1
        continue
    fi
    if [ "$aaa" = "-x" ]
    then
        set -x
        xtrace="-x"
        continue
    fi
    if [ "$aaa" = "-novnc" ]
    then
        novnc=1
        continue
    fi
    echo "$aaa" | grep -q '^-' && continue
    if [ "$aaa" = "vnc" ]
    then
        vncgo="1"
        continue
    fi
    if [ "$aaa" = "rdp" ]
    then
        rdpgo="1"
        continue
    fi
    if [ "$aaa" = "ssh" ]
    then
        sshgo="1"
        continue
    fi
    if [ "$aaa" = "stop" ]
    then
        dostop="stop"
        continue
    fi
    if [ "$aaa" = "manual" ]
    then
        manual="manual"
        continue
    fi
    if [ "$aaa" = "runvm" ]
    then
        dovm="1"
        continue
    fi
    test -z "$VM_NAME" && VM_NAME="$aaa" && pecho "VM NAME: $VM_NAME" 
done

if [ -z "$VM_NAME" ]
then
    usage
    exit 1
fi
shift


if [ "$dovm" = "1" ]
then
    if [ -z "$VM_CMD" ]
    then
        eecho "VM_CMD not defined"
        exit 1
    fi
    runvm
    exit $?
fi

export VM_DIR="$MK_WORKBASE/data/$VM_NAME/"
export VM_CFG_DIR="$MK_WORKBASE/conf/$VM_NAME/"
VM_CFG_FILE="$VM_CFG_DIR/vm.conf"

if [ ! -f "$VM_CFG_FILE" ]
then
    eecho ""
    eecho "vm config $VM_CFG_FILE not found."
    eecho ""
    exit 1
fi

if [ ! -d "$VM_DIR" ]
then
    mkdir -p $VM_DIR || exit 1
fi

cd $VM_DIR
# default value
export VM_VNC_BIND="127.0.0.1"
export VM_CPUS=0
export VM_MEM=2G
export VM_VNC_PORT=""

export VM_NIC_TYPE="virtio-net"
#export VM_NIC_TYPE="e1000"

export VM_HD_TYPE="ahci-hd"
#export VM_HD_TYPE="virtio-blk"
export VM_CD_TYPE="ahci-cd"

# export VM_PCI_HD_NUM="5:"
# export VM_PCI_NIC_NUM="6:"

export VM_PCI_HD_NUM=""
export VM_PCI_NIC_NUM=""

# export VM_VNC_WAIT=",wait"
export VM_VNC_WAIT=""

# export VM_VNC_FULLSCREEN=" -fullscreen"
export VM_VNC_FULLSCREEN=""

export VM_RDP_WH="1920x1050"
export VM_RDP_WH="1280x768"
export VM_RDP_USER="guest"
export VM_RDP_PASSWORD="nopass"

export VM_CONSOLE_IP_NUM=""
export VM_CONSOLE_BR="bridge8192"
export VM_CONSOLE_BR_IP_NET="172.16.254"
export VM_CONSOLE_BR_IP_NUM="254"

export VM_NAT_IP_NUM=""
export VM_NAT_BR="bridge8191"
export VM_NAT_BR_IP_NET="172.16.253"
export VM_NAT_BR_IP_NUM="254"

vmvar=`cat $VM_CFG_FILE 2>/dev/null| grep '^VM_' | grep '=' | grep -v ';'`
eval $vmvar

dispinfo=`sysctl -a |grep -A 5 'framebuffer' | grep 'user size:'`
VM_VNC_WIDTH=`echo $dispinfo | tr ',' ' ' | awk '{print $3}'`
VM_VNC_HIGH=`echo $dispinfo | tr ',' ' ' | awk '{print $5}'`

pecho ""
pecho "DISPLAY RESOLUTION: ${VM_VNC_WIDTH}x${VM_VNC_HIGH}"
pecho ""
export VM_VNC_BASE="vncviewer -fullscreen -Shared -RemoteResize -DesktopSize=${VM_VNC_WIDTH}x${VM_VNC_HIGH}$VM_VNC_FULLSCREEN"

if [ "$viewer" = "1" ]
then
    if [ -z "$VM_NAME" ]
    then
        eecho "can not run -viewer, VM_NAME not defined"
        exit 1
    fi
    if [ "$vncgo" = "1" ]
    then
        runvnc 5 $manual 

        sleep 1

        pecho ""

        exit $?
    fi
    
    if [ "$sshgo" = "1" ]
    then
        runssh 5 $manual 

        sleep 1

        pecho ""

        exit $?
    fi

    if [ "$rdpgo" = "1" ]
    then

        runrdp 5 $manual 

        sleep 1

        pecho ""

        exit $?
    fi
    usage
    exit 0
fi


#
hwncpu="$(sysctl -n hw.ncpu)"
test -z "$hwncpu" && hwncpu=1 && eecho "read hw.ncpu failed."
maxcpu=0
let maxcpu=$hwncpu-1 >/dev/null
test $VM_CPUS -le 0 && VM_CPUS=$hwncpu

if [ $VM_CPUS -gt $hwncpu ]
then
    VM_CPUS=$hwncpu
fi

if [ "$viewer" != "1" -a "$dovm" != "1" -a "$dostop" != "stop" ]
then
    isvmrun $VM_NAME 
    if [ $? -eq 0 ]
    then
        pecho ""
        pecho "$VM_NAME is running."
        pecho ""
        aftervm 
        vncstatus
        sleep 5
        exit 0
    fi
fi

vmvar=`set | grep '^VM_' | grep '=' | grep -v ';'`
if [ `id -u` -ne 0 ]
then
    pecho ""
    pecho "sudo ..."
    pecho ""
    sudo true
fi

test -n "$USER" && sudo chown -R $USER:$USER $MK_WORKBASE

if [ "$dostop" = "stop" ]
then
    stopvm
fi
#

pecho ""
pecho "NOTE: bhyve UEFI bootloader can not boot from GPT"
pecho ""
#pecho "config:"
#pecho ""
#echo "$vmvar"
#pecho ""


VM_VNC_PORT=5900
for item in `seq 0 20`
do
    sockstat -l -4 | grep -- ":${VM_VNC_PORT}" | grep -q '*:*'
    test $? -ne 0 && break
    let VM_VNC_PORT=$VM_VNC_PORT+1 >/dev/null
done
if [ "$VM_VNC_PORT" = "5921" ]
then
    eecho "all vnc port unaviable"
    exit 1
fi

pecho ""
pecho "Running with $VM_CPUS CPU(s)."
pecho ""

# WARNING: do not use -l com1,stdio and & to run bhyve in background, will block networking
# NOTE: remove -s 31,lpc will crash with: 
export VM_CMD="$VM_SUDO_BHYVE -A -H -s 0,hostbridge -s 29,fbuf,tcp=${VM_VNC_BIND}:${VM_VNC_PORT},w=$VM_VNC_WIDTH,h=${VM_VNC_HIGH}$VM_VNC_WAIT -s 31,lpc"
VM_CMD="$VM_CMD -m $VM_MEM"
VM_CMD="$VM_CMD -c $VM_CPUS"
VM_CMD="$VM_CMD -l bootrom,/usr/local/share/uefi-firmware/BHYVE_UEFI.fd"

# for bootcd
ahcicnt=4
for item in `find $VM_DIR/ -depth 1 \( -type f -o -type l \) | sort`
do
    echo "$item" | grep -q '.iso$'
    if [ $? -eq 0 ]
    then
        VM_CMD="$VM_CMD -s ${VM_PCI_HD_NUM}${ahcicnt},${VM_CD_TYPE},$item"
        let ahcicnt=$ahcicnt+1 >/dev/null
        continue
    fi
    echo "$item" | grep -q '.disk$'
    if [ $? -eq 0 ]
    then
        VM_CMD="$VM_CMD -s ${VM_PCI_HD_NUM}${ahcicnt},${VM_HD_TYPE},$item"
        let ahcicnt=$ahcicnt+1 >/dev/null
        continue
    fi
    echo "$item" | grep -q '.device$'
    if [ $? -eq 0 ]
    then
        rawdev=`cat $item 2>/dev/null| head -n1`
        test -z "$rawdev" && continue
        test ! -f $rawdev -a ! -c $rawdev && pecho "WARNING: RAW device $rawdev($item) not found" && continue
        VM_CMD="$VM_CMD -s ${VM_PCI_HD_NUM}${ahcicnt},${VM_HD_TYPE},$rawdev"
        let ahcicnt=$ahcicnt+1 >/dev/null
        continue
    fi
done

export VM_CONSOLE_BR_IP="${VM_CONSOLE_BR_IP_NET}.${VM_CONSOLE_BR_IP_NUM}"

$VM_SUDO_IFCONFIG $VM_CONSOLE_BR >/dev/null 2>&1

if [ $? -ne  0 ]
then
    $VM_SUDO_IFCONFIG $VM_CONSOLE_BR create up || exit 1
    $VM_SUDO_IFCONFIG $VM_CONSOLE_BR inet $VM_CONSOLE_BR_IP/24 || exit 1
else
    brip=`$VM_SUDO_IFCONFIG $VM_CONSOLE_BR | grep 'inet ' | awk '{print $2}'`
    brmask=`$VM_SUDO_IFCONFIG $VM_CONSOLE_BR | grep 'inet ' | awk '{print $4}'`
    if [ "$brip" != "$VM_CONSOLE_BR_IP" -o "$brmask" != "0xffffff00" ]
    then
        pecho ""
        eecho "internal bridge $VM_CONSOLE_BR ip configure mismatch"
        pecho "NEED: $VM_CONSOLE_BR_IP 0xffffff00"
        pecho "GOT: $brip $brmask"
        pecho ""
        $VM_SUDO_IFCONFIG $VM_CONSOLE_BR destroy 2>/dev/null
        sleep 1
        $VM_SUDO_IFCONFIG $VM_CONSOLE_BR create up || exit 1
        $VM_SUDO_IFCONFIG $VM_CONSOLE_BR inet $VM_CONSOLE_BR_IP/24 || exit 1
    fi
fi
ping -t 1 -c 1 $VM_CONSOLE_BR_IP >/dev/null 2>&1
test $? -ne 0 && eecho "CONSOLE BRIDGE SETUP FAILED" && exit 1

VM_NAT_BR_IP="${VM_NAT_BR_IP_NET}.${VM_NAT_BR_IP_NUM}"

$VM_SUDO_IFCONFIG $VM_NAT_BR >/dev/null 2>&1

if [ $? -ne  0 ]
then
    $VM_SUDO_IFCONFIG $VM_NAT_BR create up || exit 1
    $VM_SUDO_IFCONFIG $VM_NAT_BR inet $VM_NAT_BR_IP/24 || exit 1
else
    brip=`$VM_SUDO_IFCONFIG $VM_NAT_BR | grep 'inet ' | awk '{print $2}'`
    brmask=`$VM_SUDO_IFCONFIG $VM_NAT_BR | grep 'inet ' | awk '{print $4}'`
    if [ "$brip" != "$VM_NAT_BR_IP" -o "$brmask" != "0xffffff00" ]
    then
        pecho ""
        eecho "internal bridge $VM_NAT_BR ip configure mismatch"
        pecho "NEED: $VM_NAT_BR_IP 0xffffff00"
        pecho "GOT: $brip $brmask"
        pecho ""
        # $VM_SUDO_IFCONFIG $VM_NAT_BR destroy 2>/dev/null
        # sleep 1
        # $VM_SUDO_IFCONFIG $VM_NAT_BR create up || exit 1
        $VM_SUDO_IFCONFIG $VM_NAT_BR inet $VM_NAT_BR_IP/24 || exit 1
    fi
fi
ping -t 1 -c 1 $VM_NAT_BR_IP >/dev/null 2>&1
test $? -ne 0 && eecho "NAT BRIDGE SETUP FAILED" && exit 1

if [ -n "${VM_PCI_HD_NUM}" ]
then
    ahcicnt=0
fi

test ! -f $VM_CFG_DIR/zz-console.mac && touch $VM_CFG_DIR/zz-console.mac

test ! -f $VM_CFG_DIR/zz-console.mac && exit 1

test ! -f $VM_CFG_DIR/zz-nat.mac && touch $VM_CFG_DIR/zz-nat.mac

test ! -f $VM_CFG_DIR/zz-nat.mac && exit 1

export VM_CONSOLE_MAC=""

allnic="`ls -A $VM_CFG_DIR/*.mac 2>/dev/null| sort|uniq`"

for item in $allnic
do
    tcnt=`cat ${item}.tap 2>/dev/null`
    if [ -n "$tcnt" ]
    then
        $VM_SUDO_IFCONFIG tap$tcnt >/dev/null 2>&1
        # already exist
        if [ $? -eq 0 ]
        then
            $VM_SUDO_IFCONFIG tap$tcnt | grep -q 'status: no carrier' 
            if [ $? -eq 0 ]
            then
                iecho "device tap$tcnt exited but in status: no carrier"
                $VM_SUDO_IFCONFIG tap$tcnt destroy || exit 1
            else
                preether=`cat ${item}.ether 2>/dev/null`
                curether=`$VM_SUDO_IFCONFIG tap$tcnt 2>/dev/null| grep 'ether ' | awk '{print $2}'`
                if [ "$preether" = "$curether" ]
                then
                    $VM_SUDO_IFCONFIG tap$tcnt destroy || exit 1
                    pecho "previous device tap$tcnt removed: $curether"
                else
                    iecho "device tap$tcnt exited but is not configured for $VM_NAME"
                    tcnt=""
                fi
            fi
        fi
    fi
    if [ -z "$tcnt" ]
    then
        tapcnt=20
        for item2 in `seq 0 20`
        do
            $VM_SUDO_IFCONFIG tap$tapcnt >/dev/null 2>&1
            if [ $? -ne 0 ]
            then
                tcnt=$tapcnt
                break
            fi
            let tapcnt=$tapcnt+1 >/dev/null
        done
        test -z "$tcnt" && eecho "all tap[20-40] unaviable" && exit 1
    fi
    echo "$tcnt" > ${item}.tap
    isnewmac=0
    mac=`cat $item 2>/dev/null`
    if [ -z "$mac" ]
    then
        mac=`genmac`
        isnewmac=1
    fi
    if [ -z "$mac" ]
    then
        eecho "generate MAC address for tap$tcnt failed"
        stopvm
        exit 1
    fi
    mac="`tolower $mac`"
    echo "$mac" > $item || exit 1
    mac=`echo "$mac"|tr '-' ':'`
    if [ $isnewmac -eq 0 ]
    then
        pecho "OLD MAC address for tap$tcnt $mac"
    else
        pecho "NEW MAC address for tap$tcnt $mac"
    fi
    VM_CMD="$VM_CMD -s ${VM_PCI_NIC_NUM}${ahcicnt},${VM_NIC_TYPE},tap$tcnt,mac=$mac"
    #VM_CMD="$VM_CMD -s ${VM_PCI_NIC_NUM}${ahcicnt},${VM_NIC_TYPE},tap$tcnt"

    let ahcicnt=$ahcicnt+1 >/dev/null

    $VM_SUDO_IFCONFIG tap$tcnt >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
        $VM_SUDO_IFCONFIG tap$tcnt create || exit 1
    fi
    curether=`$VM_SUDO_IFCONFIG tap$tcnt 2>/dev/null| grep 'ether ' | awk '{print $2}'`
    echo "$curether" > ${item}.ether || exit 1

    brname=`cat ${item}.bridge 2>/dev/null|head -n1`
    if [ "`basename $item`" = "zz-console.mac" ]
    then
        brname=$VM_CONSOLE_BR
        echo "$brname" > ${item}.bridge
        VM_CONSOLE_MAC="$mac"
        pecho "CONSOLE MAC: $VM_CONSOLE_MAC"
        echo "$VM_CONSOLE_MAC" > $VM_CFG_DIR/console.hwaddr || exit 1
    fi
    if [ "`basename $item`" = "zz-nat.mac" ]
    then
        # allow custom nat bridge
        if [ -z "$brname" ]
        then
            brname=$VM_NAT_BR
        fi
        echo "$brname" > ${item}.bridge
        VM_NAT_MAC="$mac"
        pecho "NAT MAC: $VM_NAT_MAC"
        echo "$VM_NAT_MAC" > $VM_CFG_DIR/nat.hwaddr || exit 1
    fi
    if [ -n "$brname" ]
    then
        $VM_SUDO_IFCONFIG $brname >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
            # create 
            $VM_SUDO_IFCONFIG $brname create || exit 1
        fi
        $VM_SUDO_IFCONFIG $brname up || exit 1
        $VM_SUDO_IFCONFIG $brname addm tap$tcnt || exit 1
        # $VM_SUDO_IFCONFIG $brname 
    fi
    $VM_SUDO_IFCONFIG tap$tcnt up || exit 1
    # $VM_SUDO_IFCONFIG tap$tcnt 
done
# TODO: use serial console
#-s 30,xhci,tablet \
#-l com1,stdio \
#-l com1,/dev/nmdm0A \

ncpu=$hwncpu
let ncpu=$hwncpu-$VM_CPUS >/dev/null

# -l 0-0 is ok
vcpuno=0
for item in `seq $ncpu $maxcpu`
do
    VM_CMD="$VM_CMD -p $vcpuno:$item"
    let vcpuno=$vcpuno+1 >/dev/null
done

# VM_CMD="cpuset -l $ncpu-$maxcpu $VM_CMD vm$VM_NAME"
VM_CMD="$VM_CMD vm$VM_NAME"

sudo sysctl -w net.link.tap.user_open=1 >/dev/null
sudo sysctl -w net.link.tap.up_on_open=1 >/dev/null

sudo kldload vmm 2>/dev/null
# sudo kldload nmdm 2>/dev/null

echo "$VM_VNC_PORT" > $VM_CFG_DIR/vnc.port

sudo true || exit 1

nohup sudo -E $MK_SCRIPT $xtrace $VM_NAME runvm > $VM_DIR/bhyve.log 2>&1 &

pecho ""
pecho "starting for $VM_NAME ..."
pecho ""
for aaa in `seq 1 10`
do
    pecho "."
    isvmrun $VM_NAME && iecho "$VM_NAME started." && break
    if [ -s "$VM_DIR/bhyve.log" ]
    then
        tail -n 20 $VM_DIR/bhyve.log
    fi
    sleep 1
done
isvmrun $VM_NAME 
if [ $? -ne 0 ]
then
    eecho "$VM_NAME failed to start." 
    cat $VM_DIR/bhyve.log.err
    exit 1
fi

vncstatus

update_console_ip

exit 0

EOF

chmod +x /home/david/home/bin/workvm.sh

#
# remote desktop
#

sudo fastpkg install -y xrdp-devel

### Message from xrdp-devel-0.7.0.b20130912_3,1:
### ==============================================================================
### 
### XRDP has been installed.
### 
### There is an rc.d script, so the service can be enabled by adding this line
### in /etc/rc.conf:
### 
### xrdp_enable="YES"
### xrdp_sesman_enable="YES" # if you want to run xrdp-sesman on the same machine
### 
### Do not forget to edit the configuration files in "/usr/local/etc/xrdp"
### and the "/usr/local/etc/xrdp/startwm.sh" script.
### 
### ==============================================================================

cat <<'EOF' >> /etc/rc.conf
#
xrdp_enable="YES"
xrdp_sesman_enable="YES" # if you want to run xrdp-sesman on the same machine
EOF

cat <<'EOF' > /usr/local/etc/xrdp/startwm.session
#!/bin/sh
# session configure for xrdp startwm
SESSIONS="startxfce4 startkde gnome-session blackbox fluxbox xterm"
#
EOF

chmod +x /usr/local/etc/xrdp/startwm.session

sed -i -e 's#^SESSIONS=#\. /usr/local/etc/xrdp/startwm.session \|\| SESSIONS=#g' /usr/local/etc/xrdp/startwm.sh

cat /usr/local/etc/xrdp/startwm.sh

#
# remote desktop client side
#

sudo fastpkg install -y rdesktop

cat <<'EOF' > ~/bin/xremote.sh
#!/bin/bash
#
# note: use ctl+alt+enter to switch between full-screen
#

REMOTEUSER="david"
REMOTEPASSWORD="remotepasswd"
REMOTEHOST="10.236.12.201"
disp="1920x1080"
#rdesktop -k en-us -D -u $REMOTEUSER -p $REMOTEPASSWORD -z -r clipboard:PRIMARYCLIPBOARD -s /usr/bin/xfce4-session -g $disp $REMOTEHOST &
rdesktop -f -k en-us -D -u $REMOTEUSER -p $REMOTEPASSWORD -z -r clipboard:PRIMARYCLIPBOARD -g $disp $REMOTEHOST &

EOF

chmod +x ~/bin/xremote.sh

# reboot to take effect

test ! -s ${HOME}/.config/fcitx/config && cat <<'EOF'> ${HOME}/.config/fcitx/config
[Hotkey]
TriggerKey=CTRL_ALT_SPACE
SwitchKey=Disabled
IMSwitchIncludeInactive=True

[Program]
DelayStart=5
ShareStateAmongWindow=PerProgram

[Output]

[Appearance]
ShowInputWindowWhenFocusIn=True
ShowVersion=True

EOF

cat ${HOME}/.config/fcitx/config | grep -v '^#'

# https://forums.freebsd.org/threads/xfce-how-to-start-xfce-in-freebsd.4627/

#
# configure for user david
#
# https://www.freebsd.org/doc/handbook/users-synopsis.html
#

pw usermod david -s /usr/local/bin/bash
pw groupmod video -m david 2>/dev/null || sudo pw groupmod wheel -m david

#
# config xfce startup as david
#

su - david

# http://stackoverflow.com/questions/17846529/could-not-open-a-connection-to-your-authentication-agent
# fix ssh-copyid: no keys found
test ! -f .ssh/id_rsa && ssh-keygen

ssh-add && ssh-add -L

# remove property name="output-name" type="string" value="HDMI1"
# from ${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
# when xfce4-panel disappear

cat <<'EOF'> ${HOME}/.profile
#!/bin/sh
# $FreeBSD: head/etc${HOME}dot.profile 278616 2015-02-12 05:35:00Z cperciva $
#
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:~/bin
export PATH
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

chmod +x ${HOME}/.profile

cat <<'EOF'> ${HOME}/.bashrc
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

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

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

chmod +x ${HOME}/.bashrc

cat <<'EOF'> ${HOME}/.env-all
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

chmod +x ${HOME}/.bashrc ${HOME}/.env-all


# for xdm/slim

cat <<'EOF' > ~/.xinitrc
#!/usr/local/bin/bash
#
# NOTE: PATH resetted
#
test -s /etc/profile && source /etc/profile
#
test -s ${HOME}/.env-all && source ${HOME}/.env-all
#

# export XMODIFIERS=@im=fcitx

# fcitx -d &
/usr/bin/fcitx-autostart

xfce4-terminal --maximize &

#
exec "/usr/local/bin/startxfce4" 
#
EOF

chmod +x ~/.xinitrc

# restore xfce4 setting
# rsync -a /home/david/.config/xfce4/ david@172.236.127.24:/home/david/.config/xfce4/ --delete

mkdir -p ${HOME}/.config/autostart/ && cp /usr/local/share/applications/fcitx.desktop  ${HOME}/.config/autostart/

echo '[[ $PS1 && -f /usr/local/share/bash-completion/bash_completion.sh ]] && source /usr/local/share/bash-completion/bash_completion.sh' >> ${HOME}//.env-all

wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O ${HOME}/.git-completion.bash
chmod +x ${HOME}/.git-completion.bash

echo 'test -x ${HOME}/.git-completion.bash && . ${HOME}/.git-completion.bash' >> ${HOME}//.env-all


### bluetooth
# 
# ugen0.2: <vendor 0x0a12 CSR8510 A10> at usbus0
# ubt0 on uhub0
# ubt0: <vendor 0x0a12 CSR8510 A10, class 224/1, rev 2.00/88.91, addr 5> on usbus0
# WARNING: attempt to domain_add(bluetooth) after domainfinalize()
# WARNING: attempt to domain_add(netgraph) after domainfinalize()
# 

test ! -f /etc/bluetooth/ubt0.conf && cp /etc/defaults/bluetooth.device.conf /etc/bluetooth/ubt0.conf

service bluetooth start ubt0

# I hate bluetooth, LOL

#
#
# done =-========================
#

# -----------

#
# qt5 + liteide + Go
#

# root config, install qt5 gcc 4.8

fastpkg install -y qt5 qt5-qmake gcc qt5-sqldrivers-mysql qt5-sqldrivers-sqlite3 gdb

# gdb710 for qt debug
# fix: Dwarf Error: wrong version in compilation unit header (is 4, should be 2)

# The process will require 860 MiB more space.
# 212 MiB to be downloaded.

ln -sf /usr/local/lib/qt5/bin/qmake /usr/local/bin/qmake

export QTDIR="/usr/local/share/qt5/"

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/qt5/"

cat <<'EOF' >> /etc/profile
# for qt5
export QTDIR="/usr/local/share/qt5/"
if [ -n "$LD_LIBRARY_PATH" ]
then
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/qt5/"
else
    export LD_LIBRARY_PATH="/usr/local/lib/qt5/"
fi
#
EOF

# /usr/local/include/qt5


##
# Go lang in david
#

#
# Go bootstrap
#
cd ~ && mkdir -p ~/tmp && cd ~/tmp && axel -n 8 https://storage.googleapis.com/golang/go1.5.3.freebsd-amd64.tar.gz && \
tar xfz go1.5.3.freebsd-amd64.tar.gz && mv go ~/bootstrap.go1.5.3.freebsd-amd64

export GOROOT_BOOTSTRAP=/home/david/bootstrap.go1.5.3.freebsd-amd64

# or 1.4.3

cd ~ && mkdir -p ~/tmp && cd ~/tmp && axel -n 8 https://storage.googleapis.com/golang/go1.4.3.freebsd-amd64.tar.gz && \
tar xfz go1.4.3.freebsd-amd64.tar.gz && mv go ~/bootstrap.go1.4.3.freebsd-amd64

export GOROOT_BOOTSTRAP=/home/david/bootstrap.go1.4.3.freebsd-amd64

#

cd ~ && git clone https://github.com/golang/go.git && cd go/src && ./all.bash

# --- FAIL: TestInterfaces (0.00s)
#    interface_test.go:74: route ip+net: invalid network interface name

ifi.Name= 
--- FAIL: TestInterfaces (0.00s)
    interface_test.go:75: route ip+net: invalid network interface name

mkdir -p /home/david/golibs

export PATH="$PATH:$HOME/go/bin"
export GOROOT=/home/david/go
export GOPATH=/home/david/golibs
export CGO_ENABLED=1

go env

GOARCH="amd64"
GOBIN=""
GOEXE=""
GOHOSTARCH="amd64"
GOHOSTOS="freebsd"
GOOS="freebsd"
GOPATH="/home/david/golibs"
GORACE=""
GOROOT="/home/david/go"
GOTOOLDIR="/home/david/go/pkg/tool/freebsd_amd64"
GO15VENDOREXPERIMENT="1"
CC="clang"
GOGCCFLAGS="-fPIC -m64 -pthread -fno-caret-diagnostics -Qunused-arguments -fmessage-length=0"
CXX="clang++"
CGO_ENABLED="1"

# install go tools
go get -v -t golang.org/x/tools/cmd/...

#
# liteide
#
go get -x -v -t github.com/visualfc/gotools
go get -t github.com/nsf/gocode

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/qt5/:/home/david/liteide/bin"

# http://stackoverflow.com/questions/30709056/libpng-warning-iccp-not-recognizing-known-srgb-profile-that-has-been-edited


# nfs server


cat <<'EOF' >> /etc/rc.conf
#
rpcbind_enable="YES"
nfs_server_enable="YES"
mountd_enable="YES"
mountd_flags="-r"
#
EOF


cat <<'EOF'> /etc/exports
# https://www.freebsd.org/doc/handbook/network-nfs.html
# the format is different with linux
# https://www.freebsd.org/cgi/man.cgi?query=exports&sektion=5&manpath=freebsd-release-ports
/home -alldirs -network 172.16.254.0 -mask 255.255.255.0
#
EOF

service nfsd restart

service mountd reload

showmount -e
