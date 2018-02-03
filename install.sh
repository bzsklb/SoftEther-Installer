#!/bin/bash

beta="v4.24-9652-beta-2017.12.21"
lateststable="v4.25-9656-rtm-2018.01.15"
#Release Date: 2018.01.15
service="vpnserver.service"

echo "--------------------------------------------------------------------"
echo "SoftEther VPN Server Install script"
echo "By AhmadShamli and bzsklb. Special for https://www.twitch.tv/knjazevdesu"
echo "http://github.com/bzsklb"
echo "http://github.com/AhmadShamli"
echo "http://AhmadShamli.com"
echo "credit: DigitalOcean and StackOverflow"
echo "https://www.digitalocean.com/community/tutorials/how-to-setup-a-multi-protocol-vpn-server-using-softether"
echo "https://linuxconfig.org/setting-up-softether-vpn-server-on-ubuntu-16-04-xenial-xerus-linux"
echo "--------------------------------------------------------------------"
echo "--------------------------------------------------------------------"

if [ "$(id -u)" != "0" ]; then
    echo "Please run as root/sudo."
    exit 1
fi

echo
echo "Architecture: "

# Get the machine Architecture
Architecture=$(uname -m)
case "$Architecture" in
    x86)    Architecture="x86"                  ;;
    arm?????)   Architecture="arm"                 ;;
    i?86)   Architecture="x86"                  ;;
    amd64)  Architecture="x86_64"                    ;;
    x86_64) Architecture="x86_64"                   ;;
	mipsel)		Architecture="mipsel"					;;
* ) #echo    "Your Architecture '$Architecture' -> ITS NOT SUPPORTED."   ;;
esac

echo
echo "Operating System Architecture : $Architecture"
echo

if test "$Architecture" = "x86_64"
then
	arch="64bit_-_Intel_x64_or_AMD64"
	arch2="x64-64bit"
	echo "Selected : " $arch
elif test "$Architecture" = "x86"
then
	arch="32bit_-_Intel_x86"
	arch2="x86-32bit"
	echo "Selected : " $arch
elif test "$Architecture" = "arm"
then
	echo "Selected : " $arch
	echo    "Your Architecture '$Architecture' -> NOT SUPPORTED BY THIS SCRIPT."
	exit 1
elif test "$Architecture" = "mipsel"
then
	echo "Selected : " $arch
	echo    "Your Architecture '$Architecture' -> NOT SUPPORTED BY THIS SCRIPT."
	exit 1
else
	echo    "Your Architecture '$Architecture' -> NOT SUPPORTED BY THIS SCRIPT."
	exit 1
fi

echo "--------------------------------------------------------------------"
echo
echo "Select OS"
echo
echo
echo
if VERB="$( command -v apt-get )" 2> /dev/null; then
   echo "OS: Debian-based"
   os="deb"
elif VERB="$( command -v yum )" 2> /dev/null; then
   echo "OS: Modern Red Hat-based"
   os="cent"
elif VERB="$( command -v pacman )" 2> /dev/null; then
	echo "OS: Archlinux-based "
	os="pacman"
	echo "Sorry. Archlinux is currently not supported by this script. "
   	exit 1
else
   echo "Sorry. Your linux distro is not supported." >&2
   exit 1
fi
echo
echo "--------------------------------------------------------------------"
echo
echo "Select build"
echo
echo " 1. latest stable"
echo " 2. latest(might include beta/rc)"
echo
echo "Please choose build: "
read tmp
echo

if test "$tmp" = "1"
then
	version="$lateststable"
	echo "Latest stable selected: 1 "$lateststable
elif test "$tmp" = "2"
then
	version="$beta"
	echo "Latest build(stable/beta) selected: 1 "$beta
else
	version="$lateststable"
	echo "Default: stable "$lateststable
fi

file="softether-vpnserver-"$version"-linux-"$arch2".tar.gz"
link="http://www.softether-download.com/files/softether/"$version"-tree/Linux/SoftEther_VPN_Server/"$arch"/"$file

if [ ! -s "$file" ]||[ ! -r "$file" ];then
	#remove and redownload empty or unreadable file
	rm -f "$file"
	wget "$link"
elif [ ! -f "file" ];then
	#download if not exist
	wget "$link"
fi

if [ -f "$file" ];then
	tar xzf "$file"
	dir=$(pwd)
	echo "current dir " $dir
	cd vpnserver
	dir=$(pwd)
	echo "changed to dir " $dir
else
	echo "Archive not found. Please rerun this script or check permission."
	break
fi

if [ "$os" = "cent" ];then
	yum upgrade
	yum install gcc make which
	#yum groupinstall "Development Tools" gcc 
elif [ "$os" = "deb" ];then
	apt-get update && apt-get upgrade
	#apt-get install build-essential -y
	apt-get install make gcc
elif [ "$os" = "pacman" ];then
	pacman -Syy base-devel --noconfirm
else
   echo "OS NOT SUPPORTED BY THIS SCRIPT." >&2
   exit 1 
fi

	
make
cd ..
mv vpnserver /usr/local
dir=$(pwd)
echo "current dir " $dir
cd /usr/local/vpnserver/
dir=$(pwd)
echo "changed to dir " $dir
chmod 600 *
chmod 700 vpnserver
chmod 700 vpncmd

mkdir /var/lock/subsys

touch /etc/systemd/system/"$service"
#need to cat two time to pass varible($service) value inside
cat > /etc/systemd/system/"$service" <<EOF
[Unit]
Description=SoftEther VPN Server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/vpnserver/vpnserver start
ExecStop=/usr/local/vpnserver/vpnserver stop

[Install]
WantedBy=multi-user.target
EOF

chmod 664 /etc/systemd/system/"$service"
systemctl daemon-reload
systemctl enable "$service"
systemctl start "$service"
	


echo "--------------------------------------------------------------------"
echo "--------------------------------------------------------------------"
echo "Installation done. Hurray."
echo "Now you may want to change VPN server password."
echo "See this image https://linuxconfig.org/images/set-admin-password-for-vpncmd.png"
echo "Run in terminal:"
echo "/usr/local/vpnserver/vpncmd"
echo "Press 1 to select \"Management of VPN Server or VPN Bridge\","
echo "then press Enter without typing anything to connect to the "
echo "localhost server, and again press Enter without inputting "
echo "anything to connect to server by server admin mode."
echo "Then use command below to change admin password:"
echo "ServerPasswordSet"
echo "Done...."
