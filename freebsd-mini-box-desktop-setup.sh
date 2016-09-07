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

# mini X

pkgloop install -y git-gui meld  pinentry-curses pinentry-tty geany jpeg-turbo xv

pkgloop install -y virt-viewer chromium firefox openjdk icedtea-web

# for armv6 rpi2
# pkgloop install -y git-gui meld pinentry-curses pinentry-tty geany jpeg-turbo xv

#
# https://www.freebsd.org/doc/handbook/x11.html
#

# pkgloop is alias/script of pkg

allxfce4=`pkg search xfce | grep '^xfce' | awk '{print $1}'`

pkgloop install -y ${allxfce4} xorg xf86-video-scfb xdm slim xlockmore zh-fcitx zh-fcitx-googlepinyin \
zh-fcitx-table-extra zh-fcitx-configtool gnome3-lite

pkgloop install -y virtualbox-ose libreoffice

# virtualbox-ose-additions virtualbox-ose-kmod

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

# sudo pkgloop install -y gnome3-lite

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
# xdm/gnome start on boot
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

cat <<'EOF' >> /usr/local/etc/slim.conf
#
default_user    rhinofly
focus_password    yes
#
#
EOF

#
# should already exist
#
mkdir -p /usr/local/share/xsessions/
test ! -f /usr/local/share/xsessions/xfce.desktop && cat <<'EOF' > /usr/local/share/xsessions/xfce.desktop
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

pw groupmod vboxusers -m rhinofly
pw groupmod operator -m rhinofly
pw groupmod wheel -m rhinofly
pw groupmod dialer -m rhinofly
id rhinofly

# reboot to take effect

#
# fcitx
#

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
    fcitx -r -d
else
    echo "Fcitx is running correctly."
fi
EOF

chmod +x /usr/bin/fcitx-autostart

#
# NOTE:
#      for xfce4-terminal, right-click mouse and select Input Methods-> fcitx to active chinese input
#      or pkg remove ibus to make fcitx to default input method

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
# configure for user rhinofly
#
# https://www.freebsd.org/doc/handbook/users-synopsis.html
#

pw usermod rhinofly -s /usr/local/bin/bash
pw groupmod video -m rhinofly 2>/dev/null || sudo pw groupmod wheel -m rhinofly

#
# config xfce startup as rhinofly
#

su - rhinofly

# http://stackoverflow.com/questions/17846529/could-not-open-a-connection-to-your-authentication-agent
# fix ssh-copyid: no keys found
test ! -f .ssh/id_rsa && ssh-keygen

ssh-add && ssh-add -L


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
# rsync -a /home/rhinofly/.config/xfce4/ rhinofly@172.236.127.24:/home/rhinofly/.config/xfce4/ --delete

mkdir -p ${HOME}/.config/autostart/ && cp /usr/local/share/applications/fcitx.desktop  ${HOME}/.config/autostart/

echo '[[ $PS1 && -f /usr/local/share/bash-completion/bash_completion.sh ]] && source /usr/local/share/bash-completion/bash_completion.sh' >> ${HOME}//.env-all

wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O ${HOME}/.git-completion.bash
chmod +x ${HOME}/.git-completion.bash

echo 'test -x ${HOME}/.git-completion.bash && . ${HOME}/.git-completion.bash' >> ${HOME}//.env-all

#
#
# done =-========================
#

#
# remote desktop
#

sudo pkgloop install -y xrdp-devel

Message from xrdp-devel-0.7.0.b20130912_3,1:
==============================================================================

XRDP has been installed.

There is an rc.d script, so the service can be enabled by adding this line
in /etc/rc.conf:

xrdp_enable="YES"
xrdp_sesman_enable="YES" # if you want to run xrdp-sesman on the same machine

Do not forget to edit the configuration files in "/usr/local/etc/xrdp"
and the "/usr/local/etc/xrdp/startwm.sh" script.

==============================================================================

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

sudo pkgloop install -y rdesktop

cat <<'EOF' > ~/bin/xremote.sh
#!/bin/bash
#
# note: use ctl+alt+enter to switch between full-screen
#

REMOTEUSER="rhinofly"
REMOTEPASSWORD="remotepasswd"
REMOTEHOST="10.236.12.201"
disp="1920x1080"
#rdesktop -k en-us -D -u $REMOTEUSER -p $REMOTEPASSWORD -z -r clipboard:PRIMARYCLIPBOARD -s /usr/bin/xfce4-session -g $disp $REMOTEHOST &
rdesktop -f -k en-us -D -u $REMOTEUSER -p $REMOTEPASSWORD -z -r clipboard:PRIMARYCLIPBOARD -g $disp $REMOTEHOST &

EOF

chmod +x ~/bin/xremote.sh



# -----------

#
# qt5 + liteide + Go
#

# root config, install qt5 gcc 4.8

pkgloop install -y qt5 qt5-qmake gcc qt5-sqldrivers-mysql qt5-sqldrivers-sqlite3 gdb

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
#    interface_test.go:74: route ip+net: invalid network interface name

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
