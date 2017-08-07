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





