#!/usr/bin/env bash
#
# bootstrap:
# which git || sudo pkg install -y git-lite || sudo apt-get install -y git;rm -rf ${HOME}/tmp/freebsd-desktop/ && cd ${HOME} && mkdir -p ${HOME}/tmp/ && git clone https://github.com/wheelcomplex/freebsd-desktop.git ${HOME}/tmp/freebsd-desktop/ && ${HOME}/tmp/freebsd-desktop/vimdocs/vim-ubuntu-freebsd-setup-for-go.sh
#
# base on https://github.com/yourihua/Documents/blob/master/Vim/Mac%E4%B8%8B%E4%BD%BF%E7%94%A8Vim%E6%90%AD%E5%BB%BAGo%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83.mdown
#

if [ "$1" = 'debug' -a "$DEBUGVIMSETUP" != 'YES' ]
then
    export DEBUGVIMSETUP='YES'
    /bin/bash -x $0 $@
    exit $?
fi

if [ -z "$DISPLAY" ]
then
    echo "error: can not run without X DISPLAY"
    exit 1
fi

echo "---- sudo test ----"
sudo true
if [ $? -ne 0 ]
	then
	echo "error: you need sudo to install packages"
	exit 1
fi

# stop old daemon
killall gocode 2>/dev/null

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

pkginscmd="apt-get install -y"
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

utils="hg:mercurial vim meld gitk"
if [ $isfreebsd -ne 0 ]
then
	# gitk is include in git-gui
	utils="hg:mercurial vim meld gitk:git-gui"
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

# golang.org/x/tools/go/exact
# golang.org/x/tools/cmd/vet/whitelist
# golang.org/x/tools/go/gcimporter
# golang.org/x/tools/go/gccgoimporter
# golang.org/x/tools/cmd/vet
# golang.org/x/tools/go/types
# golang.org/x/tools/go/importer


gotools='
golang.org/x/tools/godoc/static
golang.org/x/tools/benchmark/parse
golang.org/x/tools/container/intsets
golang.org/x/tools/go/ast/astutil
golang.org/x/tools/go/buildutil
golang.org/x/tools/cover
golang.org/x/tools/cmd/digraph
golang.org/x/tools/cmd/fiximports
golang.org/x/tools/cmd/benchcmp
golang.org/x/tools/cmd/cover
golang.org/x/tools/blog/atom
golang.org/x/tools/present
golang.org/x/tools/godoc/vfs
golang.org/x/tools/godoc/redirect
golang.org/x/tools/godoc/util
golang.org/x/tools/godoc/vfs/httpfs
golang.org/x/tools/godoc/vfs/gatefs
golang.org/x/tools/godoc/vfs/mapfs
golang.org/x/tools/blog
golang.org/x/tools/godoc/vfs/zipfs
golang.org/x/tools/playground
golang.org/x/tools/imports
golang.org/x/tools/refactor/importgraph
golang.org/x/tools/cmd/gotype
golang.org/x/tools/cmd/html2article
golang.org/x/tools/oracle/serial
golang.org/x/tools/playground/socket
golang.org/x/tools/cmd/stress
golang.org/x/tools/cmd/tip
golang.org/x/tools/cmd/present
golang.org/x/tools/cmd/goimports
golang.org/x/tools/refactor/eg
golang.org/x/tools/go/types/typeutil
golang.org/x/tools/go/loader
golang.org/x/tools/go/ssa
golang.org/x/tools/refactor/satisfy
golang.org/x/tools/cmd/stringer
golang.org/x/tools/cmd/bundle
golang.org/x/tools/cmd/eg
golang.org/x/tools/refactor/rename
golang.org/x/tools/cmd/godex
golang.org/x/tools/cmd/gomvpkg
golang.org/x/tools/cmd/gorename
golang.org/x/tools/go/callgraph
golang.org/x/tools/go/ssa/ssautil
golang.org/x/tools/go/ssa/interp
golang.org/x/tools/go/callgraph/rta
golang.org/x/tools/go/pointer
golang.org/x/tools/go/callgraph/cha
golang.org/x/tools/go/callgraph/static
golang.org/x/tools/cmd/ssadump
golang.org/x/tools/godoc/analysis
golang.org/x/tools/cmd/callgraph
golang.org/x/tools/oracle
golang.org/x/tools/godoc
golang.org/x/tools/cmd/oracle
golang.org/x/tools/cmd/godoc
github.com/nsf/gocode
github.com/alecthomas/gometalinter
golang.org/x/tools/cmd/goimports
golang.org/x/tools/cmd/guru
golang.org/x/tools/cmd/gorename
github.com/golang/lint/golint
github.com/kisielk/errcheck
github.com/jstemmer/gotags
github.com/klauspost/asmfmt/cmd/asmfmt
github.com/fatih/motion
github.com/zmb3/gogetdoc
'
for aaa in $gotools
do
    echo "installing $aaa ..."
gcmd="go get -v $aaa"
$gcmd || proxychains $gcmd
if [ $? -ne 0 ]
then
	echo "error: $gcmd failed, try to update ..."
gcmd="go get -u -v $aaa"
$gcmd || proxychains $gcmd
if [ $? -ne 0 ]
then
	echo "error: $gcmd failed."
fi
fi
gcmd="go install -v $aaa"
$gcmd || proxychains $gcmd
if [ $? -ne 0 ]
then
	echo "error: $gcmd failed."
fi
done

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
    mkdir -p ${HOME}/$backdir && \
    cp -a ${HOME}/.vim* ${HOME}/$backdir/
    test $? -ne 0 && echo "backup to ${HOME}/$backdir failed." && exit 1
    echo ""
    echo ""
    echo "${HOME}/.vim* backup to ${HOME}/$backdir ok"
    echo ""
    echo ""
    sleep 3
fi
rm -rf ${HOME}/.vim/*

gcmd="git clone https://github.com/gmarik/Vundle.vim ${HOME}/.vim/bundle/Vundle.vim"
$gcmd
if [ $? -ne 0 ]
	then
	echo "error: git clone bundle/Vundle.vim failed: $gcmd"
	exit 1
fi

if [ ! -s ${HOME}/.gitconfig ]
then
    touch ${HOME}/.gitconfig > /dev/null 2>&1
fi

echo "setup /usr/bin/meld.git ..."
rootgrp='root'
test $isfreebsd -ne 0 && rootgrp='wheel'
sudo cp ${HOME}/tmp/freebsd-desktop/vimdocs/meld.git /usr/bin/ && sudo chmod 0655 /usr/bin/meld.git && sudo chown root:$rootgrp /usr/bin/meld.git
if [ $? -ne 0 ]
	then
	echo "error: create /usr/bin/meld.git failed."
	exit 1
fi
#
echo "---"
echo "    setup .gitconfig .vimrc ..."
echo "---"
sleep 3
cp ${HOME}/tmp/freebsd-desktop/vimdocs/gitconfig.txt ${HOME}/.gitconfig.tpl && touch ${HOME}/.gitconfig && meld ${HOME}/.gitconfig ${HOME}/.gitconfig.tpl && rm -f ${HOME}/.gitconfig.tpl

cp ${HOME}/tmp/freebsd-desktop/vimdocs/vimrc.txt ${HOME}/.vimrc.tpl && touch ${HOME}/.vimrc && meld ${HOME}/.vimrc ${HOME}/.vimrc.tpl && rm -f ${HOME}/.vimrc.tpl

gcmd="$vimcmd +PluginInstall +qall"
$gcmd
if [ $? -ne 0 ]
	then
	echo "error: PluginInstall failed: $gcmd"
	exit 1
fi

gcmd="$vimcmd +GoInstallBinaries +qall"
$gcmd || proxychains $gcmd
if [ $? -ne 0 ]
	then
	echo "error: +GoInstallBinaries +qall with proxychains failed: $gcmd"
	exit 1
fi
# vim +GoInstallBinaries +qall

gcmd="$vimcmd +GoUpdateBinaries +qall"
$gcmd || proxychains $gcmd
if [ $? -ne 0 ]
	then
	echo "error: +GoUpdateBinaries +qall with proxychains failed: $gcmd"
	exit 1
fi
# vim +:GoUpdateBinaries +qall

echo "ALL DONE!"
cat ${HOME}/tmp/freebsd-desktop/vimdocs/vim-tips.txt
#cd - >/dev/null 2>&1
#

