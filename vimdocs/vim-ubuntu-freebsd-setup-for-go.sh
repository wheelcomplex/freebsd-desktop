#!/usr/bin/env bash
#
# bootstrap:
# cd ${HOME} && mkdir -p ${HOME}/tmp/ && wget 'https://raw.githubusercontent.com/wheelcomplex/vimdocs/master/vim-ubuntu-freebsd-setup-for-go.sh' -O ${HOME}/tmp/vim-ubuntu-freebsd-setup-for-go.sh && chmod +x ${HOME}/tmp/vim-ubuntu-freebsd-setup-for-go.sh && ${HOME}/tmp/vim-ubuntu-freebsd-setup-for-go.sh
# update ~/.vimrc only
# bakdir="${HOME}/vim-back-wheelcomplex/`date +%Y-%m-%d-%H-%M-%S`/" &&mkdir -p "$bakdir"&& cp -a ${HOME}/.vimrc $bakdir/ && wget 'https://raw.githubusercontent.com/wheelcomplex/vimdocs/master/vimrc.txt' -O ${HOME}/.vimrc
#
#
#
# base on https://github.com/yourihua/Documents/blob/master/Vim/Mac%E4%B8%8B%E4%BD%BF%E7%94%A8Vim%E6%90%AD%E5%BB%BAGo%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83.mdown
#

if [ "$1" = 'debug' -a "$DEBUGVIMSETUP" != 'YES' ]
then
    export DEBUGVIMSETUP='YES'
    /bin/bash -x $0 $@
    exit $?
fi

echo "---- sudo test ----"
sudo true
if [ $? -ne 0 ]
	then
	echo "error: you need sudo to install packages"
	exit 1
fi

uname -a
isubuntu=0
isfreebsd=`uname -s| grep -ic freebsd`
if [ $isfreebsd -eq 0 ]
then
        cat /etc/issue.net 2>/dev/null
        isubuntu=`cat /etc/issue.net 2>/dev/null | grep -ci Ubuntu`
fi
if [ $isubuntu -eq 0 -a $isfreebsd -eq 0 ]
	then
	echo "error: this script support ubuntu/FreeBSD only."
	exit 1
fi
if [ `id -u` -eq 0 ]
	then
	echo "error: this script should no run by root."
	exit 1
fi

pkginscmd="apt- get install -y"
if [ $isfreebsd -ne 0 ]
then
        pkginscmd="pkg install -y"
fi

cmdok=`which git| wc -l`
if [ $cmdok -eq 0 ]
	then
	echo "warning: try to install git(git)"
	sudo $pkginscmd git
	if [ $? -ne 0 ]
		then
		echo "error: packages install failed: $pkglist"
		exit 1
	fi
fi

if [ $isfreebsd -eq 0 ]
then
	echo "installing python-dev for YouCompleteMe ..."
	sudo $pkginscmd python-dev
	if [ $? -ne 0 ]
		then
		echo "error: packages install failed: python-dev"
		exit 1
	fi
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


utils="hg:mercurial cmake vim meld gitk"
if [ $isfreebsd -ne 0 ]
then
	# gitk is include in git-gui
	utils="hg:mercurial cmake vim meld gitk:git-gui"
fi

pkglist=""
for aaa in $utils
do
	cmd=`echo "$aaa"|awk -F':' '{print $1}'`
	pkg=`echo "$aaa"|awk -F':' '{print $2}'`
	test -z "$pkg" && pkg="$cmd"
	cmdok=`which $cmd|grep -v "${HOME}"| wc -l`
	if [ $cmdok -eq 0 ]
		then
		echo "warning: try to install $pkg($cmd)"
		pkglist="$pkglist $pkg"
	fi
done
if [ -n "$pkglist" ]
	then
	sudo $pkginscmd $pkglist
	if [ $? -ne 0 ]
		then
		echo "error: packages install failed: $pkglist"
		exit 1
	fi
fi

vimcmd="/usr/bin/vim"

vim7tips="sudo sudo add-apt-repository ppa:vim-full/ppa && sudo apt-get update && sudo apt-get install vim"
if [ $isfreebsd -ne 0 ]
then
        vim7tips="please install/upgrade vim to 7.4+"
        vimcmd="/usr/local/bin/vim"
fi


if [ ! -x $vimcmd ]
	then
	echo "error: vim not installed."
    echo "TIPS: $vim7tips"
    exit 1
fi

vimverok=`$vimcmd --version | grep 'VIM - Vi IMproved 7.'| awk '{print $5}'| awk -F'.' '{print $1}'`
if [ $vimverok -eq 7 ]
then
        vimverok=`$vimcmd --version | grep -c 'VIM - Vi IMproved 7.'`
        if [ $vimverok -eq 0 ]
        	then
        	echo "error: this script support VIM - Vi IMproved 7.x only."
        	echo "TIPS: $vim7tips"
        	exit 1
        fi
        vimverok=`$vimcmd --version | grep 'VIM - Vi IMproved 7.'| awk '{print $5}'| awk -F'.' '{print $2}'`
        if [ $vimverok -le 3 ]
        	then
        	echo "error: this script support VIM - Vi IMproved 7.4 or later"
        	echo "TIPS: $vim7tips"
        	exit 1
        fi
elif [ $vimverok -lt 7 ]
then
	echo "error: this script support VIM - Vi IMproved 7.4 or later"
	echo "TIPS: $vim7tips"
	exit 1
fi

goenvok=`go env|wc -l`
if [ $goenvok -eq 0 ]
	then
	go env
	echo "error: Go environment no ready."
	echo "TIPS: https://golang.org/doc/install/source"
	exit 1
fi

echo "setup with Go environment:"
go env
echo "---"

cd ${HOME} 
backdir="vim-back-wheelcomplex/`date +%Y-%m-%d-%H-%M-%S`/" &&mkdir -p "${HOME}/$backdir"
if [ $? -ne 0 ]
	then
	echo "error: create backup directory failed: $backdir"
	exit 1
fi
needback=`ls -a ${HOME}/.vim* 2>/dev/null|wc -l`
if [ $needback -ne 0 ]
	then
	mv ${HOME}/.vim* "${HOME}/$backdir"
    test $? -ne 0 && echo "backup to ${HOME}/$backdir failed." && exit 1
    echo ""
    echo ""
    echo "${HOME}/.vim* backup to ${HOME}/$backdir ok"
    echo ""
    echo ""
    sleep 3
fi

gcmd="git clone https://github.com/gmarik/Vundle.vim ${HOME}/.vim/bundle/Vundle.vim"
$gcmd
if [ $? -ne 0 ]
	then
	echo "error: git clone bundle/Vundle.vim failed: $gcmd"
	exit 1
fi

gcmd="cp ${HOME}/tmp/vimdocs/vimrc.txt ${HOME}/.vimrc"
$gcmd
if [ $? -ne 0 ]
	then
	echo "error: create .vimrc failed: $gcmd"
	exit 1
fi

gcmd="$vimcmd +PluginInstall +qall"
$gcmd
if [ $? -ne 0 ]
	then
	echo "error: PluginInstall failed: $gcmd"
	exit 1
fi

gcmd="$vimcmd +GoInstallBinaries +qall"
$gcmd
if [ $? -ne 0 ]
	then
	echo "error: +GoInstallBinaries +qall failed: $gcmd"
	exit 1
fi
# vim +GoInstallBinaries +qall

# start Vim，and run command :PluginInstall
# :qall exit vim and compile YouCompleteMe

cd ${HOME}/.vim/bundle/YouCompleteMe && ./install.py
if [ $? -ne 0 ]
	then
	echo "error: YouCompleteMe compile failed"
	echo "TIPS: cd ${HOME}/.vim/bundle/YouCompleteMe && git submodule update --init --recursive && ./install.py"
	echo "TIPS: https://github.com/Valloric/YouCompleteMe"
	exit 1
fi

touch ${HOME}/.gitconfig > /dev/null 2>&1
mv ${HOME}/.gitconfig ${HOME}/${backdir}/
test $? -ne 0 && echo "${HOME}/.gitconfig backup to ${HOME}/$backdir failed." && exit 1
echo ""
echo ""
echo "${HOME}/.gitconfig backup to ${HOME}/$backdir ok"
echo ""
echo ""
sleep 3

gcmd="cp ${HOME}/tmp/vimdocs/gitconfig.txt ${HOME}/.gitconfig"
$gcmd
if [ $? -ne 0 ]
	then
	echo "error: create .gitconfig failed: $gcmd"
	exit 1
fi

echo "setup /usr/bin/meld.git ..."
rootgrp='root'
test $isfreebsd -ne 0 && rootgrp='wheel'
sudo cp ${HOME}/tmp/vimdocs/meld.git /usr/bin/ && sudo chmod 0655 /usr/bin/meld.git && sudo chown root:$rootgrp /usr/bin/meld.git
if [ $? -ne 0 ]
	then
	echo "error: create /usr/bin/meld.git failed."
	exit 1
fi
#

echo "---"
echo "    setup gitconfig ..."
echo "---"
sleep 3
if [ -s ${HOME}/$backdir/.gitconfig ]
then
	meld ${HOME}/.gitconfig ${HOME}/$backdir/.gitconfig
else
	$vimcmd ${HOME}/.gitconfig
fi

echo "ALL DONE!"
cat ${HOME}/tmp/vimdocs/vim-tips.txt
#cd - >/dev/null 2>&1
#
