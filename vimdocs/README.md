# vimdocs

setup vim for Go lang in ubuntu and freebsd

## bootstrap:
<pre>
which git || sudo pkg install -y git-lite || sudo apt-get install -y git;rm -rf ${HOME}/tmp/freebsd-desktop/ && cd ${HOME} && mkdir -p ${HOME}/tmp/ && git clone https://github.com/wheelcomplex/freebsd-desktop.git ${HOME}/tmp/freebsd-desktop/ && ${HOME}/tmp/freebsd-desktop/vimdocs/vim-ubuntu-freebsd-setup-for-go.sh
</pre>
