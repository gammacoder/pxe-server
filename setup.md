#### Setup PXE TFTP Environment ####
Get the pxe-server repo:  
`git clone https://github.com/bclarkindy/pxe-server.git  
cd pxe-server  
./pxe-tftp.sh`  
You will have a running tftp server with pxelinux and necessary netboot install kernel from Ubuntu.  The PXE boot menu is also pre-configured for gparted (installed below).
#### Install Apache ####
Replace SERVER_NAME with your server name below for apache config...  
`apt-get -y install apache2  
echo "ServerName <SERVER_NAME>" /etc/apache2/conf.d/servername.conf  
service apache2 restart`
#### PXE GParted ####
Download GParted zip file  
Unzip all the files in a temp dir /tmp/gparted/:  
`mkdir -p /tmp/gparted; unzip gparted-live-*.zip -d /tmp/gparted/`  
Copy the necessary boot files (vmlinuz and initrd.img) to /tftpboot/gparted/:  
`mkdir /tftpboot/gparted  
cp /tmp/gparted/live/vmlinuz /tftpboot/gparted/  
cp /tmp/gparted/live/initrd.img /tftpboot/gparted/`  
Copy /tmp/gparted/live/filesystem.squashfs to your http server:  
`mkdir /var/www/gparted  
cp /tmp/gparted/live/filesystem.squashfs /var/www/gparted`
#### DHCP Server ####
`apt-get -y install isc-dhcp-server`  


