#!/bin/bash
DRIVER_PACKAGE=${1:-"Ascend310-driver-1.71.t0.0.b010-ubuntu18.04.aarch64-minirc.tar.gz"}
NETWORK_CARD_DEFAULT_IP=${2:-"192.168.0.2"}
USB_CARD_DEFAULT_IP=${3:-"192.168.1.2"}
username="HwHiAiUser"
password="HwHiAiUser:\$6\$klSpdQ1K\$4Gm/7HxehX.YSum4Wf3IDFZ3v5L.clybUpGNGaw9zAh3rqzqB4mWbxvSTFcvhbjY/6.tlgHhWsbtbAVNR9TSI/:17795:0:99999:7:::"
root_pwd="root:\$6\$klSpdQ1K\$4Gm/7HxehX.YSum4Wf3IDFZ3v5L.clybUpGNGaw9zAh3rqzqB4mWbxvSTFcvhbjY/6.tlgHhWsbtbAVNR9TSI/:17795:0:99999:7:::"
NETWORK_CARD_GATEWAY=`echo ${NETWORK_CARD_DEFAULT_IP} | sed -r 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+/\1.1/g'`

# 1. apt install deb
mv /etc/apt/sources.list /etc/apt/sources.list.bak
touch /etc/apt/sources.list
echo "deb file:/cdtmp bionic main restricted" > /etc/apt/sources.list

locale-gen zh_CN.UTF-8 en_US.UTF-8 en_HK.UTF-8
apt-get update
echo "make_sd_process: 5%"
apt-get install openssh-server -y
apt-get install tar -y
apt-get install vim -y
echo "make_sd_process: 10%"
apt-get install gcc -y
apt-get install zlib -y
apt-get install python2.7 -y
apt-get install python3 -y
apt-get install pciutils -y
apt-get install strace -y
apt-get install nfs-common -y
apt-get install sysstat -y
apt-get install libelf1 -y
apt-get install libpython2.7 -y
apt-get install libnuma1 -y
echo "make_sd_process: 20%"
apt-get install dmidecode -y
apt-get install rsync -y
apt-get install net-tools -y
echo "make_sd_process: 25%"

mv /etc/apt/sources.list.bak /etc/apt/sources.list

# 2. set username
useradd -m ${username} -d /home/${username} -s /bin/bash
sed -i "/^${username}:/c\\${password}" /etc/shadow
sed -i "/^root:/c\\${root_pwd}" /etc/shadow

# 3. config host
echo 'davinci-mini' > /etc/hostname
echo '127.0.0.1        localhost' > /etc/hosts
echo '127.0.1.1        davinci-mini' >> /etc/hosts

# 4. config ip
echo "
network:
  version: 2
#  renderer: NetworkManager
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no 
      addresses: [${NETWORK_CARD_DEFAULT_IP}/24] 
      gateway4: ${NETWORK_CARD_GATEWAY}
      nameservers:
            addresses: [255.255.0.0]
    
    usb0:
      dhcp4: no 
      addresses: [${USB_CARD_DEFAULT_IP}/24] 
      gateway4: ${NETWORK_CARD_GATEWAY}
" > /etc/netplan/01-netcfg.yaml

# 5. auto-run minirc_cp.sh and minirc_sys_init.sh when start ubuntu
echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
cd /var/


/bin/bash /var/minirc_boot.sh /opt/mini/${DRIVER_PACKAGE}

/bin/bash /var/acllib_install.sh >/var/1.log

/bin/bash /var/aicpu_kernels_install.sh >>/var/1.log


exit 0
" > /etc/rc.local


chmod 755 /etc/rc.local
echo "RuntimeMaxUse=50M" >> /etc/systemd/journald.conf
echo "SystemMaxUse=50M" >> /etc/systemd/journald.conf

echo "export LD_LIBRARY_PATH=/home/HwHiAiUser/Ascend/acllib/lib64" >> /home/HwHiAiUser/.bashrc

exit
# end
