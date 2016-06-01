#
# https://forums.freebsd.org/threads/51393/
# HOWTO: FreeBSD 10.1 amd64 UEFI boot with encrypted ZFS root using GELI
#

#
# https://wiki.freebsd.org/UEFI
#

# boot into freebsd livecd

# working in /bin/sh
/bin/sh

#
# http://www.schmidp.com/2014/01/07/zfs-full-disk-encryption-with-freebsd-10-part-2/
# livecd ssh setup

# get network ready
ifconfig re0 up && dhclient re0

# start sshd with remote root login

mkdir /tmp/etc
mount_unionfs /tmp/etc /etc
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
passwd root
service sshd onestart

#
# disk list
#
root@:~ # camcontrol devlist
<Samsung SSD 840 EVO 500GB EXT0BB6Q>  at scbus0 target 0 lun 0 (pass0,ada0)
<ST1000LM024 HN-M101MBB 2BA30001>  at scbus1 target 0 lun 0 (pass1,ada1)
<AHCI SGPIO Enclosure 1.00 0001>   at scbus2 target 0 lun 0 (pass2,ses0)
<ADATA USB Flash Drive 1100>       at scbus3 target 0 lun 0 (da0,pass3)
<ACASIS FA-05US 0007>              at scbus4 target 0 lun 0 (da1,pass4)
<Samsung SSD 840 EVO 1TB 0>        at scbus5 target 0 lun 0 (da2,pass5)

#
# install to <ACASIS FA-05US 0007>              at scbus4 target 0 lun 0 (da1,pass4)
#

export TD=da1

# current parts

root@:~ # gpart show $TD
=>        40  3907029088  da1  GPT  (1.8T)
          40        1024    1  freebsd-boot  (512K)
        1064         984       - free -  (492K)
        2048     4194304    2  freebsd-swap  (2.0G)
     4196352  3902832640    3  freebsd-zfs  (1.8T)
  3907028992         136       - free -  (68K)

# new parts: 
GPT: 
EFI(500M, FAT16)
freebsd-ufs(800G, UFS)
freebsd-swap(32G, swap)
<free>

# create parts
# ALL DATA IN $TD WILL LOST
gpart destroy -F $TD

# use gpt
gpart create -s GPT $TD

#

gpart add -t efi -s 500M -a 1M -l EFI $TD

gpart add -t freebsd-ufs -s 800G -a 1M -l fbsd-rootfs $TD

gpart add -t freebsd-swap -s 32G -a 1M -l fbsd-swap $TD

gpart show $TD

=>        40  3907029088  da1  GPT  (1.8T)
          40        2008       - free -  (1.0M)
        2048     1024000    1  efi  (500M)
     1026048  1677721600    2  freebsd-ufs  (800G)
  1678747648    67108864    3  freebsd-swap  (32G)
  1745856512  2161172616       - free -  (1.0T)

# format parts
newfs_msdos -F 16 -L EFI /dev/${TD}p1

newfs -U -t -S 4096 -L freebsdrootfs /dev/${TD}p2 && tunefs -p /dev/${TD}p2

# get UUID (MUST NOT MOUNTED)

p1uuid=`gpart list ${TD} | grep -A 14 "Name: ${TD}p1"| grep "rawuuid:"|awk '{print $2}'` && echo $p1uuid

p2uuid=`gpart list ${TD} | grep -A 14 "Name: ${TD}p2"| grep "rawuuid:"|awk '{print $2}'` && echo $p2uuid

p3uuid=`gpart list ${TD} | grep -A 14 "Name: ${TD}p3"| grep "rawuuid:"|awk '{print $2}'` && echo $p3uuid

ls -alh /dev/gptid/$p1uuid /dev/gptid/$p2uuid /dev/gptid/$p3uuid

# write bootcode

mkdir -p /tmp/efi && \
mount -t msdosfs /dev/${TD}p1 /tmp/efi && \
mkdir -p /tmp/efi/EFI/BOOT && \
cp /boot/boot1.efi /tmp/efi/EFI/BOOT/BOOTX64.EFI && \
umount /tmp/efi

# boot+root
mkdir -p /tmp/rootfs && \
mount -t ufs /dev/${TD}p2 /tmp/rootfs

#
# import zfs pool and restore
#

zpool import bkssd && \
restore rf /tmp/bks/fbsd11-alpha-base.rootfs.dump /tmp/rootfs/ && \
ls -lah /tmp/rootfs/

#
# modify /etc/fstab
#

mkdir -p /tmp/rootfs/msdosboot

cat <<EOF> /tmp/rootfs/etc/fstab 
# Device    Mountpoint    FStype    Options    Dump    Pass#
/dev/gptid/$p2uuid /    ufs    rw    1    1
/dev/gptid/$p1uuid /msdosboot    msdosfs    rw    1    1
/dev/gptid/$p3uuid none    swap    sw    0    0
EOF

cat /tmp/rootfs/etc/fstab 

umount /tmp/rootfs











#
