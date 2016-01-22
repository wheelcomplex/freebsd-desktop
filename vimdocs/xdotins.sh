#!/bin/bash
#
# bootstrap:
# cd ${HOME} && mkdir -p ${HOME}/tmp/ && wget 'https://raw.githubusercontent.com/wheelcomplex/vimdocs/master/xdotins.sh' -O ${HOME}/tmp/xdotins.sh && chmod +x ${HOME}/tmp/xdotins.sh && ${HOME}/tmp/xdotins.sh
#

if [ "$1" = 'debug' -a "$DEBUGVIMSETUP" != 'YES' ]
then
    export DEBUGVIMSETUP='YES'
    /bin/bash -x $0 $@
    exit $?
fi

sudo true
if [ $? -ne 0 ]
	then
	echo "error: you need sudo to install xdot"
	exit 1
fi

utils="xdot"

pkglist=""
for aaa in $utils
do
	cmd=`echo "$aaa"|awk -F':' '{print $1}'`
	pkg=`echo "$aaa"|awk -F':' '{print $2}'`
	test -z "$pkg" && pkg="$cmd"
	cmdok=`which $cmd| wc -l`
	if [ $cmdok -eq 0 ]
		then
		echo "warning: try to install $pkg($cmd)"
		pkglist="$pkglist $pkg"
	fi
done
if [ -n "$pkglist" ]
	then
	sudo apt-get -y install $pkglist
	if [ $? -ne 0 ]
		then
		echo "error: packages install failed: $pkglist"
		exit 1
	fi
fi

cat /etc/issue.net
isubuntu=`cat /etc/issue.net| grep -ci Ubuntu`
if [ $isubuntu -eq 0 ]
	then
	echo "error: this script support ubuntu only."
	exit 1
fi
if [ `id -u` -eq 0 ]
	then
	echo "error: this script should no run by root."
	exit 1
fi

if [ "$VIMSETUPNEW" != 'YES' ]
then
	gcmd="git clone https://github.com/wheelcomplex/vimdocs.git ${HOME}/tmp/vimdocs/"
	rm -rf ${HOME}/tmp/vimdocs && mkdir -p ${HOME}/tmp/ && $gcmd
	if [ $? -ne 0 ]
		then
		echo "error: git clone failed: $gcmd"
		exit 1
	fi
    export VIMSETUPNEW='YES'
    gcmd="${HOME}/tmp/vimdocs/`basename $0`"
    chmod +x $gcmd
    echo "Run script from git: $gcmd"
    if [ "$DEBUGVIMSETUP" = 'YES' ]
    then
        /bin/bash -x $gcmd $@
        exit $?
    fi
    $gcmd $@
    exit $?
fi

sudo cp ${HOME}/tmp/vimdocs/fixdot /usr/bin/ && sudo chmod 0655 /usr/bin/fixdot && sudo chown root:root /usr/bin/fixdot
if [ $? -ne 0 ]
	then
	echo "error: create /usr/bin/fixdot failed."
	exit 1
fi
echo "ALL DONE!"
#cd - >/dev/null 2>&1
#
