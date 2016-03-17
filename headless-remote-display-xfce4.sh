
#
# http://docs.xfce.org/xfce/xfce4-session/advanced
# https://wiki.gentoo.org/wiki/X_without_Display_Manager
# Auto login from console, Instead of using a desktop manager, you can also auto login from the console.
#


#
# X server 10.236.12.200
# X client 10.236.12.201
# account rhinofly



#
# X server ----- setup
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
    decho "LOOP#$cnt: pkg $@"
    sleep 1
done
exit $exitcode
#
EOF

chmod +x /usr/local/sbin/pkgloop

pkg bootstrap

# base pkg

pkgloop install -y bash bash-completion sudo pciutils usbutils git vim-lite rsync cpuflags axel wget pstree bind-tools pigz gtar

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
hostname="yinjiajin-networking-800200.localdomain"

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


#
# reboot
#

#
# https://www.freebsd.org/doc/handbook/x11.html
#

# pkgloop is alias/script of pkg

# pkg for x server

pkgloop install -y xorg hal xf86-input-keyboard

#
# install https://github.com/jamiesonbecker/owa-user-agent/ if you access microsoft exchange OWA
#

#

cp /etc/X11/xorg.conf /etc/X11/xorg.conf.orig.$$

X -configure && cat /root/xorg.conf.new > /etc/X11/xorg.conf

cat /etc/X11/xorg.conf

# /etc/X11/xorg.conf for i5-box, using vesa

# for asus ul30a + dell 2412m
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
    Driver      "intel"
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
# check X driver status in X
#
glxinfo | grep -C 3 vendor
glxinfo | grep -C 3 render

glxgears

#########  Do _NOT_ use /etc/ttys to start gdm at boot time.  This will result in gdm
#########  hanging or restarting constantly. Instead, add gdm_enable="YES" to
#########  /etc/rc.conf. GDM will be started automatic on the next reboot.

#
# gdm start on boot
#

cat <<EOF>> /etc/rc.conf
#
dbus_enable="YES"
hald_enable="YES"
#
# note: do not start gdm/gnome for X server side
#
gdm_enable="NO"
gnome_enable="NO"
#
EOF

# setup xauth of X server
#
# https://computing.llnl.gov/?set=access&page=xauth
# http://www.biac.duke.edu/library/documentation/xwin32/security.html#xauth
#

# start X server with auth, by user xremote

pw groupadd xremote
pw useradd -m -d /home/xremote -s /usr/local/bin/bash -n xremote

test -x /usr/local/bin/bash && pw usermod xremote -s /usr/local/bin/bash

#
# config x server by xremote
# https://www.freebsd.org/cgi/man.cgi?query=xinit&sektion=1&apropos=0&manpath=XFree86+4.7.0

su - xremote

cat <<'EOF' > ${HOME}/.xserver.conf
# user:host[:homedir][:xserverhost]
#XCLIENTS="rhinofly:10.236.12.201 rhinofly:127.0.0.1:/home/rhinofly/home"
XCLIENTS="rhinofly:10.236.12.201 rhinofly:127.0.0.1:"
#
EOF

#
# .xserverinitrc
#

cat <<'EOF' > ${HOME}/.xserverinitrc
#!/bin/sh
decho(){
    local msg=$@
    test -n "$msg" && echo "`date` $msg" && return 0
    echo "`date`"
}

decho "info: X server initrc :$XSERVERPORT auth by ${XAUTHORITY} for $XREMOTES at vt$XVTNUM ..."

for xcl in $XREMOTES
do
    # TODO: select one of remotes to connect by tls agent
    
    xclientuser=`echo $xcl|awk -F':' '{print $1}'`
    xclienthost=`echo $xcl|awk -F':' '{print $2}'`
    xclienthome=`echo $xcl|awk -F':' '{print $3}'`
    xserverhost=`echo $xcl|awk -F':' '{print $4}'`
    if [ -z "$xclientuser" -o -z "$xclienthost" ]
    then
        decho "warning: ignored invalid client define(user or host no defined): $xcl"
        continue
    fi
    
    REMOTECMD="ssh $xclientuser@$xclienthost DISPLAY=$xserverhost:$XSERVERPORT XAUTHORITY=${xclienthome}/.XremoteAuthority ${xclienthome}/.remotexsession"

    echo "launch: $REMOTECMD"

done

decho "PRESS <ctl-c> to exit ..."
while [ : ]
do
    sleep 1 || break
done
echo ""
#$REMOTECMD

echo "exit from $XREMOTES"
#
EOF

chmod +x ${HOME}/.xserverinitrc

#
# start X server by xremote, using xinit
#
mkdir -p ${HOME}/bin/

cat <<'EOF' > ${HOME}/bin/xserverstart
#!/usr/bin/env bash
#
# ssh to client host and launch startxfce4
#
decho(){
    local msg=$@
    test -n "$msg" && echo "`date` $msg" && return 0
    echo "`date`"
}
#
if [ ! -s ${HOME}/.xserver.conf ]
then
    decho "${HOME}/.xserver.conf no existed of empty."
    exit 1
fi

. ${HOME}/.xserver.conf

decho "using ${HOME}/.xserver.conf for $XCLIENTS ..."

# ----

# probe unused vt, otherwise keyboard input will not functioned

XVTNUM=`ps axuww| grep tty | grep ttyv | grep -v grep | awk '{print $13}'| tail -n 1| tr -d 'a-zA-Z'`
test -z "$XVTNUM" && XVTNUM=5
let XVTNUM=$XVTNUM+2

for nvt in `seq $XVTNUM 30`
do
    ps axuww| grep -i xorg | grep -v grep| grep -iq " vt${XVTNUM}"
    t1=$?
    ps axuww| grep -i xorg | grep -v grep| grep -iq " vt0${XVTNUM}"
    t2=$?
    test $t1 -ne 0 -a $t2 -ne 0 && break
    let XVTNUM=$XVTNUM+1
done

if [ $XVTNUM -le 9 ]
then
    XVTNUM="0${XVTNUM}"
fi
export XVTNUM

# ----

XSERVERPORT=""
xstartport=10
for num in 0 1 2 3 4 5 6 7 8 9 
do
    sockstat -l | grep -q ":60$xstartport "
    test $? -ne 0 && XSERVERPORT=$xstartport && break
    echo "debug: $xstartport in used"
    sockstat -l | grep ":60$xstartport "
    let xstartport=$xstartport+1
done
if [ -z "$XSERVERPORT" ]
then
    decho "error: all tcp port 6010 - 6019 in used."
    exit 1
fi

export XAUTHORITY=${HOME}/.XserverAuthority.${XVTNUM}.${XSERVERPORT}
export DISPLAY=:$XSERVERPORT

cookie=""
for aaa in `seq 1 1000`
do
    cookie=`echo -e "obase=16\n$RANDOM^8" | bc` && cat /dev/null > ${XAUTHORITY} && \
    xauth -f ${XAUTHORITY} -v add 127.0.0.1:$XSERVERPORT . $cookie && \
    xauth -f ${XAUTHORITY} -v add :$XSERVERPORT . $cookie
    if [ $? -eq 0 ]
    then
        xauth -f ${XAUTHORITY} -vn list
        break
    fi
    xauth -f ${XAUTHORITY} -v add :$XSERVERPORT . $cookie 2>&1 | grep -q -- 'key contains odd number of or non-hex characters'
    if [ $? -ne 0 ]
    then
        cookie=""
        break
    fi
    cookie=""
    sleep 1
done
if [ -z "$cookie" ]
then
    decho "error: create ${XAUTHORITY} failed."
    exit 1
fi

# ----
export mypid=$$
export XREMOTES=""

# user:host[:homedir][:xserverhost]
# XCLIENTS="rhinofly:10.236.12.201 rhinofly:127.0.0.1:/home/rhinofly"

for xcl in $XCLIENTS
do
    
    # TODO: replace ssh by tls agent
    
    xclientuser=`echo $xcl|awk -F':' '{print $1}'`
    xclienthost=`echo $xcl|awk -F':' '{print $2}'`
    xclienthome=`echo $xcl|awk -F':' '{print $3}'`
    xserverhost=`echo $xcl|awk -F':' '{print $4}'`
    if [ -z "$xclientuser" -o -z "$xclienthost" ]
    then
        decho "warning: ignored invalid client define(user or host no defined): $xcl"
        continue
    fi
    
    # SSH_CONNECTION=10.236.127.34 63953 10.236.12.12 22
    (ssh $xclientuser@$xclienthost env) > ${HOME}/.xssh.${mypid}.log
    echo "${HOME}/.xssh.${mypid}.log"

    cat ${HOME}/.xssh.${mypid}.log

    test -z "$xserverhost" && xserverhost=`cat ${HOME}/.xssh.${mypid}.log | grep 'SSH_CONNECTION=' | tr '=' ' ' | awk '{print $2}'`
    if [ -z "$xserverhost" ]
    then
        decho "error: probe server ip for $xclientuser@$xclienthost failed."
        continue
    fi
    # HOME=/home/rhinofly/home
    test -z "$xclienthome" && xclienthome=`cat ${HOME}/.xssh.${mypid}.log |grep "^HOME="|awk -F'=' '{print $2}'`
    if [ -z "$xclienthome" ]
    then
        decho "error: probe HOME of $xclientuser@$xclienthost failed."
        continue
    fi
    rm -f ${HOME}/.xssh.${mypid}.log
    # copy cookie to client
    xauth -f ${XAUTHORITY} -v add $xserverhost:$XSERVERPORT . $cookie && \
    xauth -f ${XAUTHORITY} extract - $xserverhost:$XSERVERPORT  | ssh $xclientuser@$xclienthost xauth -f ${xclienthome}/.XremoteAuthority -v merge - && ssh $xclientuser@$xclienthost xauth -f ${xclienthome}/.XremoteAuthority -vn list
    if [ $? -ne 0 ]
    then
        decho "error: send .XremoteAuthority to $xclientuser@$xclienthost failed."
        continue
    fi
    xclinfo="${xclientuser}:${xclienthost}:${xclienthome}:${xserverhost}"
    if [ -z "$XREMOTES" ]
    then
        XREMOTES="$xclinfo"
    else
        XREMOTES="$XREMOTES $xclinfo"
    fi
done

if [ -z "$XREMOTES" ]
then
    decho "error: no XCLIENTS defined in ${HOME}/.xserver.conf."
    exit 1
fi

decho "info: X server :$XSERVERPORT auth by ${XAUTHORITY} for $XREMOTES at vt$XVTNUM ..."

export XSERVERPORT
export XAUTHORITY=${HOME}/.XserverAuthority
export DISPLAY=:$XSERVERPORT
export XVTNUM=$XVTNUM

env | grep "^X"
env | grep "^DISP"
XCMD="xinit ${HOME}/.xserverinitrc -- :$XSERVERPORT -listen tcp -background none -noreset -verbose -auth ${XAUTHORITY} vt${XVTNUM}"
echo "XCMD: $XCMD"
$XCMD
exit $?
#
EOF

chmod +x ${HOME}/bin/xserverstart

${HOME}/bin/xserverstart

#
# ------ client
#


# pkg for x client, without xorg/gdm

sudo pkgloop install -y xfce gnome3-lite xlockmore chromium chromium-bsu meld firefox pinentry-curses pinentry-tty zh-fcitx zh-fcitx-googlepinyin zh-fcitx-table-extra zh-fcitx-configtool geany virtualbox-ose virtualbox-ose-additions virtualbox-ose-kmod libreoffice

cat <<EOF>> /etc/rc.conf
#
dbus_enable="YES"
hald_enable="YES"
#
# note: do not start gdm/gnome from rc.conf
#
gdm_enable="NO"
gnome_enable="NO"
#
EOF


cp -a /etc/profile /etc/profile.orig.$$

# NOTE: overwrite
cat <<'EOF' > /etc/profile
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

export LANG="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"
export LC_TIME="en_US.UTF-8"
export LC_NUMERIC="en_US.UTF-8"
export LC_MONETARY="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

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

# LANG=en_US.UTF-8
# LC_CTYPE="en_US.UTF-8"
# LC_COLLATE="en_US.UTF-8"
# LC_TIME="en_US.UTF-8"
# LC_NUMERIC="en_US.UTF-8"
# LC_MONETARY="en_US.UTF-8"
# LC_MESSAGES="en_US.UTF-8"
# LC_ALL=en_US.UTF-8

#
# configure fcitx input
#

cat <<'EOF' > /usr/bin/fcitx-autostart
#!/bin/sh

# sleep for a little while to avoid duplicate startup
sleep 2

# Test whether fcitx is running correctly with dbus...
fcitx-remote > /dev/null 2>&1

if [ $? = "1" ]; then
    echo "Fcitx seems is not running"
    fcitx
else
    echo "Fcitx is running correctly."
fi
EOF

chmod +x /usr/bin/fcitx-autostart

sudo pw usermod rhinofly -s /usr/local/bin/bash

sudo pw groupmod video -m rhinofly 2>/dev/null || sudo pw groupmod wheel -m rhinofly

su - rhinofly

# https://forums.freebsd.org/threads/xfce-how-to-start-xfce-in-freebsd.4627/

#
# configure for user rhinofly
#
# https://www.freebsd.org/doc/handbook/users-synopsis.html
#

#
# config xfce startup as rhinofly
#

# restore xfce4 setting
# rsync -a /home/rhinofly/.config/xfce4/ rhinofly@172.236.127.24:/home/rhinofly/.config/xfce4/ --delete

mkdir -p ${HOME}/.config/autostart/ && cp /usr/local/share/applications/fcitx.desktop  ${HOME}/.config/autostart/

cat <<'EOF' > ~/.loadxsession
#!/usr/bin/env bash
#
# NOTE: PATH resetted
#
test -s /etc/profile && source /etc/profile
#
test -s ${HOME}/.env-all && source ${HOME}/.env-all
#
decho(){
    local msg=$@
    test -n "$msg" && echo "`date` $msg" && return 0
    echo "`date`"
}

# fcitx -d &
/usr/bin/fcitx-autostart

echo "------"

env | grep "^X"
env | grep "^DISP"

echo "------"

if [ -x /usr/local/etc/xdg/xfce4/xinitrc ]
then
   /bin/sh /usr/local/etc/xdg/xfce4/xinitrc
   exit $?
fi

which startxfce4
if [ $? -eq 0 ]
then
   startxfce4
   exit $?
fi

which startx
if [ $? -eq 0 ]
then
   startx
   exit $?
fi

echo ""
echo " ------ ERROR: startxfce4/startx no found, please install xfce by: sudo pkg install -y xfce"
echo ""
sleep 30
exit 1
#
EOF

chmod +x ~/.loadxsession

#

cat <<'EOF' > ~/.remotexsession
#!/usr/bin/env bash
#
# NOTE: PATH resetted
#
export XCLIENTPID=$$
#
decho(){
    local msg=$@
    test -n "$msg" && echo "`date` $msg" && return 0
    echo "`date`"
}

echo "------"

env | grep "^X"
env | grep "^DISP"

which xfce4-session
if [ $? -ne 0 ]
then
    decho "error: xfce4-session no found, you should install it by: sudo pkg install -y xfce"
    exit 1
fi

nohup ~/.loadxsession >~/.loadxsession.log 2>&1 &

decho "[$$] waiting for xsession start ..."
sesspid=""
for aaa in `seq 1 30`
do
    sesspid=`timeout -s 15 -k 5 --preserve-status --foreground 1 ps axuww | grep -- " xfce4-session$" | grep -v grep | grep -v ' --' | grep -v -- '-launch' | awk '{print $2}'|head -n 1`
    if [ -n "$sesspid" ]
    then
        echo ""
        decho "[$$] xfce4-session $sesspid started."
        break
    fi
    echo -n "."
    sleep 1
done
echo ""
if [ -z "$sesspid" ]
then
    cat ~/.loadxsession.log
    echo "---"
    decho "error: [$$] xfce4-session $sesspid start failed."
    exit 1
fi
echo "---"
cat ~/.loadxsession.log

decho "[$$] waiting for xsession exit ..."
sleep 1
while [ : ]
do
    timeout -s 15 -k 5 --preserve-status --foreground 1 ps axuww | grep -- "  $sesspid " | grep -qv grep
    if [ $? -ne 0 ]
    then
        echo ""
        decho "[$$] xfce4-session $sesspid exited."
        break
    fi
    sleep 1
done
echo ""
echo "---"
cat ~/.loadxsession.log
echo ""
echo "---"
decho "[$$] xfce4-session $sesspid exited."
#
EOF

chmod +x ~/.remotexsession

#

TODO: remote agent
TODO: XDM tcp compress with snappy
BUG: no KB
