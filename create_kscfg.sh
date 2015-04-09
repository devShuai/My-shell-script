#!/bin/bash
stty erase '^H' #backspace
echo "This script will create the kickstar file for centos 6.5, and you would be input some parameter,"
echo " like: asset number,ip,netmask,gateway,nameserver."
echo "please input asset number"
read asset_number
echo "please input bootloader location"
read ks_install_sd
echo "please input ip"
read ks_ip
echo "please input netmask"
read ks_netmask
echo "please input gateway"
read ks_gateway
echo "please input nameserver"
read ks_nameserver
echo "please input ntp server"
read ntpserver
cat > /tmp/$asset_number.cfg <<EOFFF
#platform=x86, AMD64, or Intel EM64T
# System authorization information
install
text
url --url http://192.168.18.118/centos
firstboot --disable
keyboard us
lang en_US
network --bootproto=static --ip=$ks_ip --netmask=$ks_netmask --gateway=$ks_gateway --nameserver=$ks_nameserver --hostname=$asset_number --device=eth0 --onboot=on
rootpw  --iscrypted \$6\$nYtfmuzE\$QnfDL2SHh2SA24SfbV6qRB/vxYkKKFWVhOpWXe78Gtk/9W.nmLoOfwxYZMgE8VYUfYAsTXZ0oH.3sUPy/6g4I.
authconfig --enableshadow --passalgo=sha512
firewall --enabled --port=22:tcp 
selinux --disabled
services --disabled iscsi,iscsid,postfix,netfs,ip6tables,blk-availability
skipx
timezone Asia/Shanghai
zerombr
reboot --eject
bootloader --location=mbr --driveorder=$ks_install_sd --append="rhgb quiet"
clearpart --all --drives=$ks_install_sd
part /boot --fstype ext4 --size=200 --ondisk=$ks_install_sd
part /  --fstype ext4 --size=102400 --ondisk=$ks_install_sd
part /data --fstype ext4 --size=1 --grow --ondisk=$ks_install_sd
part swap --size=16000 --ondisk=$ks_install_sd

%packages --nobase
@core
%post --log=/root/ks-post.log
#!/bin/bash
#ipv6 off
cat >> /etc/modprobe.d/dist.conf <<EOF
alias net-pf-10 off
alias ipv6 off
EOF
cat >> /etc/sysconfig/network <<EOF
IPV6INIT=no
EOF

#time sync
cat > /etc/cron.hourly/ntpdate.cron <<EOF
/usr/sbin/ntpdate $ntpserver > /dev/null 2>&1
/sbin/hwclock -w > /dev/null 2>&1
EOF
chmod +x /etc/cron.hourly/ntpdate.cron

#system config
cat >> /etc/sysctl.conf <<EOF
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmmni = 4096
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048586
kernel.msgmnb = 65536
kernel.msgmax = 655360
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 2000 65500
net.core.rmem_default = 262144
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 8192
EOF

#shutdown ctrl+alt+del
cat > /etc/init/control-alt-delete.conf <<EOF
exec /usr/bin/logger -p authpriv.notice -t init "Ctrl-Alt-Del was pressed and ignored"
EOF

%end
EOFFF

install_ip=http://192.168.18.118/
cat >/tmp/$asset_number.txt <<EOF
label $asset_number
  menu label $asset_number-$ks_ip
  menu default
  kernel vmlinuz
  append ip=192.168.17.200 netmask=255.255.255.0 gateway=192.168.17.254 ksdevice=eth0 ks=$install_ip$asset_number.cfg initrd=initrd.img
EOF


mkdir -p /tmp/temp_dir_cdrom/mount
mkdir -p /tmp/temp_dir_cdrom/rw
mkdir -p /tmp/temp_dir_cdrom/iso

mount -o loop /usr/share/nginx/html/centos-boot.iso /tmp/temp_dir_cdrom/mount
rsync -a /tmp/temp_dir_cdrom/mount/ /tmp/temp_dir_cdrom/rw
umount /tmp/temp_dir_cdrom/mount
rm -rf /usr/share/nginx/html/centos-boot.iso
chmod -R +w /tmp/temp_dir_cdrom/rw
/bin/cp -f /tmp/$asset_number.cfg /usr/share/nginx/html/
sed -i "17 r /tmp/$asset_number.txt" /tmp/temp_dir_cdrom/rw/isolinux/isolinux.cfg
cd /tmp/temp_dir_cdrom/rw
mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -o /usr/share/nginx/html/centos-boot.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table /tmp/temp_dir_cdrom/rw
cd /tmp
rm -rf /tmp/temp_dir_cdrom
echo "The iso file and ks file are created."
echo "please copy url for install"
echo ${install_ip}centos-boot.iso
