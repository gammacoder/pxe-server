#!/usr/bin/env bash
#----------------------------------------------
# Build a PXE Server with multiple boot options
#----------------------------------------------

# Get script directory
base_dir=$(dirname $0)

# Ubuntu Quantal 64-bit netboot URL
# We will use this for downloading install kernel, etc.
quantal_amd64_url='http://us.archive.ubuntu.com/ubuntu/dists/quantal/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/'

# PXE pre-boot file URLs
# We wil steal them from Ubuntu archives
pxelinux_url="${quantal_amd64_url}/pxelinux.0"
vesamenu_url="${quantal_amd64_url}/boot-screens/vesamenu.c32"
splash_url="${quantal_amd64_url}/boot-screens/splash.png"

apt-get update

result=$(dpkg --get-selections | grep "tftpd")
if [ -n "$result" ]; then
    echo "Some sort of tftp server is already installed."
    echo "Exiting so we don't break anything."
    exit 1
fi

#----------------------------------------------
# Install and Configure TFTP Server
#----------------------------------------------
# Preseed configuration options before install
# These items can also be changed in /etc/default/tftpd-hpa
debconf-set-selections << EOF
tftpd-hpa tftpd-hpa/options       string  --secure
tftpd-hpa tftpd-hpa/address       string  0.0.0.0:69
tftpd-hpa tftpd-hpa/directory     string  /tftpboot
EOF

apt-get -y install tftpd-hpa

#----------------------------------------------
# Get binaries for PXE Deployment
#----------------------------------------------
# Get binary files for pre-boot environment
cd /tftpboot
if [ ! -f 'pxelinux.0' ]; then wget $pxelinux_url; fi
if [ ! -f 'vesamenu.c32' ]; then wget $vesamenu_url; fi
if [ ! -f 'splash.png' ]; then wget $splash_url; fi

# Get Ubuntu Quantal 64-bit install kernel
mkdir -p /tftpboot/quantal_amd64
cd /tftpboot/quantal_amd64
if [ ! -f 'initrd.gz' ]; then wget "${quantal_amd64_url}/initrd.gz"; fi
if [ ! -f 'linux' ]; then wget "${quantal_amd64_url}/linux"; fi

#----------------------------------------------
# PXE boot menu creation
#----------------------------------------------
# Build the pxelinux directory and write the default file
mkdir /tftpboot/pxelinux.cfg
if [ ! -f '/tftpboot/pxelinux.cfg/default' ]
then
cat << EOF > /tftpboot/pxelinux.cfg/default
include bootmenu.cfg
default vesamenu.c32
prompt 0
timeout 150
EOF
fi

# Build the main boot menu
if [ ! -f '/tftpboot/bootmenu.cfg' ]
then
cat << EOF > /tftpboot/bootmenu.cfg
menu title PXE: All Your Server Are Belong to Us
menu background splash.png
menu color title        * #FFFFFFFF *
menu color border       * #00000000 #00000000 none
menu color sel          * #ffffffff #76a1d0ff *
menu color hotsel       1;7;37;40 #ffffffff #76a1d0ff *
menu color tabmsg       * #ffffffff #00000000 *
menu color help         37;40 #ffdddd00 #00000000 none
menu vshift 12
menu rows 10
menu helpmsgrow 15
# The command line must be at least one line from the bottom.
menu cmdlinerow 16
menu timeoutrow 16
menu tabmsgrow 18
menu tabmsg Press ENTER to boot or TAB to edit a menu entry

label Boot from primary hard drive
    localboot 0
# Ubuntu Server 12.10 Menu
menu begin Ubuntu Server 12.10 64-bit
    menu title Ubuntu Server 12.10 64-bit Installations
    label Automated Net Install - Manual IP
        menu label Automated Net Install - Manual IP
        kernel ubuntu-12.10-amd64/linux
        append initrd=ubuntu-12.10-amd64/initrd.gz debian-installer/locale=en_US console-setup/ask_detect=false keyboard-configuration/layoutcode=us netcfg/disable_autoconfig=true netcfg/get_hostname=ubuntu preesed/url=http://192.168.190.10/preseed.cfg -- quiet
    label Automated Net Install - DHCP
        menu label Automated Net Install - DHCP
        kernel ubuntu-12.10-amd64/linux
        append initrd=ubuntu-12.10-amd64/initrd.gz debian-installer/locale=en_US console-setup/ask_detect=false keyboard-configuration/layoutcode=us preseed/url=http://192.168.190.10/preseed.cfg netcfg/get_hostname=ubuntu -- quiet 
    label Interactive Net Install
        menu label Interactive Net Install
        kernel ubuntu-12.10-amd64/linux
        append initrd=ubuntu-12.10-amd64/initrd.gz priority=medium
menu end
# Utuilities Menu
menu begin Utilities
    menu title Utilities
    default gparted
    label gparted
        menu label GParted Live
        kernel gparted/vmlinuz
        append initrd=gparted/initrd.img boot=live config union=aufs noswap noprompt vga=788 fetch=http://192.168.190.10/gparted/filesystem.squashfs
    label memtest
        menu label Memory Test
menu end
EOF
fi

