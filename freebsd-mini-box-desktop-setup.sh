#
# install 
#
# ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/amd64/amd64/ISO-IMAGES/11.0/FreeBSD-11.0-CURRENT-amd64-20151229-r292858-memstick.img
#

# https://cooltrainer.org/a-freebsd-desktop-howto/

#
# TODO: check https://www.banym.de/freebsd/install-freebsd-11-on-thinkpad-t420
#

#
# install desktop
#

#
# https://www.freebsd.org/doc/handbook/x11.html
#

pkg install -y xorg xfce gdm gnome3-lite xlockmore

#

cp /etc/X11/xorg.conf /etc/X11/xorg.conf.orig.$$

X -configure && cat /root/xorg.conf.new > /etc/X11/xorg.conf

# /etc/X11/xorg.conf for i5-box, using vesa

cat <<'EOF'> /etc/X11/xorg.conf
#
Section "ServerLayout"
	Identifier     "X.org Configured"
	Screen      0  "Screen0" 0 0
	#Screen      1  "Screen1" LeftOf "Screen0"
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
	Option	    "Protocol" "auto"
	Option	    "Device" "/dev/sysmouse"
	Option	    "ZAxisMapping" "4 5 6 7"
EndSection

Section "Monitor"
	Identifier   "Monitor0"
	VendorName   "Monitor Vendor"
	ModelName    "Monitor Model"
EndSection

Section "Device"
	Option "AccelMethod" "sna"
	Identifier  "Card0"
	#Driver      "intel"
	Driver      "vesa"
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

#
EOF


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
gdm_enable="YES"
gnome_enable="YES"
#
EOF

#
# UTF-8 and fcitx
#

locale -a

# https://fcitx-im.org/wiki/Configure_(Other)

#
#
#

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

LANG=en_US.UTF-8
LC_CTYPE="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_ALL=en_US.UTF-8

#
# fcitx impout
#

pkg install -y zh-fcitx zh-fcitx-googlepinyin zh-fcitx-table-extra zh-fcitx-configtool

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

# https://forums.freebsd.org/threads/xfce-how-to-start-xfce-in-freebsd.4627/

#
# configure for user rhinofly
#
# https://www.freebsd.org/doc/handbook/users-synopsis.html
#

sudo pw usermod rhinofly -s /usr/local/bin/bash

sudo pw groupmod video -m rhinofly 2>/dev/null || sudo pw groupmod wheel -m rhinofly

su - rhinofly

#
# config xfce startup
#


# for gdm/slim

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

#
exec /usr/local/bin/startxfce4" 
#
EOF

chmod +x ~/.xinitrc

# restore xfce4 setting
# rsync -a /home/rhinofly/.config/xfce4/ rhinofly@172.236.127.24:/home/rhinofly/.config/xfce4/ --delete

mkdir -p ${HOME}/.config/autostart/ && cp /usr/local/share/applications/fcitx.desktop  ${HOME}/.config/autostart/
echo '[[ $PS1 && -f /usr/local/share/bash-completion/bash_completion.sh ]] && source /usr/local/share/bash-completion/bash_completion.sh' >> ${HOME}//.env-all

wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O ${HOME}/.git-completion.bash
chmod +x ${HOME}/.git-completion.bash

echo 'test -x ${HOME}/.git-completion.bash && . ${HOME}/.git-completion.bash' >> ${HOME}//.env-all

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

#
# install applications by root
#
pkgloop install -y virtualbox-ose virtualbox-ose-additions virtualbox-ose-kmod chromium chromium-bsu meld firefox pinentry-curses pinentry-tty

#
# install https://github.com/jamiesonbecker/owa-user-agent/ if you access microsoft exchange OWA
#

#

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

pw groupmod vboxusers -m rhinofly
pw groupmod operator -m rhinofly
pw groupmod wheel -m rhinofly

#


#
# qt5 + liteide + Go
#

# root config, install qt5 gcc 4.8

pkg install -y qt5 qt5-qmake gcc qt5-sqldrivers-mysql qt5-sqldrivers-sqlite3 gdb

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
# Go lang in rhinofly
#

#
# Go bootstrap
#
cd ~ && mkdir -p ~/tmp && cd ~/tmp && axel -n 8 https://storage.googleapis.com/golang/go1.5.3.freebsd-amd64.tar.gz && \
tar xfz go1.5.3.freebsd-amd64.tar.gz && mv go ~/bootstrap.go1.5.3.freebsd-amd64

export GOROOT_BOOTSTRAP=/home/rhinofly/bootstrap.go1.5.3.freebsd-amd64

# or 1.4.3

cd ~ && mkdir -p ~/tmp && cd ~/tmp && axel -n 8 https://storage.googleapis.com/golang/go1.4.3.freebsd-amd64.tar.gz && \
tar xfz go1.4.3.freebsd-amd64.tar.gz && mv go ~/bootstrap.go1.4.3.freebsd-amd64

export GOROOT_BOOTSTRAP=/home/rhinofly/bootstrap.go1.4.3.freebsd-amd64

#

cd ~ && git clone https://github.com/golang/go.git && cd go/src && ./all.bash

# --- FAIL: TestInterfaces (0.00s)
#	interface_test.go:74: route ip+net: invalid network interface name

ifi.Name= 
--- FAIL: TestInterfaces (0.00s)
	interface_test.go:75: route ip+net: invalid network interface name

mkdir -p /home/rhinofly/golibs

export PATH="$PATH:$HOME/go/bin"
export GOROOT=/home/rhinofly/go
export GOPATH=/home/rhinofly/golibs
export CGO_ENABLED=1

go env

GOARCH="amd64"
GOBIN=""
GOEXE=""
GOHOSTARCH="amd64"
GOHOSTOS="freebsd"
GOOS="freebsd"
GOPATH="/home/rhinofly/golibs"
GORACE=""
GOROOT="/home/rhinofly/go"
GOTOOLDIR="/home/rhinofly/go/pkg/tool/freebsd_amd64"
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

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/qt5/:/home/rhinofly/liteide/bin"

# http://stackoverflow.com/questions/30709056/libpng-warning-iccp-not-recognizing-known-srgb-profile-that-has-been-edited


#
# run linux apps
#
# https://www.freebsd.org/doc/handbook/linuxemu.html
#
# FreeBSD provides 32-bit binary compatibility with Linux
#
