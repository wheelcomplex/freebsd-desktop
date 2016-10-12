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

# allow wheel group sudo

sh -c 'ASSUME_ALWAYS_YES=yes pkg bootstrap -f' && pkg install -f -y bash wget sudo rsync && ln -f /usr/local/bin/bash /bin/bash;\
mount -t fdescfs fdesc /dev/fd && echo '%wheel ALL=(ALL) ALL' >> /usr/local/etc/sudoers && \
cat /usr/local/etc/sudoers|tail -n 10 && df -h

# cd /usr/ports/shells/bash && make install clean

bash

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
# rhinofly login with bash
#

test -x /usr/local/bin/bash && pw usermod rhinofly -s /usr/local/bin/bash || pw usermod rhinofly -s /bin/sh

mkdir -p /usr/local/sbin/ 

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
if [ "$act" != 'install' -a "$act" != 'fetch' ]
then
    pkg $@
    exit $?
fi
shift

test "$1" = '-y' && shift

target="$@"

echo "fast pkg ${act}ing $target ..."

tmpfile="/tmp/fastpkg.$$.list"
echo "n" | pkg install $target > $tmpfile 2>&1

list=`cat $tmpfile | grep -A 1000 "to be INSTALLED:"| grep -v "to be INSTALLED:"| grep -v 'Installed packages to be REINSTALLED:'| grep -v "The process will"|grep -v "to be downloaded."| grep -v "Proceed with this action"| grep -v 'ABI changed'| grep -v 'Number of packages to be'|awk -F': ' '{print $1}'| grep -v '^$'|awk '{print $1}'`;
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
                ps axuww| grep 'pkg fetch' | grep -v grep | awk -F'-y ' '{print $2}'
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
pkg install -y $target
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

pkgloop install -y sudo pciutils usbutils vim rsync cpuflags axel git-gui wget ca_root_nss subversion pstree bind-tools pigz gtar dot2tex unzip xauth && \
pkgloop install -y bash-completion

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
camcontrol identify /dev/da0

gpart show da0

# check for TRIM support in ufs
tunefs -p /dev/da0p1

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

cat <<EOF>> /boot/loader.conf
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

# OR

cat <<EOF>> /boot/loader.conf
# wait for storage, in ms
kern.cam.boot_delay=10000
kern.cam.scsi_delay=10000
# vfs.mountroot.timeout in second
vfs.mountroot.timeout=15
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
kld_list="geom_uzip if_bridge bridgestp fdescfs linux linprocfs wlan_xauth snd_driver coretemp vboxdrv"
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
pf_enable="YES"                 # Set to YES to enable packet filter (pf)
pf_rules="/etc/pf.conf"         # rules definition file for pf
pf_program="/sbin/pfctl"        # where the pfctl program lives
pf_flags=""                     # additional flags for pfctl
pflog_enable="YES"              # Set to YES to enable packet filter logging
pflog_logfile="/var/log/pflog"  # where pflogd should store the logfile
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
#
EOF

# create
test -f /etc/rc.local && mv /etc/rc.local /etc/rc.local.orig.$$

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
# wlanmode hostap fpr softap, sta for wifi client
#    /sbin/ifaceboot wlan0 ath0 wlanmode sta up
#    /sbin/ifconfig wlan0 txpower 5
#
#    /sbin/ifaceboot bridge0 addm em1 addm em2 addm em3 addm wlan0 inet 172.236.150.43/24
#
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
dhcp-range=172.236.150.51,172.236.150.90,2400h
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
# or
# chflags 0 /etc/resolv.conf

#

/usr/local/etc/rc.d/dnsmasq restart

sleep 1 && tail -n 20 /var/log/messages

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

# convert GBK filename to utf-8
# http://unix.stackexchange.com/questions/290713/how-to-convert-gbk-to-utf-8-in-a-mixed-encoding-directory
# http://edyfox.codecarver.org/html/linux_gbk2utf8.html

pkg install -y convmv

# convmv -f gbk -t utf8 *
# convmv -r -f gbk -t utf-8 --notest *

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

rm -rf /usr/src && mkdir -p /usr/src/ && git clone https://github.com/freebsd/freebsd.git /usr/src

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

# ssh remote forward
# https://help.ubuntu.com/community/SSH/OpenSSH/PortForwarding
# need GatewayPorts yes in /etc/ssh/sshd_config for 0.0.0.0:8822
# ssh -f -N -n -T -R 0.0.0.0:8822:10.236.150.26:22 public-ssh-server
# ssh -f -N -n -T -R 0.0.0.0:9922:10.236.150.21:22 public-ssh-server
