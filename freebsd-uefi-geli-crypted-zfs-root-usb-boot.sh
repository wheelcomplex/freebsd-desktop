#
# https://forums.freebsd.org/threads/51393/
# HOWTO: FreeBSD 10.1 amd64 UEFI boot with encrypted ZFS root using GELI
#

# boot into freebsd livecd

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


# current parts

root@:~ # gpart show da1
=>        40  3907029088  da1  GPT  (1.8T)
          40        1024    1  freebsd-boot  (512K)
        1064         984       - free -  (492K)
        2048     4194304    2  freebsd-swap  (2.0G)
     4196352  3902832640    3  freebsd-zfs  (1.8T)
  3907028992         136       - free -  (68K)

# new parts: GPT: EFI(4G, FAT32)+freebsd-boot(100M,UFS)+
