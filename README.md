# freebsd-desktop
my freebsd desktop setup notes

## freebsd setup notes

### base system setup
        freebsd-mini-box-base-system-setup.sh

### gateway/hostapd/softap setup
        freebsd-mini-box-hostapd-softap-setup.sh

### xfce desktop(xfce/virtualbox/fcitx/chromium) setup
        freebsd-mini-box-desktop-setup.sh

### hardware informations
        freebsd-mini-box-hwinfo.txt

## vimdocs

setup vim for Go lang in ubuntu and freebsd

### bootstrap:
<pre>
cd ${HOME} && mkdir -p ${HOME}/tmp/ && \
wget 'https://raw.githubusercontent.com/wheelcomplex/freebsd-desktop/master/vimdosc/vim-ubuntu-freebsd-setup-for-go.sh' -O \
${HOME}/tmp/vim-ubuntu-freebsd-setup-for-go.sh && chmod +x ${HOME}/tmp/vim-ubuntu-freebsd-setup-for-go.sh && \
${HOME}/tmp/vim-ubuntu-freebsd-setup-for-go.sh
</pre>
