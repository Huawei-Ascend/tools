#!/bin/bash
RUN_MINI=${1:-"mini_developerkit_1.32.0.B080.rar"}
NETWORK_CARD_DEFAULT_IP=${2:-"192.168.0.2"}
USB_CARD_DEFAULT_IP=${3:-"192.168.1.2"}
username="HwHiAiUser"
password="HwHiAiUser:\$6\$klSpdQ1K\$4Gm/7HxehX.YSum4Wf3IDFZ3v5L.clybUpGNGaw9zAh3rqzqB4mWbxvSTFcvhbjY/6.tlgHhWsbtbAVNR9TSI/:17795:0:99999:7:::"
root_pwd="root:\$6\$klSpdQ1K\$4Gm/7HxehX.YSum4Wf3IDFZ3v5L.clybUpGNGaw9zAh3rqzqB4mWbxvSTFcvhbjY/6.tlgHhWsbtbAVNR9TSI/:17795:0:99999:7:::"
NETWORK_CARD_GATEWAY=`echo ${NETWORK_CARD_DEFAULT_IP} | sed -r 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+/\1.1/g'`


# 1. apt install deb
mv /etc/apt/sources.list /etc/apt/sources.list.bak
touch /etc/apt/sources.list
echo "deb file:/cdtmp xenial main restrict" > /etc/apt/sources.list

locale-gen zh_CN.UTF-8 en_US.UTF-8 en_HK.UTF-8
apt-get update
apt-get install openssh-server -y
apt-get install unzip -y
apt-get install vim -y
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
apt-get install dmidecode -y
apt-get install rsync -y

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
echo "source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address ${NETWORK_CARD_DEFAULT_IP}
netmask 255.255.255.0
gateway ${NETWORK_CARD_GATEWAY}

auto usb0
iface usb0 inet static
address ${USB_CARD_DEFAULT_IP}
netmask 255.255.255.0
" > /etc/network/interfaces

# 5. auto-run minirc_cp.sh and minirc_sys_init.sh when start ubuntu
# 启动ubuntu时，自动运行minirc_cp.sh和minirc_sys_init.sh脚本文件
echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution bits.
# 要启用或禁用此脚本，只需更改执行位。
#
# By default this script does nothing.
# 默认情况下，此脚本不执行任何操作。
cd /var/

/bin/bash /var/minirc_boot.sh /opt/mini/${RUN_MINI}

exit 0
" > /etc/rc.local

echo "RuntimeMaxUse=50M" >> /etc/systemd/journald.conf
echo "SystemMaxUse=50M" >> /etc/systemd/journald.conf

exit
# end
