
# https://github.com/churchers/vm-bhyve

fastpkg install -y bhyve-firmware grub2-bhyve uefi-edk2-bhyve-csm uefi-edk2-bhyve vm-bhyve
 
zfs create bktank/backvm
 
cat <<'EOF'>> /etc/rc.conf
# for vm-bhyve
vm_enable="YES"
vm_dir="zfs:bktank/backvm"
#
EOF

zfs create bktank/backvm

vm init

vm version

ZMOUNTDIR=`mount | grep "bktank/backvm on "| awk '{print $3}'`
mkdir -p /${ZMOUNTDIR}/.templates/

cp -v /usr/local/share/examples/vm-bhyve/* /${ZMOUNTDIR}/.templates/

vm switch create public
# or vm switch import public bridge0 to use existed bridge0

vm switch add public re0

vm iso http://ftp.freebsd.org/pub/FreeBSD/snapshots/ISO-IMAGES/12.0/FreeBSD-12.0-CURRENT-amd64-20170420-r317181-disc1.iso

# iso file will put in /home/backvm/.iso/

# UEFI boot
# https://github.com/churchers/vm-bhyve/wiki/UEFI-Graphics-(VNC)
#

cat <<'EOF' > /home/backvm/.templates/freebsd12amd64.conf
graphics="yes"
graphics_res="1280x720"
graphics_wait="yes"
uefi="yes"
loader="bhyveload"
cpu=2
memory=2048M
network0_type="virtio-net"
network0_switch="public"
#disk0_type="virtio-blk"
disk0_type="ahci-hd"
disk0_name="disk0.img"
disk0_opts="nocache,direct"
disk0_size="40G"
EOF

vm create -t freebsd12amd64 freebsd12amd64
# vm configure file: /home/backvm/freebsd12amd64/freebsd12amd64.conf

# vm [-f] install freebsd12amd64 FreeBSD-12.0-CURRENT-amd64-20170420-r317181-disc1.iso
vm install freebsd12amd64 FreeBSD-12.0-CURRENT-amd64-20170420-r317181-disc1.iso

vm list

vm info

vm console freebsd12amd64
# press ~. to exit from console

# vnc console: pkg install tigervnc
vncviewer 127.0.0.1:5900


