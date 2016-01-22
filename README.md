# freebsd-desktop
my freebsd desktop setup notes

## freebsd setup notes

### base system setup

        https://github.com/wheelcomplex/freebsd-desktop/blob/master/freebsd-mini-box-base-system-setup.sh

### gateway/hostapd/softap setup

https://github.com/wheelcomplex/freebsd-desktop/blob/master/freebsd-mini-box-hostapd-softap-setup.sh

### xfce desktop(xfce/virtualbox/fcitx/chromium) setup

https://github.com/wheelcomplex/freebsd-desktop/blob/master/freebsd-mini-box-desktop-setup.sh

### hardware informations

https://github.com/wheelcomplex/freebsd-desktop/blob/master/freebsd-mini-box-hwinfo.txt

## vimdocs

setup vim for Go lang in ubuntu and freebsd

https://github.com/wheelcomplex/freebsd-desktop/blob/master/vimdocs/

### bootstrap:
<pre>
cd ${HOME} && mkdir -p ${HOME}/tmp/ && \
wget 'https://raw.githubusercontent.com/wheelcomplex/freebsd-desktop/master/vimdosc/vim-ubuntu-freebsd-setup-for-go.sh' -O \
${HOME}/tmp/vim-ubuntu-freebsd-setup-for-go.sh && chmod +x ${HOME}/tmp/vim-ubuntu-freebsd-setup-for-go.sh && \
${HOME}/tmp/vim-ubuntu-freebsd-setup-for-go.sh
</pre>
