#
# https://forums.freebsd.org/threads/51393/
# HOWTO: FreeBSD 10.1 amd64 UEFI boot with encrypted ZFS root using GELI
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

export TD=/dev/da1

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
freebsd-boot(4G, UFS)
freebsd-zfs(800G, zfs)
freebsd-swap(32G, swap)
<free>

# create parts
# ALL DATA IN $TD WILL LOST
gpart destroy -F $TD

# use gpt
gpart create -s GPT $TD

#

gpart add -t efi -s 500M -a 1M -l EFI $TD

gpart add -t freebsd-boot -s 4G -a 1M -l fbsd-boot $TD

gpart add -t freebsd-zfs -s 800G -a 1M -l fbsd-zfs $TD

gpart add -t freebsd-swap -s 32G -a 1M -l fbsd-swap $TD

gpart show $TD

=>        40  3907029088  da1  GPT  (1.8T)
          40        2008       - free -  (1.0M)
        2048     1024000    1  efi  (500M)
     1026048     8388608    2  freebsd-boot  (4.0G)
     9414656  1677721600    3  freebsd-zfs  (800G)
  1687136256    67108864    4  freebsd-swap  (32G)
  1754245120  2152784008       - free -  (1.0T)
  
# format parts
newfs_msdos -F 16 -L EFI ${TD}p1

newfs -U -t -S 4096 -L freebsdboot ${TD}p2 && tunefs -p ${TD}p2

newfs -U -t -S 4096 -L freebsdboot ${TD}p2 && tunefs -p ${TD}p2

# write bootcode




















#
